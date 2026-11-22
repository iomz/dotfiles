"""Apply the real source as a dev and as a non-dev host into throwaway homes."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
MISE_FILES = (".config/mise/config.toml", ".config/zsh/rc.d/04-mise.zsh",
              ".config/zsh/rc.d/00-homebrew-guard.zsh")
DEV_SHELL_FILES = (".config/zsh/rc.d/02-plugin-manager.zsh", ".config/zsh/rc.d/05-zeno.zsh")
MISE_SCRIPTS = ("mise-install.sh", "install-opencode-codex-quota-sidebar.sh",
                "install-opencode-dir-tree-bottom.sh")


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class HostProfileTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="chezmoi-profile-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def chezmoi(self, host, *args):
        config = self.root / "config.toml"
        config.write_text(f'[data]\nvariant = "workstation"\nhost = "{host}"\n'
                          'git_name = "Test"\ngit_email = "test@example.org"\n')
        return subprocess.run(
            ["chezmoi", "--source", str(SOURCE), "--destination", str(self.home),
             "--config", str(config), "--persistent-state", str(self.root / "state"),
             "--cache", str(self.root / "cache"), "--no-tty", *args],
            env=dict(os.environ, HOME=str(self.home)), stdin=subprocess.DEVNULL,
            text=True, capture_output=True, check=True).stdout

    def apply(self, host):
        # Files only: scripts install packages.
        self.chezmoi(host, "apply", "--force", "--exclude", "scripts")

    def test_dev_host_gets_mise_and_plugins(self):
        self.apply("sazanka")
        for name in MISE_FILES + DEV_SHELL_FILES:
            self.assertTrue((self.home / name).is_file(), name)
        for name in MISE_SCRIPTS:
            self.assertTrue(self.chezmoi("sazanka", "cat", str(self.home / name)).strip(), name)

    def test_leaving_dev_removes_mise_and_plugins(self):
        self.apply("sazanka")
        self.apply("tinybox")
        for name in MISE_FILES + DEV_SHELL_FILES:
            self.assertFalse((self.home / name).exists(), name)
        for name in MISE_SCRIPTS:
            self.assertEqual(self.chezmoi("tinybox", "cat", str(self.home / name)).strip(), "", name)

    def test_only_dev_hosts_manage_neovim(self):
        self.assertIn(".config/nvim/init.lua", self.chezmoi("sazanka", "managed").splitlines())
        self.assertNotIn(".config/nvim", self.chezmoi("tinybox", "managed"))

    def test_existing_profile_is_left_alone(self):
        profile = self.home / ".profile"
        profile.write_text("# host-local\n")
        self.apply("tinybox")
        self.assertEqual(profile.read_text(), "# host-local\n")

    def test_zsh_directories_are_exact(self):
        self.apply("tinybox")
        leftovers = [self.home / ".config/zsh/rc.d/99-old.zsh",
                     self.home / ".config/zsh/functions/old"]
        for path in leftovers:
            path.write_text("# unmanaged\n")
        self.apply("tinybox")
        for path in leftovers:
            self.assertFalse(path.exists(), path)


if __name__ == "__main__":
    unittest.main()
