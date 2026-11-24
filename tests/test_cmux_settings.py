"""cmux settings: only allowlisted appearance keys, and macOS only."""

import json
from pathlib import Path
import re
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / "run_onchange_after_cmux-appearance.sh.tmpl"
ALLOWED = {
    "appearanceMode", "appIconMode", "sidebarAppearanceDefaultsVersion", "sidebarPreset",
    "sidebarMaterial", "sidebarBlendMode", "sidebarState", "sidebarTintHex", "sidebarTintOpacity",
    "sidebarBlurOpacity", "sidebarCornerRadius", "rightSidebar.mode", "confirmQuit",
    "warnBeforeQuitShortcut",
}


class CmuxSettingsTest(unittest.TestCase):
    def test_script_writes_only_allowlisted_keys(self):
        text = SCRIPT.read_text()
        keys = re.findall(r'^defaults write "\$domain" (\S+) -', text, re.M)
        self.assertEqual(set(keys), ALLOWED)
        self.assertEqual(len(keys), len(ALLOWED))
        self.assertNotRegex(text, r"defaults (import|export)")

    def test_shortcuts_file_is_private_json_without_account_data(self):
        path = SOURCE / "dot_config/cmux/private_cmux.json"
        data = json.loads(path.read_text())
        self.assertEqual(set(data) - {"$schema", "schemaVersion"}, {"shortcuts"})


if __name__ == "__main__":
    unittest.main()
