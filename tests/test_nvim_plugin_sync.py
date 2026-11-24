"""The Neovim plugin sync script must change whenever the nvim config changes."""

import re
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome

EXTRA = '[data.hosts.devbox]\ngroups = ["stem"]\n'
SCRIPT = "run_onchange_after_nvim-plugin-sync.sh.tmpl"


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class NvimPluginSyncTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.h.copy(*(f".chezmoitemplates/{name}"
                      for name in ("is-stem", "tool-selected", "brew-path", "variant")))
        nvim = self.h.source / "dot_config/nvim"
        (nvim / "lua").mkdir(parents=True)
        (nvim / "init.lua").write_text("require('config')\n")
        (nvim / "lua/config.lua").write_text("return {}\n")
        self.h.configure("devbox", extra=EXTRA)

    def render(self):
        return self.h.render((SOURCE / SCRIPT).read_text())

    def trigger(self):
        return re.search(r"chezmoi trigger: ([0-9a-f]{64})", self.render()).group(1)

    def test_trigger_follows_content_and_names(self):
        before = self.trigger()
        self.assertEqual(self.trigger(), before)
        config = self.h.source / "dot_config/nvim/lua/config.lua"
        config.write_text("return { changed = true }\n")
        changed = self.trigger()
        self.assertNotEqual(changed, before)
        config.rename(config.with_name("renamed.lua"))
        self.assertNotEqual(self.trigger(), changed)

    def test_renders_nothing_off_stem_or_in_a_sandbox(self):
        for host, variant in (("tinybox", "helm"), ("devbox", "agent-sandbox")):
            with self.subTest(host=host, variant=variant):
                self.h.configure(host, variant, extra=EXTRA)
                self.assertEqual(self.render().strip(), "")


if __name__ == "__main__":
    unittest.main()
