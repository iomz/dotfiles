"""Apply the real source as a stem and as a leaf host into throwaway homes."""

import os
import re
import subprocess
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome

MISE_FILES = (".config/mise/config.toml", ".config/zsh/rc.d/04-mise.zsh",
              ".config/zsh/rc.d/00-homebrew-guard.zsh")
DEV_SHELL_FILES = (".config/zsh/rc.d/02-plugin-manager.zsh", ".config/zsh/rc.d/05-zeno.zsh")
MISE_SCRIPTS = ("mise-install.sh", "install-opencode-codex-quota-sidebar.sh",
                "install-opencode-dir-tree-bottom.sh")
SKILLS = sorted(p.name.removeprefix("symlink_").removesuffix(".tmpl")
                for p in (SOURCE / "private_dot_claude/skills").iterdir())
GUARD = SOURCE / "run_before_20-guard-agent-skill-links.sh.tmpl"


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class HostProfileTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.home = self.h.home

    def chezmoi(self, host, *args):
        self.h.configure(host)
        return self.h.run(*args).stdout

    def apply(self, host):
        # Files only: scripts install packages.
        self.chezmoi(host, "apply", "--force", "--exclude", "scripts")

    def test_stem_gets_mise_neovim_and_plugins_and_leaving_stem_removes_them(self):
        self.apply("sazanka")
        for name in MISE_FILES + DEV_SHELL_FILES + (".config/nvim/init.lua",):
            self.assertTrue((self.home / name).is_file(), name)
        for name in MISE_SCRIPTS:
            self.assertTrue(self.chezmoi("sazanka", "cat", str(self.home / name)).strip(), name)
        self.apply("tinybox")
        for name in MISE_FILES + DEV_SHELL_FILES:
            self.assertFalse((self.home / name).exists(), name)
        for name in MISE_SCRIPTS:
            self.assertEqual(self.chezmoi("tinybox", "cat", str(self.home / name)).strip(), "", name)
        self.assertNotIn(".config/nvim", self.chezmoi("tinybox", "managed"))

    def test_leaf_prompt_uses_the_starship_host_color(self):
        self.apply("tinybox")
        starship = (self.home / ".config/starship.toml").read_text()
        style = (self.home / ".config/zsh/rc.d/07-style.zsh").read_text()
        color = re.search(r'\[hostname\]\n.*?\nstyle = "bold fg:([^"]+)"', starship, re.S).group(1)
        prompt = re.search(r"%B%F\{red\}%n%f%b@%B%F\{([^}]+)\}%m", style).group(1)
        self.assertEqual(prompt, "12" if color == "bright-blue" else color)
        self.assertNotIn("<%", style)

    def test_named_hosts_get_their_own_prompt_colors(self):
        for host, color in (("oxalis", "#26b8ec"), ("helianthus", "#e05cb0")):
            self.apply(host)
            starship = (self.home / ".config/starship.toml").read_text()
            style = (self.home / ".config/zsh/rc.d/07-style.zsh").read_text()
            self.assertIn(f'style = "bold fg:{color}"', starship, host)
            self.assertIn(f"@%B%F{{{color}}}%m", style, host)

    def test_stem_links_personal_skills_into_the_clone(self):
        self.apply("sazanka")
        clone = self.home / ".local/share/agent-skills/skills"
        links = sorted(p.name for p in (self.home / ".claude/skills").iterdir())
        self.assertEqual(links, SKILLS)
        for name in SKILLS:
            self.assertEqual(os.readlink(self.home / ".claude/skills" / name), str(clone / name))
        self.assertIsNone(self.run_guard("sazanka"), "existing links pass the guard")
        self.assertNotIn(".claude/skills", self.chezmoi("tinybox", "managed"))

    def run_guard(self, host):
        script = self.chezmoi(host, "execute-template", GUARD.read_text())
        if not script.strip():
            return None
        return subprocess.run(["sh", "-c", script], text=True, capture_output=True)

    def test_guard_stops_before_a_link_replaces_a_directory(self):
        self.assertIsNone(self.run_guard("sazanka"))
        copy = self.home / ".claude/skills" / SKILLS[0]
        copy.mkdir(parents=True)
        (copy / "SKILL.md").write_text("APM copy\n")
        result = self.run_guard("sazanka")
        self.assertEqual(result.returncode, 1)
        self.assertIn(f"~/.claude/skills/{SKILLS[0]}", result.stderr)
        self.assertIn("apm install -g", result.stderr)
        self.assertIsNone(self.run_guard("tinybox"), "leaf hosts get no links")

    def test_guard_warns_about_copies_that_shadow_links_in_opencode(self):
        (self.home / ".agents/skills" / SKILLS[0]).mkdir(parents=True)
        result = self.run_guard("sazanka")
        self.assertEqual(result.returncode, 0)
        self.assertIn(f"~/.agents/skills/{SKILLS[0]}", result.stderr)
        self.assertNotIn("nothing was applied", result.stderr)

    def test_existing_profile_is_left_alone(self):
        profile = self.home / ".profile"
        profile.write_text("# host-local\n")
        self.apply("tinybox")
        self.assertEqual(profile.read_text(), "# host-local\n")

    def test_zsh_directories_are_exact(self):
        self.apply("tinybox")
        leftovers = [self.home / ".config/zsh/rc.d/99-old.zsh",
                     self.home / ".config/zsh/functions/old"]
        for path in leftovers:
            path.write_text("# unmanaged\n")
        self.apply("tinybox")
        for path in leftovers:
            self.assertFalse(path.exists(), path)


if __name__ == "__main__":
    unittest.main()
