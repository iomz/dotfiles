"""Run the rendered Homebrew installer script against stub commands."""

import os
import shutil
import subprocess
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome, run_on_terminal, stub

SCRIPT = "run_before_10-install-homebrew.sh.tmpl"
URL = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class InstallHomebrewTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.h.source = self.h.root / "source"
        self.root = self.h.root
        self.calls = self.root / "calls"
        self.calls.write_text("")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # PATH holds only stubs and the utilities the script needs.
        for tool in ("grep", "mkdir", "mktemp", "rm", "tr"):
            (self.bin / tool).symlink_to(shutil.which(tool))
        self.stub("id", 'echo "staff admin everyone"')
        self.stub("curl", 'while [ "$1" != -o ]; do shift; done; echo "echo installer ran" > "$2"')
        self.stub("bash", '{} "$1" >> "{}"'.format(shutil.which("sh"), self.calls))

    def stub(self, name, body):
        stub(self.bin, name, body, self.calls)

    def render(self, os_name="darwin", brew_paths=("/nonexistent/brew",)):
        data = {"chezmoi": {"os": os_name, "homeDir": str(self.root / "home")},
                "brew_paths": list(brew_paths)}
        return self.h.render((SOURCE / SCRIPT).read_text(), data)

    @property
    def pending(self):
        return self.root / "home/.local/state/dotfiles/homebrew-install-pending"

    def run_script(self, terminal):
        script = self.root / "install-homebrew.sh"
        script.write_text(self.render())
        env = dict(os.environ, PATH=str(self.bin), TMPDIR=str(self.root / "tmp"))
        (self.root / "tmp").mkdir(exist_ok=True)
        if not terminal:
            result = subprocess.run([shutil.which("sh"), str(script)], text=True, capture_output=True,
                                    stdin=subprocess.DEVNULL, env=env)
            return result.returncode, result.stderr
        return run_on_terminal(script, env)

    def test_renders_empty_where_brew_exists_or_off_macos(self):
        brew = self.root / "brew"
        brew.write_text("")
        self.assertEqual(self.render(brew_paths=["/nonexistent/brew", str(brew)]).strip(), "")
        self.assertEqual(self.render(os_name="linux").strip(), "")
        self.assertIn("#!/bin/sh", self.render())

    def test_installs_from_a_complete_download_on_a_terminal(self):
        status, _ = self.run_script(terminal=True)
        self.assertEqual(status, 0)
        calls = self.calls.read_text()
        self.assertIn(URL, calls)
        self.assertIn("installer ran", calls)
        self.assertEqual(list((self.root / "tmp").iterdir()), [], "the download is removed")
        self.assertFalse(self.pending.exists())

    def test_failed_install_does_not_fail_the_apply(self):
        self.stub("curl", "exit 22")
        status, output = self.run_script(terminal=True)
        self.assertEqual(status, 0)
        self.assertIn("next chezmoi apply retries", output)
        self.assertNotIn("bash ", self.calls.read_text())
        self.assertTrue(self.pending.exists())

    def test_failed_install_is_retried_even_where_brew_exists(self):
        # The installer creates bin/brew before steps that can still fail.
        brew = self.root / "brew"
        brew.write_text("")
        self.stub("bash", 'exit 1')
        self.run_script(terminal=True)
        self.assertTrue(self.pending.exists())
        self.assertIn("#!/bin/sh", self.render(brew_paths=[str(brew)]))
        self.stub("bash", 'exit 0')
        self.run_script(terminal=True)
        self.assertFalse(self.pending.exists())
        self.assertEqual(self.render(brew_paths=[str(brew)]).strip(), "")

    def test_skips_without_a_terminal(self):
        status, stderr = self.run_script(terminal=False)
        self.assertEqual(status, 0)
        self.assertIn("run chezmoi apply in a terminal", stderr)
        self.assertNotIn("curl", self.calls.read_text())

    def test_skips_for_non_admin_users(self):
        self.stub("id", 'echo "staff everyone"')
        status, _ = self.run_script(terminal=True)
        self.assertEqual(status, 0)
        self.assertNotIn("curl", self.calls.read_text())


if __name__ == "__main__":
    unittest.main()
