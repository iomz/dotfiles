"""Offline patch/update checks; isolated Git fixtures and fake native builds."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
PATCH = SOURCE / "dot_local/lib/opencode-patches/transparent-borders.patch"
SIDEBAR = "packages/tui/src/routes/session/sidebar.tsx"
TOOLS = "packages/tui/src/routes/session/index.tsx"
PROMPT = "packages/tui/src/component/prompt/index.tsx"
SYNTAX = "packages/theme/src/tui/syntax.ts"


@unittest.skipUnless(shutil.which("git") and shutil.which("bash"), "Git and Bash required")
class OpenCodeBordersTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="opencode-borders-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / "home"
        self.repo = self.root / "source"
        self.repo.mkdir()
        self.git = shutil.which("git")
        self.run_git("init", "-q")
        self.write(SIDEBAR, '\n' * 19 + '''    <Show when={session()}>
      <box
        backgroundColor={theme.background.raised.base}
        width={SESSION_SIDEBAR_WIDTH}
        height="100%"
        paddingTop={1}
''')
        tools = [""] * 2738
        tools[1400:1404] = [
            "                  trackOptions: {",
            "                    backgroundColor: theme.decrease(theme.background.raised.base),",
            "                    foregroundColor: theme.border.base,",
            "                  },",
        ]
        tools[2217:2220] = [
            "  const [hover, setHover] = createSignal(false)",
            '  const color = createMemo(() => local.agent.color(data.session.get(ctx.sessionID)?.agent ?? "build"))',
            "  const delivery = createMemo(() => ctx.pendingDelivery(props.message.id))",
        ]
        tools[2214:2217] = [
            "  const themes = useThemes()",
            "  const theme = useTheme()",
            "  const mode = themes.mode",
        ]
        tools[2274:2278] = [
            "        >",
            "          <text fg={theme.text.base}>{props.message.text}</text>",
            "          <Show when={skills().length}>",
            '            <box flexDirection="row" paddingTop={1} gap={1} flexWrap="wrap">',
        ]
        tools[2735:2738] = [
            "      customBorderChars={SplitBorder.customBorderChars}",
            "      borderColor={theme.background.base}",
            "      onMouseOver={() => props.onClick && setHover(true)}",
        ]
        tools[2283:2286] = [
            '                        bg: theme.hue.accent[mode() === "light" ? 300 : 200],',
            "                        fg: theme.background.raised.base,",
            "                        bold: true,",
        ]
        tools[2307:2310] = [
            '                          bg: theme.hue.accent[mode() === "light" ? 300 : 200],',
            "                          fg: theme.background.raised.base,",
            "                          bold: true,",
        ]
        self.write(TOOLS, "\n".join(tools) + "\n")
        self.write(PROMPT, "\n" * 1652 +
                   "  const promptBg = createMemo(() => theme.decrease(theme.background.raised.base))\n\n  return (\n")
        self.write(SYNTAX, "\n" * 12 + '''    rule(["extmark.file"], feedback.warning.base, { bold: true }),
    rule(["extmark.agent"], theme.categorical[0][step], { bold: true }),
    rule(["extmark.skill"], (theme.categorical[1] ?? theme.categorical[0])[step], { bold: true }),
    // V1 migration preserves its selected/inverse foreground in this action state.
    rule(["extmark.paste"], theme.text.action.primary.focused, {
      background: feedback.warning.base,
      bold: true,
    }),
''')
        self.write("packages/cli/package.json", '{"version":"2.0.26"}\n')
        self.run_git("add", ".")
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture")
        self.commit = self.run_git("rev-parse", "HEAD").stdout.strip()

    def run_git(self, *args, check=True):
        return subprocess.run([self.git, "-C", str(self.repo), *args], check=check, text=True, capture_output=True)

    def write(self, relative, text):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def executable(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        path.chmod(0o755)

    def test_patch_adds_borders_without_changing_backgrounds(self):
        before = (self.repo / SIDEBAR).read_text()
        self.run_git("apply", "--check", str(PATCH))
        self.run_git("apply", str(PATCH))
        sidebar = (self.repo / SIDEBAR).read_text()
        tools = (self.repo / TOOLS).read_text()
        self.assertIn('border={["left"]}', sidebar)
        self.assertIn("borderColor={theme.border.base}", sidebar)
        self.assertIn("borderColor={theme.border.base}", tools)
        self.assertEqual(before.count("backgroundColor={theme.background.raised.base}"),
                         sidebar.count("backgroundColor={theme.background.raised.base}"))

    def test_prompt_label_and_border_preserve_plain_text_and_queue_styling(self):
        self.run_git("apply", str(PATCH))
        tools = (self.repo / TOOLS).read_text()
        self.assertIn('local.agent.color(data.session.get(ctx.sessionID)?.agent ?? "build")', tools)
        self.assertIn('fg={delivery() ? theme.text.muted : color()} attributes={TextAttributes.BOLD}', tools)
        self.assertIn("            YOU\n", tools)
        self.assertIn("<text fg={theme.text.base}>{props.message.text}</text>", tools)

    def test_input_fill_uses_formfield_without_tinting_transcript(self):
        self.run_git("apply", str(PATCH))
        prompt = (self.repo / PROMPT).read_text()
        self.assertIn("const promptBg = createMemo(() => theme.background.formfield.base)", prompt)
        theme = json.loads((SOURCE / "dot_config/opencode/themes/cmux-transparent.json").read_text())
        self.assertEqual(theme["base"]["background"]["base"], "transparent")
        self.assertEqual(theme["base"]["background"]["raised"]["base"], "transparent")
        self.assertEqual(theme["dark"]["background"]["formfield"]["base"], "#252c35")
        self.assertEqual(theme["dark"]["scrollbar"]["base"], "#32cd99")

    def test_scrollbar_uses_its_own_color_and_badges_follow_main_text(self):
        self.run_git("apply", str(PATCH))
        tools = (self.repo / TOOLS).read_text()
        syntax = (self.repo / SYNTAX).read_text()
        self.assertIn("foregroundColor: theme.scrollbar.base", tools)
        self.assertIn('rule(["extmark.file"], theme.text.base, {', syntax)
        self.assertIn('rule(["extmark.paste"], theme.text.base, {', syntax)
        self.assertEqual(syntax.count("background: theme.background.formfield.selected"), 2)
        theme = json.loads((SOURCE / "dot_config/opencode/themes/cmux-transparent.json").read_text())
        self.assertEqual(theme["dark"]["background"]["formfield"]["$selected"], "#a63f00")
        self.assertEqual(theme["dark"]["hue"]["user"]["200"], "#ff4747")
        self.assertEqual(theme["dark"]["hue"]["secondary"]["200"], "#5394ee")
        self.assertEqual(theme["dark"]["border"]["base"], "#526071")

    def test_submitted_attachment_and_skill_tags_have_visible_text(self):
        self.run_git("apply", str(PATCH))
        tools = (self.repo / TOOLS).read_text()
        self.assertEqual(tools.count("bg: theme.background.formfield.selected"), 2)
        self.assertEqual(tools.count("fg: theme.text.base,"), 2)
        self.assertNotIn("fg: theme.background.raised.base", tools)

    def test_plan_has_explicit_cyan_without_changing_build(self):
        config = json.loads((SOURCE / "dot_config/opencode/opencode.jsonc.tmpl").read_text())
        self.assertEqual(config["agents"]["plan"], {"color": "#a0e4ee"})
        self.assertNotIn("build", config["agents"])

    def test_ctrl_p_moves_up_instead_of_opening_commands(self):
        config = json.loads((SOURCE / "dot_config/opencode/cli.json.tmpl").read_text())
        self.assertEqual(config["keybinds"]["command.palette.show"], "<leader>p")
        self.assertEqual(config["keybinds"]["input.move.up"], "up,ctrl+p")

    def setup_updater(self):
        lib = self.home / ".local/lib"
        (lib / "opencode-patches").mkdir(parents=True)
        shutil.copyfile(SOURCE / "dot_local/lib/opencode-generation.sh", lib / "opencode-generation.sh")
        self.patch = lib / "opencode-patches/transparent-borders.patch"
        shutil.copyfile(PATCH, self.patch)
        self.data = self.home / ".local/share/opencode"
        for name in ("initial", "older"):
            gen = self.data / "releases" / name
            self.executable(gen / "opencode", '#!/bin/bash\n[[ "$1" != --version ]] || echo 2.0.26\nexit 0\n')
            manifest = {"version": "2.0.26", "source_commit": self.commit, "executable": "opencode",
                        "sha256": hashlib.sha256((gen / "opencode").read_bytes()).hexdigest()}
            (gen / "manifest.json").write_text(json.dumps(manifest))
        (self.data / "active").symlink_to(self.data / "releases/initial")
        (self.data / "previous").symlink_to(self.data / "releases/older")
        self.executable(self.home / ".local/bin/opencode", '#!/bin/bash\nexec "$HOME/.local/share/opencode/active/opencode" "$@"\n')
        tools = self.root / "tools"
        self.executable(tools / "git", f'''#!/bin/bash
if [[ "$3" = fetch ]]; then exit 0; fi
if [[ "$3" = config && "$4" = --get ]]; then
  echo https://github.com/anomalyco/opencode.git
  exit 0
fi
exec "{self.git}" "$@"
''')
        self.executable(tools / "uname", '#!/bin/bash\nif [[ "$1" = -s ]]; then echo Darwin; else echo arm64; fi\n')
        self.executable(tools / "lipo", '#!/bin/bash\necho arm64\n')
        self.executable(tools / "bun", '''#!/bin/bash
if [[ "$1" = install ]]; then exit 0; fi
for arg in "$@"; do
  if [[ "$arg" = --outdir=* ]]; then out=${arg#--outdir=}; fi
done
echo build >> "$HOME/build-count"
mkdir -p "$out/cli-darwin-arm64/bin"
cat > "$out/cli-darwin-arm64/bin/opencode" <<'EOF'
#!/bin/bash
[[ "$1" != --version ]] || echo 2.0.26
exit 0
EOF
chmod +x "$out/cli-darwin-arm64/bin/opencode"
''')
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.root),
                        PATH=str(tools) + os.pathsep + os.environ["PATH"],
                        OPENCODE_UPDATE_SOURCE=str(self.repo), OPENCODE_UPDATE_ROOT=str(self.data),
                        OPENCODE_UPDATE_REF=self.commit)

    def update(self, check=True):
        result = subprocess.run(["bash", str(SOURCE / "dot_local/bin/executable_opencode-update")],
                                env=self.env, text=True, capture_output=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_patch_rebuild_noop_and_patch_revision(self):
        self.setup_updater()
        self.update()
        first = (self.data / "active").resolve()
        manifest = json.loads((first / "manifest.json").read_text())
        self.assertEqual(manifest["local_patch_sha256"], hashlib.sha256(self.patch.read_bytes()).hexdigest())
        self.assertEqual((self.data / "previous").resolve().name, "initial")
        self.assertIn("no changes made", self.update().stdout)
        self.assertEqual((self.home / "build-count").read_text().splitlines(), ["build"])
        self.patch.write_text(self.patch.read_text() + "\n")
        self.update()
        self.assertNotEqual((self.data / "active").resolve(), first)
        self.assertEqual((self.data / "previous").resolve(), first)
        self.assertEqual(len((self.home / "build-count").read_text().splitlines()), 2)

    def test_conflicting_patch_keeps_active_build(self):
        self.setup_updater()
        self.patch.write_text(self.patch.read_text().replace("onMouseOver", "renamedUpstreamHandler"))
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local UI patch no longer matches upstream", result.stderr)
        self.assertEqual((self.data / "active").resolve().name, "initial")
        self.assertFalse((self.home / "build-count").exists())
        self.assertFalse((self.data / "operation.lock").exists())

    def test_patch_only_rebuild_does_not_downgrade_source(self):
        older = self.commit
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                     "commit", "--allow-empty", "-qm", "newer fixture")
        self.commit = self.run_git("rev-parse", "HEAD").stdout.strip()
        self.setup_updater()
        self.env["OPENCODE_UPDATE_REF"] = older
        self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], self.commit)


if __name__ == "__main__":
    unittest.main()
