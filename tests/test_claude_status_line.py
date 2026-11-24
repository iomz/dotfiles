import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = "claude-status-line.sh"
WRAPPER = SOURCE / "dot_local/bin/executable_claude-code-status-line"


@unittest.skipUnless(shutil.which("chezmoi") and shutil.which("jq"), "chezmoi and jq required")
class ClaudeStatusLineTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="chezmoi-claude-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def render(self, host, variant="helm"):
        config = self.root / "config.toml"
        config.write_text(f'[data]\nvariant = "{variant}"\nhost = "{host}"\n'
                          'git_name = "Test"\ngit_email = "test@example.org"\n')
        return subprocess.run(
            ["chezmoi", "--source", str(SOURCE), "--destination", str(self.home),
             "--config", str(config), "--persistent-state", str(self.root / "state"),
             "--cache", str(self.root / "cache"), "--no-tty", "cat", str(self.home / SCRIPT)],
            env=dict(os.environ, HOME=str(self.home)), stdin=subprocess.DEVNULL,
            text=True, capture_output=True, check=True).stdout

    def run_script(self):
        script = self.root / SCRIPT
        script.write_text(self.render("sazanka"))
        subprocess.run(["sh", str(script)], env=dict(os.environ, HOME=str(self.home)),
                       text=True, capture_output=True, check=True)
        return json.loads((self.home / ".claude/settings.json").read_text())

    def test_only_stem_helm_hosts_get_the_script(self):
        self.assertTrue(self.render("sazanka").strip())
        self.assertEqual(self.render("tinybox").strip(), "")
        # An agent sandbox ignores everything but its instructions.
        with self.assertRaises(subprocess.CalledProcessError):
            self.render("sazanka", "agent-sandbox")

    def test_sets_only_the_status_line_keys(self):
        settings = self.home / ".claude/settings.json"
        settings.parent.mkdir()
        settings.write_text(json.dumps({
            "model": "opus",
            "hooks": {"Stop": []},
            "statusLine": {"type": "command", "command": "old", "padding": 0},
        }))
        settings.chmod(0o600)
        data = self.run_script()
        self.assertEqual(data["model"], "opus")
        self.assertEqual(data["hooks"], {"Stop": []})
        self.assertEqual(data["statusLine"], {
            "type": "command",
            "command": f"{self.home}/.local/bin/claude-code-status-line",
            "padding": 0,
        })
        self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(settings.parent.iterdir()), [settings])

    def test_creates_settings_when_missing(self):
        self.assertEqual(self.run_script()["statusLine"]["type"], "command")


class WrapperDefaultsTest(unittest.TestCase):
    def run_wrapper(self, **env):
        with tempfile.TemporaryDirectory(prefix="claude-wrapper-") as home:
            fake = Path(home) / ".local/bin/claude-code-status-line.py"
            fake.parent.mkdir(parents=True)
            fake.write_text('#!/bin/sh\nprintf "%s|%s|%s" "$SL_SEGMENTS" "$SL_SEGMENT_GAP" '
                            '"$SL_SHOW_STATUSLINE_UPDATE"\n')
            fake.chmod(0o755)
            clean = {k: v for k, v in os.environ.items() if not k.startswith("SL_")}
            return subprocess.run(["bash", str(WRAPPER)], input="{}", text=True,
                                  capture_output=True, check=True,
                                  env=dict(clean, HOME=home, **env)).stdout

    def test_wrapper_holds_the_layout(self):
        segments, gap, update = self.run_wrapper().split("|")
        self.assertTrue(segments.startswith("update model:colon=0:effort=full percentage "))
        self.assertEqual((gap, update), ("  ", "0"))

    def test_environment_still_wins(self):
        self.assertEqual(self.run_wrapper(SL_SEGMENTS="model", SL_SEGMENT_GAP=" ",
                                          SL_SHOW_STATUSLINE_UPDATE="1"), "model| |1")


if __name__ == "__main__":
    unittest.main()
