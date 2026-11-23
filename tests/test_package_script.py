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
        # Every package is known unless named in $UNKNOWN. Labels are translated
        # outside the C locale, as apt does.
        self.stub("apt-cache", 'label=Candidate; [ "${LC_ALL:-}" = C ] || label=候補\n'
                               'case " $UNKNOWN " in *" $2 "*) echo "  $label: (none)" ;; *) echo "  $label: 1.0" ;; esac')
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

    def run_script(self, unknown="", **env):
        self.calls.write_text("")
        result = subprocess.run([shutil.which("sh"), str(self.script)], text=True, capture_output=True,
                                stdin=subprocess.DEVNULL,
                                env=dict(os.environ, PATH=str(self.bin), UNKNOWN=unknown, **env))
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

    def test_missing_extrepo_or_mise_package_still_reports(self):
        self.stub("id", "echo 0")
        self.stub("dpkg-query", 'echo "ii pkg-have"')
        self.stub("apt-get")
        self.stub("apt", '[ "$*" != "install -y mise" ]')
        _, stderr = self.run_script(unknown="pkg-b")
        self.assertIn("skipped (unknown to the package manager): pkg-b", stderr)
        self.assertIn("skipped (no usable package manager): brew-c mise", stderr)

    def test_unknown_names_are_skipped_and_reported(self):
        self.stub_common()
        self.stub("apt-get")
        self.stub("brew", 'case " $UNKNOWN " in *" $2 "*) [ "$1" != info ] ;; esac')
        installs, stderr = self.run_script(unknown="pkg-b brew-c")
        self.assertEqual(installs, ["sudo apt install -y pkg-a"])
        self.assertIn("skipped (unknown to the package manager): pkg-b brew-c", stderr)

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
            "tapped": {"darwin": {"brew": "owner/tap/f-tap"}},
            "app": {"darwin": {"cask": "c-have"}},
            "app2": {"darwin": {"cask": "c-want"}},
            "app3": {"darwin": {"cask": "c-more"}},
        },
    }

    def setUp(self):
        super().setUp()
        # Names in $UNKNOWN are unknown to brew info; casks in $FAIL fail to install.
        self.stub("brew", '''case "$1" in
  list) case "$3" in --formula) echo f-have; echo f-tap ;; --cask) echo c-have ;; esac ;;
  info) case " $UNKNOWN " in *" $3 "*) exit 1 ;; esac ;;
  install) case " ${FAIL:-} " in *" $3 "*) exit 1 ;; esac ;;
esac''')

    def test_installs_only_missing_formulae_and_casks(self):
        installs, _ = self.run_script()
        # Apps first: a formula may need one, as sshfs-mac needs macfuse.
        self.assertEqual(installs, ["brew install --cask c-want", "brew install --cask c-more",
                                    "brew install --formula f-want"])

    def test_tap_qualified_formulae_match_by_name_and_skip_the_info_check(self):
        self.stub("brew", 'case "$1 $3" in "list --formula") echo f-have; echo f-want ;; info*) exit 1 ;; esac')
        installs, _ = self.run_script()
        self.assertIn("brew install --formula owner/tap/f-tap", installs)
        self.assertNotIn("info --formula owner/tap/f-tap", self.calls.read_text())

    def test_unknown_names_are_skipped_and_reported(self):
        installs, stderr = self.run_script(unknown="f-want c-want")
        self.assertEqual(installs, ["brew install --cask c-more"])
        self.assertIn("skipped (unknown to Homebrew): f-want c-want", stderr)

    def test_a_failed_cask_does_not_stop_the_others(self):
        installs, stderr = self.run_script(FAIL="c-want")
        self.assertIn("brew install --cask c-more", installs)
        self.assertIn("install-packages: failed: c-want", stderr)
        self.assertIn("to retry later", stderr)

    def test_missing_homebrew_skips_without_failing(self):
        (self.bin / "brew").unlink()
        installs, stderr = self.run_script()
        self.assertEqual(installs, [])
        self.assertIn("skipped (no usable package manager): f-have owner/tap/f-tap f-want c-have c-want c-more\n", stderr)
        self.assertIn("to retry later", stderr)


if __name__ == "__main__":
    unittest.main()
