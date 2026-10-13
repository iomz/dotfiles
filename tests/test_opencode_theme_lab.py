"""Theme-lab event tests without a browser or network access."""

from html.parser import HTMLParser
from pathlib import Path
import shutil
import subprocess
import unittest


LAB = Path(__file__).resolve().parents[1] / "scripts/opencode-theme-lab.html"


class LabParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.script = []
        self.inputs = {}

    def handle_starttag(self, tag, attrs):
        if tag == "script":
            self.active = True
        if tag == "input":
            attributes = dict(attrs)
            self.inputs[attributes["id"]] = attributes

    def handle_endtag(self, tag):
        if tag == "script":
            self.active = False

    def handle_data(self, data):
        if self.active:
            self.script.append(data)


class ThemeLabTest(unittest.TestCase):
    def setUp(self):
        self.parser = LabParser()
        self.parser.feed(LAB.read_text())

    def test_attachment_background_has_no_native_popup(self):
        self.assertEqual(self.parser.inputs["badgeBg"]["type"], "text")
        for channel in ("badgeRed", "badgeGreen", "badgeBlue"):
            self.assertEqual(self.parser.inputs[channel]["type"], "range")

    @unittest.skipUnless(shutil.which("node"), "Node required")
    def test_palette_link_rgb_controls_and_invalid_hex(self):
        harness = r'''
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const elements = {};
const document = { getElementById(id) {
  return elements[id] ??= {
    value: id === 'preset' ? 'personal' : '', checked: false,
    style: { setProperty() {} }, listeners: {},
    addEventListener(event, callback) { this.listeners[event] = callback; }
  };
} };
vm.runInNewContext(fs.readFileSync(0, 'utf8'), { document });
const choices = () => JSON.parse(elements.output.value);
const change = (id, value, event = 'input') => {
  elements[id].value = value;
  elements[id].listeners[event]({ target: elements[id] });
};
assert.equal(choices().colors.you, '#ff4747');
assert.equal(choices().colors.secondary, '#5394ee');
assert.equal(choices().colors.scrollbar, '#32cd99');
assert.equal(choices().colors.text, '#e6edf3');
assert.equal(choices().colors.sidebarHeading, '#5394ee');
assert.equal(choices().colors.quota, '#32cd99');
change('sidebarHeading', '#a0e4ee');
assert.equal(choices().colors.sidebarHeading, '#a0e4ee');
assert.equal(choices().colors.secondary, '#5394ee');
assert.equal(choices().colors.badgeFg, choices().colors.text);
assert.equal(elements.badgeFg.disabled, true);
change('text', '#ffffff');
assert.equal(choices().colors.badgeFg, '#ffffff');
assert.equal(choices().badgeFgMatchesText, true);
change('badgeGreen', '128');
assert.equal(choices().colors.badgeBg, '#a68000');
assert.equal(elements.badgeBg.value, '#a68000');
change('badgeBg', '#123456');
assert.equal(choices().colors.badgeBg, '#123456');
assert.equal(elements.badgeRed.value, 18);
assert.equal(elements.badgeGreen.value, 52);
assert.equal(elements.badgeBlue.value, 86);
change('badgeBg', '#nope');
assert.equal(choices().colors.badgeBg, '#123456');
elements.linkBadgeText.checked = false;
elements.linkBadgeText.listeners.change();
assert.equal(elements.badgeFg.disabled, false);
change('badgeFg', '#112233');
change('text', '#aabbcc');
assert.equal(choices().colors.badgeFg, '#112233');
change('preset', 'amber', 'change');
assert.equal(choices().colors.you, '#f5c17c');
assert.equal(choices().badgeFgMatchesText, false);
change('preset', 'personal', 'change');
assert.equal(choices().badgeFgMatchesText, true);
assert.equal(choices().colors.badgeBg, '#a63f00');
assert.match(elements.ratios.textContent, /passes 4.5:1/);
console.log('Palette, badge linking, RGB sliders, and hex validation pass');
'''
        result = subprocess.run(["node", "-e", harness], input="".join(self.parser.script),
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
