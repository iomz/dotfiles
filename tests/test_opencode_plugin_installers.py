"""The OpenCode CLI plugin installers run only while dependencies are missing."""

import os
import shutil
import tomllib
import unittest

from chezmoi_home import CHEZMOI, SOURCE, ChezmoiHome, stub

PLUGINS = {"codex-quota-sidebar": "zod", "dir-tree-bottom": "opencode-dir-tree-tui"}
NODE = tomllib.loads((SOURCE / ".chezmoidata/tools.toml").read_text())["tools"]["node"]["mise"]


@unittest.skipUnless(CHEZMOI, "chezmoi required")
class PluginInstallerTest(unittest.TestCase):
    def setUp(self):
        self.h = ChezmoiHome(self)
        self.h.configure("oxalis")
        self.h.copy(".chezmoidata/tools.toml", ".chezmoitemplates/tool-selected",
                    ".chezmoitemplates/brew-path")
        for name in PLUGINS:
            self.h.copy(f"run_after_install-opencode-{name}.sh.tmpl",
                        f"dot_config/opencode/cli-plugins/{name}/package.json",
                        f"dot_config/opencode/cli-plugins/{name}/package-lock.json")
        tools = self.tools = self.h.root / "tools"
        tools.mkdir()
        # npm ci, reached only through `mise exec node@<pinned> -- npm`.
        stub(tools, "mise-npm", f'''set -eu
test "$1" = ci && test "$2" = --prefix
dir=$3
case "$dir" in
    */codex-quota-sidebar) dependency=zod ;;
    */dir-tree-bottom) dependency=opencode-dir-tree-tui ;;
    *) exit 98 ;;
esac
if [ -f "$HOME/fail-npm" ]; then exit 42; fi
mkdir -p "$dir/node_modules/$dependency"
printf '{{}}\\n' > "$dir/node_modules/$dependency/package.json"
printf '%s\\n' "$dir" >> "$HOME/npm-calls"''')
        # An inherited npm stands for a broken asdf shim.
        stub(tools, "npm", 'echo "unexpected asdf shim" >&2; exit 99')
        stub(tools, "mise", f'''set -eu
test "$2" = node@{NODE}
case "$1" in
    install) exit 0 ;;
    exec) shift 4; exec "$(dirname "$0")/mise-npm" "$@" ;;
    *) exit 98 ;;
esac''')
        self.h.env["PATH"] = str(tools) + os.pathsep + self.h.env["PATH"]

    def npm_calls(self):
        return len((self.h.home / "npm-calls").read_text().splitlines())

    def test_installs_once_and_again_after_loss_or_lock_change(self):
        self.h.run("apply")
        self.assertEqual(self.npm_calls(), 2)
        # Current dependencies render the installers empty: no run, no status entry.
        self.h.run("apply")
        self.assertEqual(self.npm_calls(), 2)
        self.assertEqual(self.h.run("status").stdout, "")

        quota = self.h.home / ".config/opencode/cli-plugins/codex-quota-sidebar"
        shutil.rmtree(quota / "node_modules")
        (self.h.home / "fail-npm").write_text("")
        self.assertNotEqual(self.h.run("apply", check=False).returncode, 0)
        self.assertFalse((quota / "node_modules/.chezmoi-lock-sha256").exists())
        (self.h.home / "fail-npm").unlink()
        self.h.run("apply")
        self.assertTrue((quota / "node_modules/zod/package.json").is_file())
        self.assertEqual(self.npm_calls(), 3)

        lock = self.h.source / "dot_config/opencode/cli-plugins/codex-quota-sidebar/package-lock.json"
        lock.write_text(lock.read_text() + "\n")
        self.h.run("apply")
        self.assertEqual(self.npm_calls(), 4)

    def test_finds_mise_beside_brew_outside_path(self):
        # A fresh macOS host: chezmoi inherits a PATH without Homebrew.
        stub(self.tools, "brew")
        self.h.configure("oxalis", extra=f'brew_paths = ["/nonexistent/brew", "{self.tools / "brew"}"]\n')
        self.h.env["PATH"] = "/usr/bin:/bin"
        self.h.run("apply")
        self.assertEqual(self.npm_calls(), 2)


if __name__ == "__main__":
    unittest.main()
