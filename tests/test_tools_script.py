"""Exercise scripts/tools.py against a fixed temporary inventory."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / "scripts/tools.py"
# Fixed fixture, independent of the real inventory's versions.
FIXTURE = """\
# Fixture inventory.

[hosts.oxalis]
groups = ["dev"]

[tools.ansible]
mise_id = "pipx:ansible"
mise = { version = "14.2.0", uvx = false, pipx_args = "--include-deps" }

[tools.bat]
mise = "latest"

[tools.gh]
mise = "2.95.0"

[tools.git]
darwin.brew = "git"
linux.apt = "git"

[tools.wget]
darwin.brew = "wget"

[tools.curl]
linux.apt = "curl"

# --- Homebrew guard ---

[homebrew_guard]
extra = ["poetry"]
"""


class ToolsScriptTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="tools-script-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.inventory = root / "tools.toml"
        self.inventory.write_text(FIXTURE)
        self.original = self.inventory.read_text()
        bin_dir = root / "bin"
        bin_dir.mkdir()
        mise = bin_dir / "mise"
        mise.write_text('#!/bin/sh\ntest "$1" = latest || exit 98\necho 9.9.9\n')
        mise.chmod(0o755)
        self.env = dict(os.environ, PATH=str(bin_dir) + os.pathsep + os.environ["PATH"])

    def tools(self, *args, check=True):
        result = subprocess.run([sys.executable, "-I", str(SCRIPT), "--inventory",
                                 str(self.inventory), *args],
                                env=self.env, capture_output=True, text=True)
        if check and result.returncode != 0:
            self.fail(result.stderr)
        return result

    def data(self):
        return tomllib.loads(self.inventory.read_text())["tools"]

    def assert_unchanged(self, result):
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.inventory.read_text(), self.original)

    def test_add_mise_pins_latest_before_guard_section(self):
        self.tools("add", "yq", "mise", "--groups", "dev")
        self.assertEqual(self.data()["yq"], {"mise": "9.9.9", "groups": ["dev"]})
        text = self.inventory.read_text()
        self.assertLess(text.index("[tools.yq]"), text.index("[homebrew_guard]"))
        self.assertTrue(text.startswith(self.original[:text.index("[tools.yq]") - 1]))

    def test_add_explicit_version_and_mise_id(self):
        self.tools("add", "prettier", "mise", "3.0.0", "--mise-id", "npm:prettier")
        self.assertEqual(self.data()["prettier"], {"mise_id": "npm:prettier", "mise": "3.0.0"})

    def test_add_os_package_to_existing_entry(self):
        self.tools("add", "curl", "brew")
        self.assertEqual(self.data()["curl"], {"linux": {"apt": "curl"}, "darwin": {"brew": "curl"}})

    def test_rejected_adds_leave_file_unchanged(self):
        cases = [
            ("add", "gh", "mise"),                       # duplicate entry
            ("add", "gh", "apt"),                        # mise entry gets OS package
            ("add", "git", "brew"),                      # field already declared
            ("add", "yq", "mise", "--hosts", "oxalsi"),  # unknown host, reverted
            ("add", "wget2", "brew", "wget"),            # package name reused
            ("add", "bad.name", "mise"),
        ]
        for case in cases:
            with self.subTest(case=case):
                self.assert_unchanged(self.tools(*case, check=False))

    def test_bump_updates_pinned_versions_only(self):
        self.tools("bump")
        tools = self.data()
        self.assertEqual(tools["gh"]["mise"], "9.9.9")
        self.assertEqual(tools["ansible"]["mise"],
                         {"version": "9.9.9", "uvx": False, "pipx_args": "--include-deps"})
        self.assertEqual(tools["bat"]["mise"], "latest")
        self.assertEqual(tools["git"], tomllib.loads(self.original)["tools"]["git"])

    def test_bump_include_latest_and_single_entry(self):
        self.tools("bump", "bat", "--include-latest")
        tools = self.data()
        self.assertEqual(tools["bat"]["mise"], "9.9.9")
        self.assertEqual(tools["gh"]["mise"], tomllib.loads(self.original)["tools"]["gh"]["mise"])

    def test_bump_respects_hold(self):
        self.inventory.write_text(self.original.replace(
            '[tools.gh]\nmise = "2.95.0"\n', '[tools.gh]\nmise = "2.95.0"\nhold = true\n'))
        result = self.tools("bump", "gh")
        self.assertIn("hold", result.stdout)
        self.assertEqual(self.data()["gh"]["mise"], "2.95.0")

    def test_bump_keeps_other_lines(self):
        self.tools("bump")
        changed = [(a, b) for a, b in zip(self.original.splitlines(), self.inventory.read_text().splitlines())
                   if a != b]
        self.assertTrue(changed)
        for before, after in changed:
            self.assertTrue(before.startswith("mise =") and after.startswith("mise ="), (before, after))

    @unittest.skipUnless(sys.platform == "darwin", "tool-move is macOS-only")
    def test_move_refuses_wrong_direction_without_side_effects(self):
        self.assert_unchanged(self.tools("move", "git", "brew", check=False))
        self.assert_unchanged(self.tools("move", "gh", "mise", check=False))
        self.assert_unchanged(self.tools("move", "curl", "mise", check=False))


if __name__ == "__main__":
    unittest.main()
