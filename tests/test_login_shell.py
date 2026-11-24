"""Render and run the login shell script against stub account lookups."""

import os
from pathlib import Path
import shutil
import subprocess
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome, run_on_terminal, stub

SCRIPT = "run_after_30-login-shell.sh.tmpl"


def system_zsh():
    for line in Path("/etc/shells").read_text().splitlines():
        if line in ("/bin/zsh", "/usr/bin/zsh") and os.access(line, os.X_OK):
            return line
    return None


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class LoginShellTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.h.copy(".chezmoitemplates/variant")
        self.root = self.h.root
        self.calls = self.root / "calls"
        self.calls.write_text("")
        # Only stubs and plain utilities: no real dscl or getent answers.
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for tool in ("sh", "cut", "sed"):
            (self.bin / tool).symlink_to(shutil.which(tool))
        self.stub("id", "echo tester")
        self.stub("chsh", 'echo "chsh $*" >> "$CALLS"; exit "${CHSH_STATUS:-0}"')

    def stub(self, name, body):
        stub(self.bin, name, body)

    def render(self, login_shell, variant="helm"):
        self.stub("getent", f'echo "tester:x:1000:1000::/home/tester:{login_shell}"')
        self.h.env["PATH"] = str(self.bin)
        return self.h.render((SOURCE / SCRIPT).read_text(), {"variant": variant})

    def run_script(self, terminal, **env):
        script = self.root / "login-shell.sh"
        script.write_text(self.render("/bin/bash"))
        env = dict(os.environ, PATH=str(self.bin), CALLS=str(self.calls), **env)
        if not terminal:
            result = subprocess.run([shutil.which("sh"), str(script)], env=env, text=True,
                                    capture_output=True, stdin=subprocess.DEVNULL)
            return result.returncode, result.stderr
        return run_on_terminal(script, env)

    def test_renders_only_while_the_login_shell_is_not_zsh(self):
        self.assertIn("#!/bin/sh", self.render("/bin/bash"))
        self.assertEqual(self.render("/usr/bin/zsh").strip(), "")
        self.assertEqual(self.render("/bin/bash", variant="agent-sandbox").strip(), "")
        self.assertEqual(self.render("/bin/bash", variant="workstation").count("#!/bin/sh"), 1)

    @unittest.skipUnless(system_zsh(), "no zsh in /etc/shells")
    def test_changes_the_login_shell_on_a_terminal(self):
        status, output = self.run_script(terminal=True)
        self.assertEqual(status, 0, output)
        self.assertEqual(self.calls.read_text(), f"chsh -s {system_zsh()}\n")

    @unittest.skipUnless(system_zsh(), "no zsh in /etc/shells")
    def test_prints_the_command_without_a_terminal(self):
        status, stderr = self.run_script(terminal=False)
        self.assertEqual(status, 0)
        self.assertIn(f"chsh -s {system_zsh()}", stderr)
        self.assertEqual(self.calls.read_text(), "")

    @unittest.skipUnless(system_zsh(), "no zsh in /etc/shells")
    def test_a_failed_chsh_does_not_fail_the_apply(self):
        status, output = self.run_script(terminal=True, CHSH_STATUS="1")
        self.assertEqual(status, 0)
        self.assertIn("chsh failed", output)


if __name__ == "__main__":
    unittest.main()
