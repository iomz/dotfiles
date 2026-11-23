"""Run scripts/host-slim.sh on a home applied as a stem host, then as a leaf."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / "scripts/host-slim.sh"


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class HostSlimTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="host-slim-")
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name) / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=temp.name)
        self.env.pop("XDG_CONFIG_HOME", None)

    def configure(self, host, variant="helm"):
        config = self.home / ".config/chezmoi/chezmoi.toml"
        config.parent.mkdir(parents=True, exist_ok=True)
        host_line = f'host = "{host}"\n' if host else ""
        config.write_text(f'sourceDir = "{SOURCE}"\n[data]\nvariant = "{variant}"\n{host_line}'
                          'git_name = "Test"\ngit_email = "test@example.org"\n')

    def apply(self, host):
        self.configure(host)
        subprocess.run(["chezmoi", "apply", "--force", "--no-tty", "--exclude", "scripts"],
                       env=self.env, stdin=subprocess.DEVNULL, capture_output=True, check=True)

    def slim(self, *args, env=None, code=0):
        result = subprocess.run(["sh", str(SCRIPT), *args], env=env or self.env, text=True,
                                capture_output=True)
        self.assertEqual(result.returncode, code, result.stderr)
        return result.stdout

    def write(self, path, text="x\n"):
        target = self.home / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def leaf_home(self):
        """A home that was a stem host, with tool data, then applied as a leaf."""
        self.apply("sazanka")
        for path in (".local/share/mise/installs/node/x", ".local/share/zinit/plugins/x",
                     ".local/state/nvim/shada/main.shada", ".local/share/agent-skills/skills/x/SKILL.md",
                     ".config/nvim/lazy-lock.json"):
            self.write(path)
        # Not ours: an APM copy beside the skill links, and unrelated user data.
        self.write(".claude/skills/third-party/SKILL.md")
        self.write(".local/share/keep/data")
        self.write(".profile", "export TINY_CHEZMOI=1\n")
        self.apply("tinybox")

    def test_stem_and_sandbox_hosts_have_nothing_to_slim(self):
        self.configure("sazanka")
        self.assertIn("stem host; nothing to slim", self.slim())
        self.configure("sandbox", variant="agent-sandbox")
        self.assertIn("nothing to slim on an agent-sandbox host", self.slim())

    def test_a_config_from_before_the_host_key_asks_for_chezmoi_init(self):
        self.configure(None)
        result = subprocess.run(["sh", str(SCRIPT)], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("run chezmoi init first", result.stderr)

    def test_dry_run_lists_and_moves_nothing(self):
        self.leaf_home()
        out = self.slim()
        for path in (".config/nvim", ".local/share/mise", ".local/share/zinit", ".local/state/nvim",
                     ".local/share/agent-skills", ".claude/skills/evolve-skill", ".profile"):
            self.assertIn(f"  {path}\n", out)
        for path in (".claude/skills\n", ".claude/skills/third-party", ".local/share/keep",
                     ".config/nvim/init.lua"):
            self.assertNotIn(path, out)
        self.assertTrue((self.home / ".config/nvim").exists())
        self.assertFalse((self.home / ".chezmoi-backups").exists())

    def test_apply_moves_into_a_backup_and_the_restore_command_works(self):
        self.leaf_home()
        out = self.slim("--apply")
        backups = list((self.home / ".chezmoi-backups").glob("slim-*"))
        self.assertEqual(len(backups), 1)
        backup = backups[0]
        self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
        for path in (".config/nvim", ".local/share/mise", ".local/share/agent-skills", ".profile"):
            self.assertFalse((self.home / path).exists(), path)
            self.assertTrue((backup / path).exists(), path)
        self.assertFalse((self.home / ".claude/skills/evolve-skill").is_symlink())
        self.assertTrue((self.home / ".claude/skills/third-party/SKILL.md").exists())
        self.assertTrue((self.home / ".local/share/keep/data").exists())
        self.assertIn("nothing to slim", self.slim())

        # Restoring keeps what exists again, user data named MOVED, and the home's mode.
        self.write(".config/nvim/init.lua", "new\n")
        self.write("MOVED", "mine\n")
        self.home.chmod(0o751)
        restore = out.rsplit("To restore: ", 1)[1].strip()
        subprocess.run(["sh", "-c", restore], env=self.env, check=True, capture_output=True)
        self.assertTrue((self.home / ".local/share/mise/installs/node/x").exists())
        self.assertTrue((self.home / ".claude/skills/evolve-skill").is_symlink())
        self.assertEqual((self.home / ".profile").read_text(), "export TINY_CHEZMOI=1\n")
        self.assertEqual((self.home / ".config/nvim/init.lua").read_text(), "new\n")
        self.assertTrue((backup / ".config/nvim/lazy-lock.json").exists())
        self.assertTrue((backup / "MOVED").exists())
        self.assertEqual((self.home / "MOVED").read_text(), "mine\n")
        self.assertEqual(self.home.stat().st_mode & 0o777, 0o751)

    def test_a_failed_managed_query_moves_nothing(self):
        self.leaf_home()
        real = shutil.which("chezmoi")
        bin_dir = self.home.parent / "bin"
        bin_dir.mkdir()
        fake = bin_dir / "chezmoi"
        fake.write_text("#!/bin/sh\n"
                        'case " $* " in *" managed "*) case " $* " in *--override-data*) ;; *) exit 1 ;; esac ;; esac\n'
                        f'exec "{real}" "$@"\n')
        fake.chmod(0o755)
        env = dict(self.env, PATH=f"{bin_dir}{os.pathsep}{self.env['PATH']}")
        self.slim("--apply", env=env, code=1)
        self.assertFalse((self.home / ".chezmoi-backups").exists())
        self.assertTrue((self.home / ".config/nvim").exists())

    def test_a_profile_with_more_than_the_legacy_line_stays(self):
        self.leaf_home()
        self.write(".profile", "export TINY_CHEZMOI=1\nexport EDITOR=vim\n")
        self.assertNotIn(".profile", self.slim())


if __name__ == "__main__":
    unittest.main()
