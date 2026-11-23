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
        config.write_text(f'sourceDir = "{SOURCE}"\n[data]\nvariant = "{variant}"\nhost = "{host}"\n'
                          'git_name = "Test"\ngit_email = "test@example.org"\n')

    def apply(self, host):
        self.configure(host)
        subprocess.run(["chezmoi", "apply", "--force", "--no-tty", "--exclude", "scripts"],
                       env=self.env, stdin=subprocess.DEVNULL, capture_output=True, check=True)

    def slim(self, *args):
        result = subprocess.run(["sh", str(SCRIPT), *args], env=self.env, text=True,
                                capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
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

        restore = out.rsplit("To restore: ", 1)[1].strip()
        subprocess.run(["sh", "-c", restore], env=self.env, check=True)
        self.assertTrue((self.home / ".config/nvim/lazy-lock.json").exists())
        self.assertTrue((self.home / ".claude/skills/evolve-skill").is_symlink())
        self.assertEqual((self.home / ".profile").read_text(), "export TINY_CHEZMOI=1\n")
        self.assertFalse((self.home / "MOVED").exists())

    def test_a_profile_with_more_than_the_legacy_line_stays(self):
        self.leaf_home()
        self.write(".profile", "export TINY_CHEZMOI=1\nexport EDITOR=vim\n")
        self.assertNotIn(".profile", self.slim())


if __name__ == "__main__":
    unittest.main()
