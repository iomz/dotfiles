"""The status line script edits only statusLine; the wrapper's defaults yield to SL_*."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome

SCRIPT = "claude-status-line.sh"
WRAPPER = SOURCE / "dot_local/bin/executable_claude-code-status-line"


@unittest.skipUnless(CHEZMOI and shutil.which("jq"), "chezmoi and jq required")
class ClaudeStatusLineTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.home = self.h.home
        self.settings = self.home / ".claude/settings.json"

    def render(self, host, variant="helm"):
        self.h.configure(host, variant)
        return self.h.run("cat", str(self.home / SCRIPT)).stdout

    def run_script(self):
        script = self.h.root / SCRIPT
        script.write_text(self.render("sazanka"))
        subprocess.run(["sh", str(script)], env=self.h.env, text=True,
                       capture_output=True, check=True)
        return json.loads(self.settings.read_text())

    def test_only_stem_helm_hosts_with_jq_get_the_script(self):
        self.assertTrue(self.render("sazanka").strip())
        self.assertEqual(self.render("tinybox").strip(), "")
        # An agent sandbox ignores everything but its instructions.
        with self.assertRaises(subprocess.CalledProcessError):
            self.render("sazanka", "agent-sandbox")
        # Without jq the script renders empty, so a later apply runs it.
        tools = self.h.root / "tools"
        tools.mkdir()
        self.h.env["PATH"] = str(tools)
        self.assertEqual(self.render("sazanka").strip(), "")

    def test_sets_only_the_status_line_keys_and_keeps_the_mode(self):
        self.settings.parent.mkdir()
        self.settings.write_text(json.dumps({
            "model": "opus",
            "statusLine": {"type": "command", "command": "old", "padding": 0},
        }))
        self.settings.chmod(0o600)
        data = self.run_script()
        self.assertEqual(data["model"], "opus")
        self.assertEqual(data["statusLine"], {
            "type": "command",
            "command": f"{self.home}/.local/bin/claude-code-status-line",
            "padding": 0,
        })
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.settings.parent.iterdir()), [self.settings])

    def test_creates_missing_settings_privately(self):
        self.assertEqual(self.run_script()["statusLine"]["type"], "command")
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o600)

    def test_keeps_a_linked_settings_file_linked(self):
        target = self.h.root / "dotfiles/settings.json"
        target.parent.mkdir()
        target.write_text('{"model": "opus"}')
        self.settings.parent.mkdir()
        self.settings.symlink_to(target)
        self.assertEqual(self.run_script()["model"], "opus")
        self.assertTrue(self.settings.is_symlink())
        self.assertEqual(json.loads(target.read_text())["statusLine"]["command"],
                         f"{self.home}/.local/bin/claude-code-status-line")
        self.assertEqual(sorted(p.name for p in target.parent.iterdir()), ["settings.json"])


class WrapperDefaultsTest(unittest.TestCase):
    def test_environment_overrides_the_defaults(self):
        with tempfile.TemporaryDirectory(prefix="claude-wrapper-") as home:
            fake = Path(home) / ".local/bin/claude-code-status-line.py"
            fake.parent.mkdir(parents=True)
            fake.write_text('#!/bin/sh\nprintf "%s|%s|%s" "$SL_SEGMENTS" "$SL_SEGMENT_GAP" '
                            '"$SL_SHOW_STATUSLINE_UPDATE"\n')
            fake.chmod(0o755)
            env = {k: v for k, v in os.environ.items() if not k.startswith("SL_")}
            env.update(HOME=home, SL_SEGMENTS="model", SL_SEGMENT_GAP=" ",
                       SL_SHOW_STATUSLINE_UPDATE="1")
            result = subprocess.run(["bash", str(WRAPPER)], input="{}", text=True,
                                    capture_output=True, check=True, env=env)
        self.assertEqual(result.stdout, "model| |1")


if __name__ == "__main__":
    unittest.main()
