"""Run the skills-pull recipe against local repositories."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("just") and shutil.which("git"), "just and git required")
class SkillsPullTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="skills-pull-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.env = dict(os.environ, HOME=str(root / "home"), GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_AUTHOR_NAME="T", GIT_AUTHOR_EMAIL="t@example.org",
                        GIT_COMMITTER_NAME="T", GIT_COMMITTER_EMAIL="t@example.org")
        self.upstream = root / "upstream"
        self.git("init", "-q", "-b", "main", str(self.upstream))
        self.commit("one")
        self.clone = root / "home/.local/share/agent-skills"
        self.git("clone", "-q", str(self.upstream), str(self.clone))

    def git(self, *args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd, env=self.env, text=True,
                              capture_output=True, check=True).stdout

    def commit(self, text):
        (self.upstream / "SKILL.md").write_text(text + "\n")
        self.git("add", "SKILL.md", cwd=self.upstream)
        self.git("commit", "-q", "-m", text, cwd=self.upstream)

    def pull(self):
        return subprocess.run(["just", "-f", str(SOURCE / "justfile"), "skills-pull"],
                              env=self.env, text=True, capture_output=True)

    def test_fast_forwards_a_clean_clone(self):
        self.commit("two")
        self.assertEqual(self.pull().returncode, 0)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "two\n")

    def test_stops_on_local_changes(self):
        self.commit("two")
        (self.clone / "SKILL.md").write_text("edited\n")
        result = self.pull()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local changes", result.stderr)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "edited\n")

    def test_stops_on_another_branch(self):
        self.git("switch", "-q", "-c", "draft", cwd=self.clone)
        result = self.pull()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not main", result.stderr)

    def test_refuses_to_merge_local_commits(self):
        self.commit("two")
        (self.clone / "SKILL.md").write_text("local\n")
        self.git("commit", "-q", "-am", "local", cwd=self.clone)
        before = self.git("rev-parse", "HEAD", cwd=self.clone)
        self.assertNotEqual(self.pull().returncode, 0)
        self.assertEqual(self.git("rev-parse", "HEAD", cwd=self.clone), before)


if __name__ == "__main__":
    unittest.main()
