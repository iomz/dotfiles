"""Run the rendered vendor install script runner against stub commands."""

import os
import shutil
import subprocess
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome, stub

SCRIPT = "run_after_install-scripts.sh.tmpl"


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class InstallScriptsTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.h.copy(".chezmoitemplates/tool-selected")
        self.root = self.h.root
        self.home = self.h.home
        self.calls = self.root / "calls"
        self.calls.write_text("")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # PATH holds only stubs and the utilities the script and stubs need.
        for tool in ("cat", "mkdir", "mktemp", "rm"):
            (self.bin / tool).symlink_to(shutil.which(tool))
        self.stub("curl", 'while [ "$1" != -o ]; do shift; done; : > "$2"')
        # An "installer" creates the file listed for its tool under $CREATES.
        self.creates = self.root / "creates"
        self.creates.mkdir()
        self.stub("bash", 'path=$(cat "$CREATES/${1##*/}") && mkdir -p "${path%/*}" && : > "$path"')
        self.tools = {
            "alpha": {"darwin": {"script": {"url": "https://a.example/install",
                                            "creates": "~/.alpha/bin/alpha"}},
                      "groups": ["stem"]},
            "beta": {"darwin": {"script": {"url": "https://b.example/install", "args": ["--quiet"],
                                           "creates": "~/.local/bin/beta"}},
                     "linux": {"script": {"url": "https://b.example/install",
                                          "creates": "~/.local/bin/beta"}},
                     "groups": ["stem"]},
            "gamma": {"darwin": {"script": {"url": "https://c.example/install",
                                            "creates": "~/.local/bin/gamma"}},
                      "hosts": ["leaf"]},
            "app": {"darwin": {"cask": "app"}},
        }

    def stub(self, name, body):
        stub(self.bin, name, body, self.calls)

    def render(self, host="stem1", os_name="darwin"):
        data = {"chezmoi": {"os": os_name, "arch": "arm64", "homeDir": str(self.home)},
                "host": host, "tools": self.tools,
                "hosts": {"stem1": {"groups": ["stem"]}, "leaf": {}}}
        return self.h.render((SOURCE / SCRIPT).read_text(), data)

    def run_script(self, **kwargs):
        script = self.root / "install-scripts.sh"
        script.write_text(self.render(**kwargs))
        (self.root / "tmp").mkdir(exist_ok=True)
        for name, tool in self.tools.items():
            vendor = tool.get(kwargs.get("os_name", "darwin"), {}).get("script")
            if vendor:
                (self.creates / name).write_text(vendor["creates"].replace("~", str(self.home), 1))
        env = dict(os.environ, PATH=str(self.bin), TMPDIR=str(self.root / "tmp"),
                   CREATES=str(self.creates))
        result = subprocess.run([shutil.which("sh"), str(script)], text=True, capture_output=True,
                                stdin=subprocess.DEVNULL, env=env)
        return result.returncode, result.stderr

    def installs(self):
        return [line for line in self.calls.read_text().splitlines() if line.startswith("curl ")]

    def test_installs_selected_missing_tools_with_their_args(self):
        status, stderr = self.run_script()
        self.assertEqual(status, 0, stderr)
        self.assertNotIn("failed", stderr)
        self.assertEqual(len(self.installs()), 2)
        calls = self.calls.read_text()
        self.assertIn("https://a.example/install", calls)
        self.assertIn("https://b.example/install", calls)
        self.assertNotIn("c.example", calls)
        self.assertRegex(calls, r"bash \S+/beta --quiet\n")
        self.assertTrue((self.home / ".alpha/bin/alpha").exists())
        self.assertEqual(list((self.root / "tmp").iterdir()), [], "downloads are removed")

    def test_renders_empty_once_every_tool_exists(self):
        self.run_script()
        self.assertEqual(self.render().strip(), "")
        self.assertEqual(self.render(host="other").strip(), "")

    def test_selects_by_os_table_and_host(self):
        self.assertNotIn("a.example", self.render(os_name="linux"))
        self.assertIn("b.example", self.render(os_name="linux"))
        leaf = self.render(host="leaf")
        self.assertIn("c.example", leaf)
        self.assertNotIn("a.example", leaf)

    def test_failures_do_not_stop_the_rest_or_fail_the_apply(self):
        self.stub("curl", 'case "$*" in *a.example*) exit 22 ;; esac; '
                          'while [ "$1" != -o ]; do shift; done; : > "$2"')
        status, stderr = self.run_script()
        self.assertEqual(status, 0)
        self.assertIn("failed: alpha", stderr)
        self.assertIn("next chezmoi apply retries", stderr)
        self.assertTrue((self.home / ".local/bin/beta").exists())

    def test_an_install_that_creates_nothing_counts_as_failed(self):
        self.stub("bash", "exit 0")
        status, stderr = self.run_script()
        self.assertEqual(status, 0)
        self.assertIn("failed: alpha beta", stderr)


if __name__ == "__main__":
    unittest.main()
