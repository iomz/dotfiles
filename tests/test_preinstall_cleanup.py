"""Offline migration checks against real chezmoi and isolated destination homes."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = "run_once_before_00-cleanup-legacy-config.sh.tmpl"
MANAGED = {
    ".vimrc": "dot_vimrc",
    ".zshenv": "dot_zshenv",
    ".gitconfig": "dot_gitconfig.tmpl",
    ".config/nvim/init.lua": "dot_config/nvim/init.lua",
    ".config/zsh/.zshrc": "dot_config/zsh/dot_zshrc",
    ".config/direnv/direnv.toml": "dot_config/direnv/direnv.toml",
    ".config/mise/config.toml": "dot_config/mise/config.toml",
    ".config/ghostty/config.ghostty": "dot_config/ghostty/config.ghostty",
    ".config/zellij/config.kdl": "dot_config/zellij/config.kdl",
    ".config/zeno/config.yml": "dot_config/zeno/config.yml",
    ".config/starship.toml": "dot_config/starship.toml.tmpl",
    ".config/vale/.vale.ini": "dot_config/vale/dot_vale.ini",
    ".config/yamlfmt/.yamlfmt": "dot_config/yamlfmt/dot_yamlfmt",
    ".hammerspoon/init.lua": "dot_hammerspoon/init.lua",
    ".profile": "dot_profile.tmpl",
    ".inputrc": "dot_inputrc",
    ".mostrc": "dot_mostrc",
    ".screenrc": "dot_screenrc",
    ".tigrc": "dot_tigrc",
}


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class PreinstallCleanupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="chezmoi-cleanup-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.source = self.root / "source"
        self.source.mkdir()
        for name in (SCRIPT, *MANAGED.values()):
            target = self.source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(SOURCE / name, target)
        # Installer stub proves cleanup precedes ordinary installation scripts.
        (self.source / "run_once_install-probe.sh").write_text(
            '#!/bin/sh\nset -eu\n'
            'test ! -e "$HOME/.config/nvim/init.vim"\n'
            'test -f "$HOME/.config/nvim/init.lua"\n'
            'echo installed > "$HOME/install-probe"\n'
        )
        self.config = self.root / "config.toml"
        self.config.write_text('[data]\nvariant = "workstation"\n')
        self.env = dict(os.environ, HOME=str(self.home))
        self.command = [
            "chezmoi", "--source", str(self.source), "--destination", str(self.home),
            "--config", str(self.config), "--persistent-state", str(self.root / "state"),
            "--cache", str(self.root / "cache"), "--no-tty",
        ]

    def chezmoi(self, *args, check=True):
        return subprocess.run(self.command + list(args), env=self.env, cwd=self.root,
                              stdin=subprocess.DEVNULL, text=True,
                              capture_output=True, check=check)

    def put(self, relative, content="legacy\n"):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def backups(self):
        return list((self.home / ".chezmoi-backups").glob("pre-install.*"))

    def test_migration_preserves_backups_and_unrelated_state(self):
        legacy = [".vim/plugin/old.vim", ".vimrc", ".gvimrc", ".exrc",
                  ".config/vim/vimrc", ".config/nvim/init.vim",
                  ".config/nvim/plugin/old.vim", ".config/zsh/rc.d/99-old.zsh",
                  ".zshenv", ".zprofile", ".zshrc", ".zlogin", ".zlogout",
                  ".zshrc.zwc", ".zsh/completions/_old", ".gitconfig",
                  ".config/git/config", ".config/git/extra.conf",
                  ".config/direnv/direnvrc", ".config/direnv/lib/old.sh",
                  ".config/mise/conf.d/old.toml", ".config/rtx/config.toml",
                  ".mise.toml", ".rtx.toml", ".tool-versions",
                  ".config/ghostty/config", ".config/zellij/layouts/old.kdl",
                  ".config/zeno/old.yml", ".config/starship.toml",
                  ".config/vale/old.ini", ".config/yamlfmt/old.yml",
                  ".config/tig/config", ".config/opencode/plugins/old.js",
                  ".config/opencode/opencode.json", ".hammerspoon/modules/old.lua",
                  ".profile", ".inputrc", ".mostrc", ".screenrc", ".tigrc"]
        preserved = [".zsh_history", ".viminfo", ".local/share/nvim/sentinel",
                     ".local/share/vim/bundle/sentinel", ".cache/zsh/sentinel",
                     ".config/other/config", ".config/opencode/service.json",
                     ".codex/auth.json", ".git-credentials",
                     ".ssh/config", ".config/gh/hosts.yml", ".config/rclone/rclone.conf",
                     ".local/share/opencode/auth.json", ".local/share/opencode/session/probe",
                     ".claude/settings.json", ".agents/skills/probe/SKILL.md",
                     ".apm/apm.lock.yaml", "project/.tool-versions", "project/.mise.toml"]
        for name in legacy + preserved:
            self.put(name)
        self.chezmoi("apply")
        backup, = self.backups()
        self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
        self.assertEqual(backup.parent.stat().st_mode & 0o777, 0o700)
        self.assertRegex(backup.name, r"^pre-install\.\d{8}T\d{6}Z\.")
        for name in legacy:
            self.assertEqual((backup / name).read_text(), "legacy\n", name)
        for name in preserved:
            self.assertEqual((self.home / name).read_text(), "legacy\n", name)
        for name in set(legacy) - set(MANAGED):
            self.assertFalse((self.home / name).exists(), name)
        self.assertTrue((self.home / "install-probe").exists())
        self.assertEqual(self.chezmoi("diff").stdout, "")
        self.put(".zprofile", "new customization\n")
        self.chezmoi("apply")
        self.assertEqual(self.backups(), [backup])
        self.assertEqual((self.home / ".zprofile").read_text(), "new customization\n")

    def test_unchanged_managed_files_are_redeployed(self):
        rendered = {}
        for name in MANAGED:
            rendered[name] = self.chezmoi("cat", str(self.home / name)).stdout
            self.put(name, rendered[name])
        self.chezmoi("apply")
        self.assertEqual(self.chezmoi("diff").stdout, "")
        for name in MANAGED:
            # Chezmoi omits empty rendered templates (e.g. .profile on macOS).
            if rendered[name]:
                self.assertEqual((self.home / name).read_text(), rendered[name], name)
            else:
                self.assertFalse((self.home / name).exists(), name)

    def test_symlinks_are_moved_not_followed(self):
        outside = self.root / "external"
        outside.mkdir()
        (outside / "sentinel").write_text("keep")
        (self.home / ".vim").symlink_to(outside, target_is_directory=True)
        (self.home / ".zlogin").symlink_to(self.root / "missing")
        (self.home / ".config").mkdir()
        (self.home / ".config/nvim").symlink_to(outside, target_is_directory=True)
        self.chezmoi("apply")
        backup, = self.backups()
        self.assertTrue((backup / ".vim").is_symlink())
        self.assertTrue((backup / ".zlogin").is_symlink())
        self.assertTrue((backup / ".config/nvim").is_symlink())
        self.assertEqual((outside / "sentinel").read_text(), "keep")
        self.assertEqual(list(outside.iterdir()), [outside / "sentinel"])
        self.assertFalse((self.home / ".config/nvim").is_symlink())
        self.assertTrue((self.home / ".config/nvim/init.lua").is_file())

    def test_opencode_service_symlink_stays_in_place(self):
        service = self.root / "service-config"
        service.write_text("host-owned\n")
        directory = self.home / ".config/opencode"
        directory.mkdir(parents=True)
        (directory / "service.json").symlink_to(service)
        self.put(".config/opencode/.legacy-config")
        self.chezmoi("apply")
        self.assertTrue((directory / "service.json").is_symlink())
        self.assertEqual(service.read_text(), "host-owned\n")
        backup, = self.backups()
        self.assertEqual((backup / ".config/opencode/.legacy-config").read_text(), "legacy\n")
        self.assertFalse((backup / ".config/opencode/service.json").exists())

    def test_redirected_parents_fail_before_moving_and_retry(self):
        for parent in (".config", ".chezmoi-backups"):
            with self.subTest(parent=parent):
                outside = self.root / "external"
                outside.mkdir(exist_ok=True)
                link = self.home / parent
                link.symlink_to(outside, target_is_directory=True)
                self.put(".vimrc")
                result = self.chezmoi("apply", "--force", check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Cleanup refused:", result.stderr)
                self.assertEqual((self.home / ".vimrc").read_text(), "legacy\n")
                self.assertEqual(list(outside.iterdir()), [])
                link.unlink()
        self.chezmoi("apply", "--force")
        self.assertEqual(len(self.backups()), 1)

    def test_dry_run_has_no_side_effects(self):
        self.put(".vimrc")
        self.chezmoi("apply", "--dry-run")
        self.assertEqual((self.home / ".vimrc").read_text(), "legacy\n")
        self.assertEqual(self.backups(), [])
        self.chezmoi("apply", "--force")
        self.assertEqual(len(self.backups()), 1)

    def test_clean_home_needs_no_backup(self):
        self.chezmoi("apply")
        self.assertEqual(self.backups(), [])
        self.assertTrue((self.home / ".chezmoi-backups/.pre-install-complete").is_file())

    def test_script_changes_do_not_sweep_again(self):
        self.put(".config/direnv/direnvrc")
        self.chezmoi("apply")
        original_backups = self.backups()
        self.put(".config/direnv/direnvrc", "new customization\n")
        script = self.source / SCRIPT
        script.write_text(script.read_text().replace("set -eu", "set -eu\n# Updated script"))
        self.chezmoi("apply")
        self.assertEqual(self.backups(), original_backups)
        self.assertEqual((self.home / ".config/direnv/direnvrc").read_text(),
                         "new customization\n")

    def test_partial_failure_keeps_backups_and_retries(self):
        self.put(".vimrc")
        self.put(".gitconfig")
        tools = self.root / "tools"
        tools.mkdir()
        real_mv = shutil.which("mv")
        stub = tools / "mv"
        stub.write_text('#!/bin/sh\ncase "$1" in */.gitconfig) exit 42;; esac\n'
                        f'exec "{real_mv}" "$@"\n')
        stub.chmod(0o755)
        original_path = self.env["PATH"]
        self.env["PATH"] = str(tools) + os.pathsep + original_path
        result = self.chezmoi("apply", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cleanup refused: cannot back up", result.stderr)
        self.assertIn("cleanup is not marked complete", result.stderr)
        first, = self.backups()
        self.assertEqual((first / ".vimrc").read_text(), "legacy\n")
        self.assertFalse((self.home / ".vimrc").exists())
        self.assertEqual((self.home / ".gitconfig").read_text(), "legacy\n")
        self.assertFalse((self.home / ".chezmoi-backups/.pre-install-complete").exists())
        self.assertFalse((self.home / "install-probe").exists())
        self.env["PATH"] = original_path
        self.chezmoi("apply")
        self.assertEqual(len(self.backups()), 2)
        self.assertEqual((first / ".vimrc").read_text(), "legacy\n")
        self.assertEqual(self.chezmoi("diff").stdout, "")

    @unittest.skipIf(os.geteuid() == 0, "root bypasses directory permissions")
    def test_permission_preflight_prevents_partial_sweep(self):
        self.put(".vimrc")
        self.put(".config/nvim/init.vim")
        directory = self.home / ".config/nvim"
        directory.chmod(0o500)
        try:
            result = self.chezmoi("apply", check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Cleanup refused: cannot back up", result.stderr)
            self.assertEqual(self.backups(), [])
            self.assertEqual((self.home / ".vimrc").read_text(), "legacy\n")
            self.assertTrue((directory / "init.vim").exists())
            self.assertFalse((self.home / ".chezmoi-backups/.pre-install-complete").exists())
        finally:
            directory.chmod(0o700)
        self.chezmoi("apply")
        self.assertEqual(len(self.backups()), 1)

    def test_starship_prioritizes_prompt_latency(self):
        config = tomllib.loads(self.chezmoi("cat", str(self.home / ".config/starship.toml")).stdout)
        self.assertEqual(config["scan_timeout"], 10)
        self.assertEqual(config["command_timeout"], 100)
        self.assertFalse(config["follow_symlinks"])

    def test_cloud_script_is_empty(self):
        self.config.write_text('[data]\nvariant = "claude-cloud"\n')
        script = self.chezmoi("cat", str(self.home / "00-cleanup-legacy-config.sh")).stdout
        self.assertEqual(script.strip(), "")

    def test_plugin_dependencies_recover_after_sweep_and_later_loss(self):
        config_dir = self.source / "dot_config/mise"
        config_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SOURCE / "dot_config/mise/config.toml", config_dir / "config.toml")
        plugins = {"codex-quota-sidebar": "zod", "dir-tree-bottom": "opencode-dir-tree-tui"}
        for name, dependency in plugins.items():
            script = f"run_after_install-opencode-{name}.sh.tmpl"
            shutil.copyfile(SOURCE / script, self.source / script)
            relative = f"dot_config/opencode/cli-plugins/{name}"
            directory = self.source / relative
            directory.mkdir(parents=True)
            for filename in ("package.json", "package-lock.json"):
                shutil.copyfile(SOURCE / relative / filename, directory / filename)
            # Model an existing installation removed by the first sweep.
            self.put(f".config/opencode/cli-plugins/{name}/node_modules/{dependency}/package.json")
        tools = self.root / "tools"
        tools.mkdir()
        npm = tools / "mise-npm"
        npm.write_text('''#!/bin/sh
set -eu
test "$1" = ci
test "$2" = --prefix
dir=$3
test -f "$dir/package-lock.json"
case "$dir" in
    */codex-quota-sidebar)
        dependency=zod
        mkdir -p "$dir/node_modules/opencode-codex-usage"
        printf '{}\\n' > "$dir/node_modules/opencode-codex-usage/package.json"
        ;;
    */dir-tree-bottom) dependency=opencode-dir-tree-tui ;;
    *) exit 98 ;;
esac
if [ -f "$HOME/fail-npm" ]; then exit 42; fi
mkdir -p "$dir/node_modules/$dependency"
printf '{}\\n' > "$dir/node_modules/$dependency/package.json"
printf '%s\\n' "$dir" >> "$HOME/npm-calls"
''')
        npm.chmod(0o755)
        # The inherited npm represents a broken asdf shim. Only mise may select npm.
        ambient = tools / "npm"
        ambient.write_text('#!/bin/sh\necho "unexpected asdf shim" >&2\nexit 99\n')
        ambient.chmod(0o755)
        mise = tools / "mise"
        mise.write_text('''#!/bin/sh
set -eu
test "$2" = node@@NODE_VERSION@
case "$1" in
    install) exit 0 ;;
    exec)
        test "$3" = --
        test "$4" = npm
        shift 4
        exec "$(dirname "$0")/mise-npm" "$@"
        ;;
    *) exit 98 ;;
esac
'''.replace("@NODE_VERSION@", tomllib.loads((SOURCE / "dot_config/mise/config.toml").read_text())["tools"]["node"]))
        mise.chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]
        self.chezmoi("apply")
        self.assertEqual(len((self.home / "npm-calls").read_text().splitlines()), 2)
        self.chezmoi("apply")
        self.assertEqual(len((self.home / "npm-calls").read_text().splitlines()), 2)
        quota = self.home / ".config/opencode/cli-plugins/codex-quota-sidebar"
        shutil.move(quota / "node_modules", self.root / "lost-node-modules")
        self.put("fail-npm")
        result = self.chezmoi("apply", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((quota / "node_modules/.chezmoi-lock-sha256").exists())
        (self.home / "fail-npm").unlink()
        self.chezmoi("apply")
        self.assertTrue((quota / "node_modules/zod/package.json").is_file())
        self.assertEqual(len((self.home / "npm-calls").read_text().splitlines()), 3)
        lock = self.source / "dot_config/opencode/cli-plugins/codex-quota-sidebar/package-lock.json"
        lock.write_text(lock.read_text() + "\n")
        self.chezmoi("apply")
        self.assertEqual(len((self.home / "npm-calls").read_text().splitlines()), 4)
        self.assertEqual(len(self.backups()), 1)


if __name__ == "__main__":
    unittest.main()
