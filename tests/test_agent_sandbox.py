"""Isolated chezmoi checks; no network, package installs or real-home writes."""

import json
import hashlib
import os
import subprocess
import sys
import tarfile
import tomllib
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome

APM_VERSION = tomllib.loads((SOURCE / ".chezmoidata/tools.toml").read_text())["tools"]["apm-cli"]["mise"]


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class ClaudeCloudTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.root, self.home, self.config = self.h.root, self.h.home, self.h.config
        self.config.unlink()  # chezmoi init writes it
        # Model Cloud: repository cwd is not an ancestor/descendant of HOME.
        self.project = self.h.cwd = self.root / "workspace/repo"
        self.project.mkdir(parents=True)
        self.env = self.h.env
        self.env["TMPDIR"] = str(self.root)
        # Offline applies only check Node availability; real hook checks are manual.
        tools = self.root / "tools"
        tools.mkdir()
        node = tools / "node"
        node.write_text("#!/bin/sh\nexit 0\n")
        node.chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]
        self.env.pop("CLAUDE_CONFIG_DIR", None)

    def chezmoi(self, *args, check=True, timeout=None):
        return self.h.run(*args, check=check, timeout=timeout)

    def init_cloud(self):
        self.env["CHEZMOI_VARIANT"] = "agent-sandbox"
        self.chezmoi("init", "--promptDefaults")
        self.env.pop("CHEZMOI_VARIANT")

    def test_cloud_allowlist_and_persistence(self):
        self.init_cloud()
        self.chezmoi("init", "--promptDefaults")
        self.assertIn('variant = "agent-sandbox"', self.config.read_text())
        self.assertNotIn("git_email", self.config.read_text())
        self.assertEqual(set(self.chezmoi("managed").stdout.splitlines()), {
            ".apm", ".apm/apm.yml", ".claude", ".claude/CLAUDE.md", "agent-sandbox-apm.sh",
        })
        managed = self.chezmoi("managed").stdout.splitlines()
        for cloud_owned in (".gitconfig", ".claude.json", ".claude/AGENTS.md"):
            self.assertNotIn(cloud_owned, managed)
        manifest = self.chezmoi("cat", str(self.home / ".apm/apm.yml")).stdout
        self.assertNotIn("brain-vault", manifest)
        self.assertNotIn("iomz/skills", manifest)
        self.assertFalse(any(line.startswith("- ") for line in manifest.splitlines()))
        common = (SOURCE / ".chezmoitemplates/AGENTS.md").read_text().strip()
        instructions = self.chezmoi("cat", str(self.home / ".claude/CLAUDE.md")).stdout
        self.assertEqual(instructions.strip(), common)
        self.chezmoi("apply", "--dry-run")
        for os_name in ("linux", "darwin"):
            override = json.dumps({"chezmoi": {"os": os_name}})
            self.assertEqual(self.chezmoi("--override-data", override, "managed").stdout,
                             self.chezmoi("managed").stdout)

    def test_helm_os_rendering(self):
        for os_name in ("darwin", "linux"):
            with self.subTest(os=os_name):
                self.env["CHEZMOI_VARIANT"] = "helm"
                self.chezmoi("init", "--promptDefaults")
                override = json.dumps({"chezmoi": {"os": os_name}})
                managed = self.chezmoi("--override-data", override, "managed").stdout
                self.assertIn(".config/mise/config.toml", managed)
                self.assertIn(".config/zsh/.zshrc", managed)
                self.assertNotIn("agent-sandbox-apm.sh", managed)
                self.assertNotIn("scripts/bootstrap-agent-sandbox.sh", managed)
                self.assertIn(".claude/CLAUDE.md", managed)
                self.assertNotIn(".claude/AGENTS.md", managed)
                self.assertIn(".gitconfig", managed)
                self.assertIn(".codex/AGENTS.md", managed)
                common = (SOURCE / ".chezmoitemplates/AGENTS.md").read_text().strip()
                claude = self.chezmoi("--override-data", override, "cat",
                                      str(self.home / ".claude/CLAUDE.md")).stdout
                codex = self.chezmoi("--override-data", override, "cat",
                                     str(self.home / ".codex/AGENTS.md")).stdout
                self.assertEqual(claude.strip(), common)
                self.assertTrue(codex.startswith(common + "\n\n# Codex\n"))
                manifest = self.chezmoi("--override-data", override, "cat",
                                        str(self.home / ".apm/apm.yml")).stdout
                self.assertIn("iomz/brain-vault/Skills/Common/brain-vault#", manifest)
                self.assertNotIn("iomz/skills", manifest)
                self.chezmoi("--override-data", override, "apply", "--dry-run")

    def test_config_without_variant_defaults_to_helm(self):
        self.config.write_text('[data]\ngit_name = "Test"\ngit_email = "test@example.org"\n')
        managed = self.chezmoi("managed").stdout
        self.assertIn(".config/mise/config.toml", managed)
        self.assertNotIn("agent-sandbox-apm.sh", managed)

    def test_legacy_variant_names_keep_working_until_init_renames_them(self):
        for legacy, current, sandbox in (("workstation", "helm", False),
                                         ("claude-cloud", "agent-sandbox", True)):
            with self.subTest(legacy=legacy):
                self.config.write_text(f'[data]\nvariant = "{legacy}"\nhost = "sazanka"\n'
                                       'git_name = "Test"\ngit_email = "test@example.org"\n')
                managed = self.chezmoi("managed").stdout
                self.assertEqual("agent-sandbox-apm.sh" in managed, sandbox)
                self.assertEqual(".config/mise/config.toml" in managed, not sandbox)
                self.env.pop("CHEZMOI_VARIANT", None)
                self.chezmoi("init", "--promptDefaults")
                self.assertIn(f'variant = "{current}"', self.config.read_text())

    def test_invalid_variant_fails(self):
        self.env["CHEZMOI_VARIANT"] = "claude-cluod"
        result = self.chezmoi("init", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be helm or agent-sandbox", result.stderr)

    def stub_apm(self):
        # Stub only APM's environment, leaving chezmoi and instruction deployment real.
        # No Python package install or GitHub download is performed by this test.
        bin_dir = self.home / ".local/share/agent-sandbox/apm/bin"
        bin_dir.mkdir(parents=True)
        python = bin_dir / "python"
        python.write_text("#!/bin/sh\nexit 99\n")
        python.chmod(0o755)
        apm = bin_dir / "apm"
        apm.write_text('''#!/bin/sh
if [ "$1" = "--version" ]; then
  echo 'Agent Package Manager (APM) CLI version ''' + APM_VERSION + ''''
  exit 0
fi
printf '%s\\n' "$*" >> "$HOME/apm-calls"
test -f "$HOME/.apm/apm.yml" || exit 98
mkdir -p "$HOME/.claude/skills/test"
echo generated > "$HOME/.claude/skills/test/SKILL.md"
if [ ! -e "$HOME/.claude/settings.json" ]; then
  echo '{"hooks": {}}' > "$HOME/.claude/settings.json"
fi
''')
        apm.chmod(0o755)

    def test_isolated_apply_and_apm_trigger(self):
        self.init_cloud()
        self.stub_apm()
        # Chezmoi must preserve host configuration and unknown Claude files.
        sentinels = {
            ".gitconfig": '[commit]\n\tgpgsign = true\n[user]\n\tsigningkey = cloud-key\n',
            ".claude.json": '{"cloudOwned": true}\n',
            ".claude/launcher.json": '{"launcher": "cloud"}\n',
            ".claude/sessions/probe.json": '{"session": "cloud"}\n',
            ".claude/synced-skills/cloud/SKILL.md": "cloud-synced skill\n",
            ".claude/skills/cloud-owned/SKILL.md": "cloud-owned skill\n",
            ".claude/agents/cloud-owned.md": "cloud-owned agent\n",
            ".claude/settings.json": '{"cloudOwned": true, "hooks": {}}\n',
        }
        for name, content in sentinels.items():
            path = self.home / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        self.chezmoi("apply")
        self.chezmoi("apply")
        for name, content in sentinels.items():
            self.assertEqual((self.home / name).read_text(), content, name)
        calls = (self.home / "apm-calls").read_text().splitlines()
        self.assertEqual(calls, ["install -g --target agent-skills,claude --https"])
        self.assertTrue((self.home / ".claude/skills/test/SKILL.md").is_file())
        self.assertEqual(self.chezmoi("diff").stdout, "")
        self.assertFalse((self.home / ".config").exists())
        self.assertFalse((self.home / ".zshenv").exists())
        self.assertFalse((self.home / ".local/bin").exists())
        self.assertFalse((self.home / ".claude/AGENTS.md").exists())
        common = (SOURCE / ".chezmoitemplates/AGENTS.md").read_text().strip()
        self.assertEqual((self.home / ".claude/CLAUDE.md").read_text().strip(), common)

    def test_missing_cloud_dependency_fails_clearly(self):
        self.init_cloud()
        script = self.chezmoi("cat", str(self.home / "agent-sandbox-apm.sh")).stdout
        result = subprocess.run(["/bin/sh"], input=script,
                                env=dict(self.env, PATH=str(self.root / "empty-path")),
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("agent-sandbox requires python3 on PATH", result.stderr)

    def test_unusable_settings_fail_closed_and_retry(self):
        self.init_cloud()
        self.stub_apm()
        path = self.home / ".claude/settings.json"
        path.parent.mkdir(parents=True)
        cases = [b'{"env": {"CLOUD_SENTINEL": "keep"}, "hooks": ', b"[]",
                 b'{"hooks": null}', b'{"value": NaN}', b"\xff", "directory", "fifo"]
        # Root reads mode-000 files, so the unreadable case needs a normal user.
        if os.geteuid() != 0:
            cases.append("unreadable")
        for case in cases:
            with self.subTest(case=case):
                if isinstance(case, bytes):
                    path.write_bytes(case)
                elif case == "directory":
                    path.mkdir()
                elif case == "fifo":
                    os.mkfifo(path)
                else:
                    path.write_text('{"hooks": {}}')
                    path.chmod(0)
                result = self.chezmoi("apply", check=False, timeout=30)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("refusing APM deployment", result.stderr)
                self.assertFalse((self.home / "apm-calls").exists())
                if isinstance(case, bytes):
                    self.assertEqual(path.read_bytes(), case)
                if case == "directory":
                    path.rmdir()
                else:
                    path.unlink()
        # A failed run must not consume chezmoi's onchange trigger.
        path.write_text('{"hooks": {}}')
        self.chezmoi("apply")
        self.assertEqual(len((self.home / "apm-calls").read_text().splitlines()), 1)

    def test_redirected_claude_config_fails_closed(self):
        self.init_cloud()
        self.stub_apm()
        alternate = self.home / "cloud-config"
        alternate.mkdir()
        path = alternate / "settings.json"
        original = b'{"cloudOwned": true}'
        path.write_bytes(original)
        self.env["CLAUDE_CONFIG_DIR"] = str(alternate)
        result = self.chezmoi("apply", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("CLAUDE_CONFIG_DIR must resolve to ~/.claude", result.stderr)
        self.assertEqual(path.read_bytes(), original)
        self.assertFalse((self.home / "apm-calls").exists())
        self.env["CLAUDE_CONFIG_DIR"] = str(self.home / ".claude")
        self.chezmoi("apply")
        self.assertTrue((self.home / "apm-calls").exists())

    def test_absent_settings_bootstrap_successfully(self):
        self.init_cloud()
        self.stub_apm()
        self.assertFalse((self.home / ".claude/settings.json").exists())
        self.chezmoi("apply")
        self.assertTrue((self.home / ".claude/settings.json").is_file())
        self.assertEqual(len((self.home / "apm-calls").read_text().splitlines()), 1)

    def test_bootstrap_creates_pinned_apm_environment(self):
        self.init_cloud()
        script = self.chezmoi("cat", str(self.home / "agent-sandbox-apm.sh")).stdout
        fixtures = self.root / "fixtures"
        fixtures.mkdir()
        fake_python = fixtures / "python3"
        fake_python.write_text('''#!/bin/sh
if [ "$#" = 1 ] && [ "$1" = - ]; then
  exec "$REAL_PYTHON" -
fi
test "$1 $2" = '-m venv' || exit 97
mkdir -p "$3/bin"
cp "$FIXTURES/venv-python" "$3/bin/python"
''')
        venv_python = fixtures / "venv-python"
        venv_python.write_text('''#!/bin/sh
printf '%s\\n' "$*" >> "$HOME/pip-calls"
cp "$FIXTURES/apm" "$(dirname "$0")/apm"
''')
        fake_apm = fixtures / "apm"
        fake_apm.write_text('''#!/bin/sh
if [ "$1" = '--version' ]; then
  echo 'Agent Package Manager (APM) CLI version ''' + APM_VERSION + ''''
else
  printf '%s\\n' "$*" >> "$HOME/apm-calls"
fi
''')
        for executable in (fake_python, venv_python, fake_apm):
            executable.chmod(0o755)
        env = dict(self.env, FIXTURES=str(fixtures), REAL_PYTHON=sys.executable,
                   PATH=str(fixtures) + os.pathsep + self.env["PATH"])
        for _ in range(2):
            result = subprocess.run(["/bin/sh"], input=script, env=env,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / "pip-calls").read_text().splitlines(), [
            "-m pip install --no-input --disable-pip-version-check apm-cli==" + APM_VERSION,
        ])
        self.assertEqual((self.home / "apm-calls").read_text().splitlines(), [
            "install -g --target agent-skills,claude --https",
            "install -g --target agent-skills,claude --https",
        ])

    def release_fixtures(self):
        """Use a tiny release fixture; verified executable delegates to real chezmoi."""
        fixtures = self.root / "release-fixtures"
        fixtures.mkdir()
        binary = fixtures / "chezmoi"
        binary.write_text('''#!/bin/sh
if [ "$1" = '--version' ]; then
  echo 'chezmoi version v2.65.0, fixture'
  exit 0
fi
printf '%s|%s\\n' "$CHEZMOI_VARIANT" "$*" >> "$HOME/bootstrap-calls"
exec "$REAL_CHEZMOI" --destination "$HOME" --config "$TEST_CONFIG" \
  --persistent-state "$TEST_STATE" --cache "$TEST_CACHE" "$@"
''')
        binary.chmod(0o755)
        asset = fixtures / "asset.tar.gz"
        with tarfile.open(asset, "w:gz") as archive:
            archive.add(binary, arcname="chezmoi")
        digest = hashlib.sha256(asset.read_bytes()).hexdigest()
        checksums = fixtures / "checksums.txt"
        checksums.write_text(digest + "  chezmoi_2.65.0_linux_amd64.tar.gz\n"
                             + "0" * 64 + "  another_asset.tar.gz\n")
        uname = fixtures / "uname"
        uname.write_text('''#!/bin/sh
case "$1" in -s) echo Linux ;; -m) echo x86_64 ;; *) exit 97 ;; esac
''')
        curl = fixtures / "curl"
        curl.write_text('''#!/bin/sh
printf '%s\\n' "$2" >> "$HOME/downloads"
case "$2" in
  https://github.com/twpayne/chezmoi/releases/download/v2.65.0/chezmoi_2.65.0_linux_amd64.tar.gz)
    cp "$FIXTURES/asset.tar.gz" "$4" ;;
  https://github.com/twpayne/chezmoi/releases/download/v2.65.0/chezmoi_2.65.0_checksums.txt)
    cp "$FIXTURES/checksums.txt" "$4" ;;
  *) exit 97 ;;
esac
''')
        # macOS lacks GNU sha256sum; emulate its -c interface with real SHA-256.
        sha = fixtures / "sha256sum"
        sha.write_text(f'''#!{sys.executable}
import hashlib, pathlib, sys
assert sys.argv[1] == '-c'
for line in pathlib.Path(sys.argv[2]).read_text().splitlines():
    expected, name = line.split()
    if hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest() != expected:
        print('checksum mismatch', file=sys.stderr)
        sys.exit(1)
''')
        for executable in (uname, curl, sha):
            executable.chmod(0o755)
        env = dict(self.env, FIXTURES=str(fixtures), REAL_CHEZMOI=CHEZMOI,
                   TEST_CONFIG=str(self.config), TEST_STATE=str(self.root / "state"),
                   TEST_CACHE=str(self.root / "cache"),
                   PATH=str(fixtures) + os.pathsep + self.env["PATH"])
        return env, checksums

    def setup_bootstrap(self, env):
        return subprocess.run(["/bin/sh", str(SOURCE / "scripts/bootstrap-agent-sandbox.sh")],
                              cwd=self.project, env=env, stdin=subprocess.DEVNULL,
                              text=True, capture_output=True)

    def test_setup_bootstrap_noninteractive_and_cached(self):
        env, _ = self.release_fixtures()
        self.stub_apm()
        # Wrong cached version must be replaced, then correct pin reused.
        installed = self.home / ".local/bin/chezmoi"
        installed.parent.mkdir(parents=True)
        installed.write_text("#!/bin/sh\necho 'chezmoi version v2.64.0, stale'\n")
        installed.chmod(0o755)
        for _ in range(2):
            result = self.setup_bootstrap(env)
            self.assertEqual(result.returncode, 0, result.stderr)
        calls = (self.home / "bootstrap-calls").read_text().splitlines()
        expected = f"agent-sandbox|--source {SOURCE} init --apply --no-tty --promptDefaults"
        self.assertEqual(calls, [expected, expected])
        self.assertEqual(len((self.home / "downloads").read_text().splitlines()), 2)
        self.assertEqual((self.home / "apm-calls").read_text().splitlines(), [
            "install -g --target agent-skills,claude --https",
        ])
        self.assertIn('variant = "agent-sandbox"', self.config.read_text())
        self.assertTrue((self.home / ".claude/CLAUDE.md").is_file())
        self.assertFalse((self.home / ".claude/AGENTS.md").exists())
        self.assertEqual(self.chezmoi("diff").stdout, "")
        self.assertFalse(list(self.root.glob("chezmoi-cloud.*")))

    def test_setup_bootstrap_rejects_bad_missing_or_duplicate_checksums(self):
        env, checksums = self.release_fixtures()
        original = checksums.read_text()
        for content, error in (
                ("0" * 64 + "  chezmoi_2.65.0_linux_amd64.tar.gz\n", "checksum mismatch"),
                ("", "missing or duplicate chezmoi checksum entry"),
                (original + original, "missing or duplicate chezmoi checksum entry")):
            with self.subTest(checksums=content):
                checksums.write_text(content)
                result = self.setup_bootstrap(env)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)
                self.assertFalse((self.home / ".local/bin/chezmoi").exists())
                self.assertFalse((self.home / "bootstrap-calls").exists())
                self.assertFalse(list(self.root.glob("chezmoi-cloud.*")))

    def test_setup_bootstrap_rejects_unsupported_platform(self):
        env, checksums = self.release_fixtures()
        (checksums.parent / "uname").write_text("#!/bin/sh\necho Darwin\n")
        result = self.setup_bootstrap(env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires Linux x86_64", result.stderr)
        self.assertFalse((self.home / "downloads").exists())



if __name__ == "__main__":
    unittest.main()
