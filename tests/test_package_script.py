"""Run the rendered Linux package script against stub package managers."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = "run_once_install-packages.sh.tmpl"
DATA = {
    "chezmoi": {"os": "linux", "arch": "amd64"},
    "host": "h",
    "hosts": {},
    "tools": {
        "aptonly": {"linux": {"apt": "pkg-a"}},
        "both": {"linux": {"apt": "pkg-b", "brew": "brew-b"}},
        "brewonly": {"linux": {"brew": "brew-c"}},
        "have": {"linux": {"apt": "pkg-have"}},
        "runtime": {"mise": "1"},
    },
}


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class LinuxPackageScriptTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="package-script-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        source = self.root / "source"
        (source / ".chezmoitemplates").mkdir(parents=True)
        for name in ("tool-selected", "selects-mise"):
            shutil.copyfile(SOURCE / ".chezmoitemplates" / name,
                            source / ".chezmoitemplates" / name)
        (self.root / "home").mkdir()
        (self.root / "config.toml").write_text("")
        rendered = subprocess.run(
            ["chezmoi", "--source", str(source), "--destination", str(self.root / "home"),
             "--config", str(self.root / "config.toml"), "--override-data", json.dumps(DATA),
             "execute-template", (SOURCE / SCRIPT).read_text()],
            env=dict(os.environ, HOME=str(self.root)), text=True, capture_output=True, check=True)
        self.script = self.root / "install-packages.sh"
        self.script.write_text(rendered.stdout)
        self.calls = self.root / "calls"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # PATH holds only stubs and the utilities the script needs, so a real
        # apt-get or brew on the test machine cannot leak in.
        for tool in ("awk", "grep"):
            (self.bin / tool).symlink_to(shutil.which(tool))

    def stub(self, name, body="exit 0"):
        path = self.bin / name
        path.write_text(f'#!/bin/sh\necho "{name} $*" >> "{self.calls}"\n{body}\n')
        path.chmod(0o755)

    def run_script(self):
        self.calls.write_text("")
        result = subprocess.run([shutil.which("sh"), str(self.script)], text=True, capture_output=True,
                                env=dict(os.environ, PATH=str(self.bin)))
        self.assertEqual(result.returncode, 0, result.stderr)
        installs = [line for line in self.calls.read_text().splitlines() if " install " in line]
        return installs, result.stderr

    def stub_common(self):
        self.stub("sudo")
        self.stub("mise")
        self.stub("dpkg-query", 'echo "ii pkg-have"')

    def test_apt_preferred_and_brew_for_brew_only_tools(self):
        self.stub_common()
        self.stub("apt-get")
        self.stub("brew")
        installs, _ = self.run_script()
        self.assertEqual(installs, ["sudo apt install -y pkg-a pkg-b", "brew install brew-c"])

    def test_brew_covers_hosts_without_apt(self):
        self.stub_common()
        self.stub("brew")
        installs, stderr = self.run_script()
        self.assertEqual(installs, ["brew install brew-b brew-c"])
        self.assertIn("skipped (no usable package manager): pkg-a pkg-have", stderr)

    def test_without_package_managers_everything_is_reported(self):
        self.stub_common()
        installs, stderr = self.run_script()
        self.assertEqual(installs, [])
        self.assertIn("pkg-a pkg-b brew-c pkg-have", stderr)


if __name__ == "__main__":
    unittest.main()
