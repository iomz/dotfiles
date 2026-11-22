"""Run the rendered Linux package script against stub package managers."""

import json
import os
from pathlib import Path
import pty
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


class PackageScriptCase(unittest.TestCase):
    data = DATA

    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="package-script-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        source = self.root / "source"
        (source / ".chezmoitemplates").mkdir(parents=True)
        for name in ("tool-selected", "selects-mise", "brew-path"):
            shutil.copyfile(SOURCE / ".chezmoitemplates" / name,
                            source / ".chezmoitemplates" / name)
        (self.root / "home").mkdir()
        (self.root / "config.toml").write_text("")
        self.script = self.root / "install-packages.sh"
        self.render(self.data)
        self.calls = self.root / "calls"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # PATH holds only stubs and the utilities the script needs, so a real
        # apt-get or brew on the test machine cannot leak in.
        self.stub("id", "echo 1000")
        for tool in ("awk", "grep"):
            (self.bin / tool).symlink_to(shutil.which(tool))

    def render(self, data):
        rendered = subprocess.run(
            ["chezmoi", "--source", str(self.root / "source"), "--destination", str(self.root / "home"),
             "--config", str(self.root / "config.toml"), "--override-data", json.dumps(data),
             "execute-template", (SOURCE / SCRIPT).read_text()],
            env=dict(os.environ, HOME=str(self.root)), text=True, capture_output=True, check=True)
        self.script.write_text(rendered.stdout)

    def stub(self, name, body="exit 0", directory=None):
        path = (directory or self.bin) / name
        path.write_text(f'#!/bin/sh\necho "{name} $*" >> "{self.calls}"\n{body}\n')
        path.chmod(0o755)

    def run_script(self):
        self.calls.write_text("")
        result = subprocess.run([shutil.which("sh"), str(self.script)], text=True, capture_output=True,
                                stdin=subprocess.DEVNULL,
                                env=dict(os.environ, PATH=str(self.bin)))
        self.assertEqual(result.returncode, 0, result.stderr)
        installs = [line for line in self.calls.read_text().splitlines() if " install " in line]
        return installs, result.stderr


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class LinuxPackageScriptTest(PackageScriptCase):
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

    def test_unusable_sudo_falls_back_to_brew(self):
        self.stub_common()
        self.stub("sudo", "exit 1")
        self.stub("apt-get")
        self.stub("brew")
        installs, stderr = self.run_script()
        self.assertEqual(installs, ["brew install brew-b brew-c"])
        # Installed apt packages need neither root nor a warning.
        self.assertIn("skipped (no usable package manager): pkg-a\n", stderr)
        self.assertEqual(self.calls.read_text().count("sudo "), 1, "sudo is probed once")

    def test_missing_sudo_skips_without_failing(self):
        self.stub("dpkg-query", 'echo "ii pkg-have"')
        self.stub("apt-get")
        installs, stderr = self.run_script()
        self.assertEqual(installs, [])
        self.assertIn("pkg-a pkg-b brew-c mise", stderr)
        self.assertIn("to retry later", stderr)

    def test_root_needs_no_sudo(self):
        self.stub("id", "echo 0")
        self.stub("dpkg-query", 'echo "ii pkg-have"')
        self.stub("apt-get")
        self.stub("apt")
        self.stub("extrepo")
        installs, _ = self.run_script()
        self.assertEqual(installs, ["apt install -y pkg-a pkg-b", "apt install -y mise"])

    def test_password_prompt_counts_as_usable_sudo(self):
        self.stub_common()
        self.stub("sudo", '[ "$1" != -n ]')
        self.stub("apt-get")
        self.calls.write_text("")
        pid, fd = pty.fork()
        if pid == 0:
            os.execve(shutil.which("sh"), ["sh", str(self.script)], dict(os.environ, PATH=str(self.bin)))
        try:
            while os.read(fd, 4096):
                pass
        except OSError:  # EIO at end of output on Linux
            pass
        self.assertEqual(os.waitpid(pid, 0)[1], 0)
        self.assertIn("sudo apt install -y pkg-a pkg-b", self.calls.read_text())

    def test_brew_outside_path_is_found(self):
        self.stub_common()
        prefix = self.root / "homebrew" / "bin"
        prefix.mkdir(parents=True)
        self.stub("brew", directory=prefix)
        self.render(dict(self.data, brew_paths=["/nonexistent/brew", str(prefix / "brew")]))
        installs, _ = self.run_script()
        self.assertEqual(installs, ["brew install brew-b brew-c"])

    def test_without_package_managers_everything_is_reported(self):
        self.stub_common()
        installs, stderr = self.run_script()
        self.assertEqual(installs, [])
        self.assertIn("pkg-a pkg-b brew-c pkg-have", stderr)


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class DarwinPackageScriptTest(PackageScriptCase):
    data = {
        "chezmoi": {"os": "darwin", "arch": "arm64"},
        "host": "h",
        "hosts": {},
        "tools": {
            "have": {"darwin": {"brew": "f-have"}},
            "want": {"darwin": {"brew": "f-want"}},
        },
    }

    def test_installs_only_missing_formulae(self):
        self.stub("brew", '[ "$1" != list ] || echo f-have')
        installs, _ = self.run_script()
        self.assertEqual(installs, ["brew install f-want"])

    def test_missing_homebrew_skips_without_failing(self):
        installs, stderr = self.run_script()
        self.assertEqual(installs, [])
        self.assertIn("skipped (no usable package manager): f-have f-want\n", stderr)
        self.assertIn("to retry later", stderr)


if __name__ == "__main__":
    unittest.main()
