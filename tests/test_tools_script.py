"""Exercise scripts/tools.py against a fixed temporary inventory."""

import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / "scripts/tools.py"


def load_tools_module():
    spec = importlib.util.spec_from_file_location("tools_script", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
# Fixed fixture, independent of the real inventory's versions.
FIXTURE = """\
# Fixture inventory.

[hosts.oxalis]
groups = ["stem"]

# --- mise ---------------------------------------------------------------

[tools.ansible]
mise_id = "pipx:ansible"
mise = { version = "14.2.0", uvx = false, pipx_args = "--include-deps" }
groups = ["stem"]

[tools.bat]
mise = "latest"
groups = ["stem"]

[tools.gh]
mise = "2.95.0"
groups = ["stem"]

# --- macOS and Linux packages -------------------------------------------

[tools.git]
darwin.brew = "git"
linux.apt = "git"

# --- macOS packages -----------------------------------------------------

[tools.wget]
# Kept for scripts.
darwin.brew = "wget"

# --- Linux packages -----------------------------------------------------

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
        self.tools("add", "yq", "mise", "--groups", "stem")
        self.assertEqual(self.data()["yq"], {"mise": "9.9.9", "groups": ["stem"]})
        text = self.inventory.read_text()
        self.assertLess(text.index("[tools.yq]"), text.index("[homebrew_guard]"))
        self.assertTrue(text.startswith(self.original[:text.index("[tools.yq]") - 1]))

    def test_scratch_inventory_is_never_applied(self):
        # Only edits to the real inventory run chezmoi apply.
        self.assertIn("not applied", self.tools("add", "yq", "mise", "1.0.0", "--groups", "stem").stdout)
        self.assertIn("not applied", self.tools("bump", "--no-apply").stdout)

    def test_add_explicit_version_and_mise_id(self):
        self.tools("add", "prettier", "mise", "3.0.0", "--mise-id", "npm:prettier",
                   "--groups", "stem")
        self.assertEqual(self.data()["prettier"], {"mise_id": "npm:prettier", "mise": "3.0.0",
                                                   "groups": ["stem"]})

    def sections(self):
        """Map each section title to the entry names under it, in file order."""
        result, title = {}, None
        for line in self.inventory.read_text().splitlines():
            if line.startswith("# --- "):
                title = line[len("# --- "):].rstrip(" -")
                result[title] = []
            elif line.startswith("[tools."):
                result[title].append(line[len("[tools."):-1])
        return result

    def test_normalize_is_stable_on_normalized_input(self):
        self.assertEqual(load_tools_module().normalize(FIXTURE), FIXTURE)

    def test_new_entries_land_sorted_in_their_section(self):
        self.tools("add", "aaa", "mise", "1.0.0", "--groups", "stem")
        self.tools("add", "fd", "apt")
        self.tools("add", "zstd", "brew")
        sections = self.sections()
        self.assertEqual(sections["mise"], ["aaa", "ansible", "bat", "gh"])
        self.assertEqual(sections["Linux packages"], ["curl", "fd"])
        self.assertEqual(sections["macOS packages"], ["wget", "zstd"])

    def test_adding_the_other_os_moves_the_entry_and_orders_keys(self):
        self.tools("add", "curl", "brew")
        sections = self.sections()
        self.assertEqual(sections["macOS and Linux packages"], ["curl", "git"])
        self.assertNotIn("Linux packages", sections)  # emptied sections disappear
        text = self.inventory.read_text()
        self.assertIn('[tools.curl]\ndarwin.brew = "curl"\nlinux.apt = "curl"\n', text)
        self.assertIn('[tools.wget]\n# Kept for scripts.\ndarwin.brew = "wget"\n', text)

    def test_vendor_scripts_get_their_own_section_and_refuse_other_managers(self):
        text = self.inventory.read_text().replace(
            "# --- Homebrew guard ---",
            '[tools.agent]\ndarwin.script = { url = "https://example.org/install", '
            'creates = "~/.local/bin/agent" }\n\n# --- Homebrew guard ---')
        self.inventory.write_text(load_tools_module().normalize(text))
        self.assertEqual(self.sections()["Vendor install scripts"], ["agent"])
        result = self.tools("add", "agent", "brew", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("vendor script", result.stderr)

    def test_add_os_package_to_existing_entry(self):
        self.tools("add", "curl", "brew")
        self.assertEqual(self.data()["curl"], {"linux": {"apt": "curl"}, "darwin": {"brew": "curl"}})

    def test_add_cask_lands_in_the_apps_section(self):
        self.tools("add", "zed", "cask")
        self.assertEqual(self.data()["zed"], {"darwin": {"cask": "zed"}})
        text = self.inventory.read_text()
        self.assertGreater(text.index("[tools.zed]"), text.index("# --- macOS apps"))

    def test_rejected_adds_leave_file_unchanged(self):
        cases = [
            ("add", "git", "cask"),                      # already a formula on macOS
            ("add", "gh", "mise"),                       # duplicate entry
            ("add", "gh", "apt"),                        # mise entry gets OS package
            ("add", "git", "brew"),                      # field already declared
            ("add", "yq", "mise", "--hosts", "oxalsi"),  # unknown host, reverted
            ("add", "wget2", "brew", "wget"),            # package name reused
            ("add", "bad.name", "mise"),
            ("add", "yq", "mise", "1.0.0"),              # mise without a scope
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
        unscoped = self.tools("move", "wget", "mise", "1.0.0", check=False)
        self.assert_unchanged(unscoped)
        self.assertIn("need --groups or --hosts", unscoped.stderr)


if __name__ == "__main__":
    unittest.main()
