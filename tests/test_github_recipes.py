"""Run the GitHub-backed just recipes against stubs and local repositories."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SKILLS_URL = "https://github.com/iomz/skills.git"


@unittest.skipUnless(shutil.which("just") and shutil.which("git"), "just and git required")
class GitHubRecipeTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="github-recipes-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.upstream = root / "upstream"
        # Send the real URL to a local repository, so nothing touches the network.
        gitconfig = root / "gitconfig"
        gitconfig.write_text(f'[url "{self.upstream}"]\n\tinsteadOf = {SKILLS_URL}\n')
        self.bin = root / "bin"
        self.bin.mkdir()
        self.calls = root / "calls"
        self.calls.write_text("")
        self.stub("gh", 'case "$1 $2" in\n'
                        '  "auth status") exit "${GH_STATUS:-0}" ;;\n'
                        '  "auth token") echo test-token ;;\n'
                        'esac')
        self.stub("apm", 'echo "apm $* token=$GITHUB_APM_PAT" >> "$CALLS"')
        self.env = dict(os.environ, HOME=str(root / "home"), GIT_CONFIG_GLOBAL=str(gitconfig),
                        PATH=f"{self.bin}{os.pathsep}{os.environ['PATH']}", CALLS=str(self.calls),
                        GIT_AUTHOR_NAME="T", GIT_AUTHOR_EMAIL="t@example.org",
                        GIT_COMMITTER_NAME="T", GIT_COMMITTER_EMAIL="t@example.org")
        self.git("init", "-q", "-b", "main", str(self.upstream))
        self.commit("one")
        self.clone = root / "home/.local/share/agent-skills"
        self.git("clone", "-q", str(self.upstream), str(self.clone))

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/sh\n{body}\n")
        path.chmod(0o755)

    def git(self, *args, cwd=None):
        return subprocess.run(["git", *args], cwd=cwd, env=self.env, text=True,
                              capture_output=True, check=True).stdout

    def commit(self, text):
        (self.upstream / "SKILL.md").write_text(text + "\n")
        self.git("add", "SKILL.md", cwd=self.upstream)
        self.git("commit", "-q", "-m", text, cwd=self.upstream)

    def just(self, recipe, **env):
        return subprocess.run(["just", "-f", str(SOURCE / "justfile"), recipe],
                              env=dict(self.env, **env), text=True, capture_output=True)

    def test_clones_over_https_when_missing(self):
        shutil.rmtree(self.clone)
        self.assertEqual(self.just("skills-pull").returncode, 0)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "one\n")
        self.assertEqual(self.git("config", "--get", "remote.origin.url", cwd=self.clone).strip(), SKILLS_URL)

    def test_moves_an_ssh_clone_to_https(self):
        self.git("remote", "set-url", "origin", "git@github.com:iomz/skills.git", cwd=self.clone)
        self.commit("two")
        self.assertEqual(self.just("skills-pull").returncode, 0)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "two\n")
        self.assertEqual(self.git("config", "--get", "remote.origin.url", cwd=self.clone).strip(), SKILLS_URL)

    def test_fast_forwards_a_clean_clone(self):
        self.commit("two")
        self.assertEqual(self.just("skills-pull").returncode, 0)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "two\n")

    def test_stops_on_local_changes(self):
        self.commit("two")
        (self.clone / "SKILL.md").write_text("edited\n")
        result = self.just("skills-pull")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local changes", result.stderr)
        self.assertEqual((self.clone / "SKILL.md").read_text(), "edited\n")

    def test_stops_on_another_branch(self):
        self.git("switch", "-q", "-c", "draft", cwd=self.clone)
        result = self.just("skills-pull")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not main", result.stderr)

    def test_refuses_to_merge_local_commits(self):
        self.commit("two")
        (self.clone / "SKILL.md").write_text("local\n")
        self.git("commit", "-q", "-am", "local", cwd=self.clone)
        before = self.git("rev-parse", "HEAD", cwd=self.clone)
        self.assertNotEqual(self.just("skills-pull").returncode, 0)
        self.assertEqual(self.git("rev-parse", "HEAD", cwd=self.clone), before)

    def test_apm_install_passes_the_gh_token(self):
        self.assertEqual(self.just("apm-install").returncode, 0)
        self.assertEqual(self.calls.read_text(), "apm install -g token=test-token\n")

    def test_recipes_stop_without_a_gh_login(self):
        shutil.rmtree(self.clone)
        for recipe in ("skills-pull", "apm-install"):
            with self.subTest(recipe=recipe):
                result = self.just(recipe, GH_STATUS="1")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("gh auth login", result.stderr)
        self.assertFalse(self.clone.exists())
        self.assertEqual(self.calls.read_text(), "")


if __name__ == "__main__":
    unittest.main()
