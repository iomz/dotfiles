"""Validate the per-host tool inventory and its selection template."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest


SOURCE = Path(__file__).resolve().parents[1]
# scripts/tools.py validates edits by pointing this at the edited file.
INVENTORY = Path(os.environ.get("TOOLS_INVENTORY", SOURCE / ".chezmoidata/tools.toml"))
SELECTOR = SOURCE / ".chezmoitemplates/tool-selected"

ENTRY_KEYS = {"mise", "mise_id", "hold", "homebrew_guard", "hosts", "groups", "arch",
              "bin", "darwin", "linux"}
OS_KEYS = {"darwin": {"brew", "arch"}, "linux": {"apt", "brew", "arch"}}
ARCHES = {"amd64", "arm64"}


class InventorySchemaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = tomllib.loads(INVENTORY.read_text())
        cls.tools = cls.data["tools"]
        cls.hosts = cls.data["hosts"]
        cls.groups = {group for host in cls.hosts.values() for group in host.get("groups", [])}

    def test_entry_keys_are_known(self):
        for name, tool in self.tools.items():
            with self.subTest(tool=name):
                self.assertLessEqual(set(tool), ENTRY_KEYS)
                for os_name in OS_KEYS:
                    if os_name in tool:
                        self.assertLessEqual(set(tool[os_name]), OS_KEYS[os_name])
                        self.assertTrue(set(tool[os_name]) - {"arch"},
                                        f"{os_name} table declares no manager")

    def test_one_manager_family(self):
        for name, tool in self.tools.items():
            with self.subTest(tool=name):
                has_mise = "mise" in tool
                has_os = any(os_name in tool for os_name in OS_KEYS)
                self.assertNotEqual(has_mise, has_os,
                                    "declare either mise or OS tables, exactly one")
                if not has_mise:
                    for key in ("mise_id", "hold", "homebrew_guard"):
                        self.assertNotIn(key, tool, f"{key} requires mise")

    def test_hosts_and_groups(self):
        for name, tool in self.tools.items():
            with self.subTest(tool=name):
                self.assertFalse("hosts" in tool and "groups" in tool,
                                 "hosts and groups are mutually exclusive")
                self.assertLessEqual(set(tool.get("hosts", [])), set(self.hosts))
                self.assertLessEqual(set(tool.get("groups", [])), self.groups)
                for key in ("hosts", "groups"):
                    if key in tool:
                        self.assertTrue(tool[key], f"empty {key} never matches")

    def test_arch_values(self):
        for name, tool in self.tools.items():
            with self.subTest(tool=name):
                arches = list(tool.get("arch", []))
                for os_name in OS_KEYS:
                    arches += tool.get(os_name, {}).get("arch", [])
                self.assertLessEqual(set(arches), ARCHES)

    def test_types(self):
        for name, tool in self.tools.items():
            with self.subTest(tool=name):
                if "mise" in tool:
                    self.assertIsInstance(tool["mise"], (str, dict))
                for key in ("hold", "homebrew_guard"):
                    if key in tool:
                        self.assertIsInstance(tool[key], bool)

    def test_layout_is_normalized(self):
        # Sections, entry order and key order are derived; just tool-* keeps them.
        spec = importlib.util.spec_from_file_location("tools_script", SOURCE / "scripts/tools.py")
        tools = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(tools)
        text = INVENTORY.read_text()
        self.assertEqual(tools.normalize(text), text,
                         "run any just tool-* recipe, or scripts/tools.py normalize, to fix the layout")

    def test_package_names_are_unique_per_manager(self):
        seen = {}
        for name, tool in self.tools.items():
            packages = []
            if "mise" in tool:
                packages.append(("mise", tool.get("mise_id", name)))
            for os_name in OS_KEYS:
                for manager, package in tool.get(os_name, {}).items():
                    if manager != "arch":
                        packages.append((f"{os_name}.{manager}", package))
            for package in packages:
                with self.subTest(package=package):
                    self.assertNotIn(package, seen,
                                     f"also declared by {seen.get(package)}")
                    seen[package] = name


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class ToolSelectionTest(unittest.TestCase):
    TOOLS = {
        "everywhere": {"mise": "1"},
        "named": {"mise": "1", "hosts": ["alpha"]},
        "grouped": {"mise": "1", "groups": ["dev"]},
        "amd64-only": {"mise": "1", "arch": ["amd64"]},
        "linux-amd64": {"darwin": {"brew": "x"}, "linux": {"apt": "x", "arch": ["amd64"]}},
    }
    HOSTS = {"alpha": {"groups": ["dev"]}, "beta": {}}

    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="chezmoi-tools-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        (root / "src/.chezmoitemplates").mkdir(parents=True)
        shutil.copyfile(SELECTOR, root / "src/.chezmoitemplates/tool-selected")
        (root / "config.toml").write_text("")
        self.command = ["chezmoi", "--source", str(root / "src"), "--destination",
                        str(root / "home"), "--config", str(root / "config.toml"),
                        "--persistent-state", str(root / "state"), "--cache", str(root / "cache")]
        self.env = dict(os.environ, HOME=str(root))

    def selected(self, host, arch, os_name=""):
        data = {"tools": self.TOOLS, "hosts": self.HOSTS, "chezmoi": {"arch": arch}}
        if host is not None:
            data["host"] = host
        template = ('{{ range $name, $tool := .tools }}'
                    '{{ if eq (includeTemplate "tool-selected" (dict "tool" $tool "data" $ "os" "'
                    + os_name + '")) "true" }}{{ $name }} {{ end }}{{ end }}')
        result = subprocess.run(self.command + ["--override-data", json.dumps(data),
                                                "execute-template", template],
                                env=self.env, text=True, capture_output=True, check=True)
        return set(result.stdout.split())

    def test_declared_dev_host(self):
        self.assertEqual(self.selected("alpha", "arm64"),
                         {"everywhere", "named", "grouped", "linux-amd64"})

    def test_host_without_groups(self):
        self.assertEqual(self.selected("beta", "amd64"),
                         {"everywhere", "amd64-only", "linux-amd64"})

    def test_unknown_and_missing_host_get_unrestricted_entries(self):
        for host in ("stranger", None):
            with self.subTest(host=host):
                self.assertEqual(self.selected(host, "arm64"), {"everywhere", "linux-amd64"})

    def test_os_table_arch_applies_only_to_that_os(self):
        self.assertNotIn("linux-amd64", self.selected("beta", "arm64", "linux"))
        self.assertIn("linux-amd64", self.selected("beta", "arm64", "darwin"))
        self.assertIn("linux-amd64", self.selected("beta", "amd64", "linux"))


if __name__ == "__main__":
    unittest.main()
