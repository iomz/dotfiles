"""Wake script checks with an isolated state directory and a fake opencode CLI."""

import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "dot_local/bin/executable_opencode-codex-resume-wake"


class CodexResumeWakeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="codex-resume-wake-")
        self.root = Path(self.temp.name)
        self.wake = self.root / "state/opencode/codex-resume-wake"
        self.wake.mkdir(parents=True)
        self.project = self.root / "my project"
        self.project.mkdir()
        tools = self.root / "tools"
        tools.mkdir()
        self.calls = self.root / "calls"
        fake = tools / "opencode"
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$CALLS"\n')
        fake.chmod(0o755)
        self.env = {
            "HOME": str(self.root),
            "XDG_STATE_HOME": str(self.root / "state"),
            "PATH": f"{tools}:/usr/bin:/bin",
            "CALLS": str(self.calls),
        }

    def tearDown(self):
        self.temp.cleanup()

    def put(self, name, due, directory):
        (self.wake / name).write_text(f"{due}\t{directory}\n")

    def run_script(self):
        subprocess.run(["sh", str(SCRIPT)], env=self.env, check=True)
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_due_location_is_booted_with_encoded_directory(self):
        now = int(time.time())
        self.put("due.tsv", now - 5, self.project)
        self.put("later.tsv", now + 3600, self.project)
        calls = self.run_script()
        self.assertEqual(len(calls), 1)
        encoded = "".join(f"%{byte:02x}" for byte in str(self.project).encode())
        self.assertIn(f"/api/rpc/personal.codex-resume/status?location%5Bdirectory%5D={encoded}", calls[0])
        # Files belong to the plugin; the waker only removes stale ones.
        self.assertTrue((self.wake / "due.tsv").exists())
        self.assertTrue((self.wake / "later.tsv").exists())

    def test_stale_invalid_and_missing_locations_are_removed(self):
        now = int(time.time())
        self.put("stale.tsv", now - 8 * 86400, self.project)
        self.put("gone.tsv", now - 5, self.root / "missing")
        self.put("invalid.tsv", "soon", self.project)
        self.assertEqual(self.run_script(), [])
        self.assertEqual(list(self.wake.iterdir()), [])

    def test_missing_state_directory_is_a_no_op(self):
        self.env["XDG_STATE_HOME"] = str(self.root / "absent")
        self.assertEqual(self.run_script(), [])


if __name__ == "__main__":
    unittest.main()
