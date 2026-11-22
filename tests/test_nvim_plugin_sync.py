"""The Neovim plugin sync script must change whenever the nvim config changes."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
DATA = '''[data]
variant = "{variant}"
host = "{host}"
[data.hosts.devbox]
groups = ["dev"]
'''
SCRIPT = "run_onchange_after_nvim-plugin-sync.sh.tmpl"


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi required")
class NvimPluginSyncTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="chezmoi-nvim-sync-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.source = root / "source"
        (self.source / "dot_config/nvim/lua").mkdir(parents=True)
        (self.source / ".chezmoitemplates").mkdir()
        for name in ("is-dev", "tool-selected"):
            shutil.copyfile(SOURCE / ".chezmoitemplates" / name,
                            self.source / ".chezmoitemplates" / name)
        shutil.copyfile(SOURCE / SCRIPT, self.source / SCRIPT)
        (self.source / "dot_config/nvim/init.lua").write_text("require('config')\n")
        (self.source / "dot_config/nvim/lua/config.lua").write_text("return {}\n")
        self.config = root / "config.toml"
        self.config.write_text(DATA.format(variant="workstation", host="devbox"))
        (root / "home").mkdir()  # glob runs relative to the destination
        self.command = ["chezmoi", "--source", str(self.source), "--destination",
                        str(root / "home"), "--config", str(root / "config.toml"),
                        "--persistent-state", str(root / "state")]
        self.env = dict(os.environ, HOME=str(root))

    def render(self, *extra):
        script = (self.source / SCRIPT).read_text()
        result = subprocess.run(self.command + [*extra, "execute-template", script],
                                env=self.env, text=True, capture_output=True, check=True)
        return result.stdout

    def trigger(self):
        return re.search(r"chezmoi trigger: ([0-9a-f]{64})", self.render()).group(1)

    def test_trigger_follows_content_and_names(self):
        before = self.trigger()
        self.assertEqual(self.trigger(), before)
        config = self.source / "dot_config/nvim/lua/config.lua"
        config.write_text("return { changed = true }\n")
        changed = self.trigger()
        self.assertNotEqual(changed, before)
        config.rename(config.with_name("renamed.lua"))
        self.assertNotEqual(self.trigger(), changed)

    def test_cloud_variant_renders_nothing(self):
        # Config data rather than --override-data, which needs chezmoi >= 2.66.
        self.config.write_text(DATA.format(variant="claude-cloud", host="devbox"))
        self.assertEqual(self.render().strip(), "")

    def test_non_dev_host_renders_nothing(self):
        self.config.write_text(DATA.format(variant="workstation", host="tinybox"))
        self.assertEqual(self.render().strip(), "")


if __name__ == "__main__":
    unittest.main()
