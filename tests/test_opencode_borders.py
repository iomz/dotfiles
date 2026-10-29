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
        self.write("package.json", '{"packageManager":"bun@1.4.4"}\n')
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

    def test_prompt_navigation_and_kill_line_keybinds(self):
        config = json.loads((SOURCE / "dot_config/opencode/cli.json.tmpl").read_text())
        self.assertEqual(config["keybinds"]["input.move.down"], "down,ctrl+n")
        self.assertEqual(config["keybinds"]["input.move.left"], "left,ctrl+b")
        self.assertEqual(config["keybinds"]["input.delete.to.line.end"], "ctrl+k")

    def setup_updater(self):
        self.upstream = self.root / "upstream.git"
        self.run_git("clone", "--bare", str(self.repo), str(self.upstream))
        self.run_git("remote", "add", "origin", str(self.upstream))
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
if [[ "$3" = config && "$4" = --get ]]; then
  echo https://github.com/anomalyco/opencode.git
  exit 0
fi
exec "{self.git}" "$@"
''')
        self.executable(tools / "uname", '#!/bin/bash\nif [[ "$1" = -s ]]; then echo "${TEST_OS:-Darwin}"; else echo "${TEST_MACHINE:-arm64}"; fi\n')
        self.executable(tools / "lipo", '#!/bin/bash\necho arm64\n')
        self.executable(tools / "getconf", '#!/bin/bash\n[[ "${TEST_LIBC:-glibc}" = glibc ]] || exit 1\necho "glibc 2.43"\n')
        self.executable(tools / "file", '#!/bin/bash\necho "${TEST_FILE_OUTPUT:-ELF 64-bit LSB executable, x86-64}"\n')
        self.executable(tools / "bun", '''#!/bin/bash
if [[ "$1" = --version ]]; then echo "${TEST_BUN_VERSION:-1.4.4}"; exit 0; fi
if [[ "$1" = install ]]; then exit 0; fi
for arg in "$@"; do
  if [[ "$arg" = --outdir=* ]]; then out=${arg#--outdir=}; fi
done
echo build >> "$HOME/build-count"
target=${TEST_BUILD_TARGET:-darwin-arm64}
mkdir -p "$out/cli-$target/bin"
printf '#!/bin/bash\n[[ "$1" != --version ]] || echo %s\nexit 0\n' "$OPENCODE_VERSION" > "$out/cli-$target/bin/opencode"
chmod +x "$out/cli-$target/bin/opencode"
''')
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.root),
                        PATH=str(tools) + os.pathsep + os.environ["PATH"],
                        OPENCODE_UPDATE_SOURCE=str(self.repo), OPENCODE_UPDATE_ROOT=str(self.data),
                        OPENCODE_UPDATE_REF=self.commit)

    def update(self, *args, check=True):
        result = subprocess.run(["bash", str(SOURCE / "dot_local/bin/executable_opencode-update"), *args],
                                env=self.env, text=True, capture_output=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def prepare_bootstrap(self):
        self.setup_updater()
        (self.data / "active").unlink()
        (self.data / "previous").unlink()
        (self.home / ".local/bin/opencode").unlink()
        shutil.copyfile(SOURCE / "dot_local/share/opencode/executable_opencode", self.data / "opencode")
        (self.data / "opencode").chmod(0o755)

    def linux_fixture(self):
        self.env.update(TEST_OS="Linux", TEST_MACHINE="x86_64", TEST_BUILD_TARGET="linux-x64")

    def test_fresh_host_requires_explicit_install(self):
        self.prepare_bootstrap()
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run opencode-update --install explicitly", result.stderr)
        self.assertFalse((self.home / "build-count").exists())
        self.assertFalse((self.home / ".local/bin/opencode").exists())
        self.assertFalse((self.data / "active").exists())
        self.assertFalse((self.data / "operation.lock").exists())

    def test_linux_explicit_install_then_update_and_rollback(self):
        self.prepare_bootstrap()
        self.linux_fixture()
        self.update("--install")
        first = (self.data / "active").resolve()
        self.assertEqual((self.data / "previous").resolve(), first)
        self.assertTrue((self.home / ".local/bin/opencode").is_symlink())
        manifest = json.loads((first / "manifest.json").read_text())
        self.assertEqual(manifest["build_target"], "linux-x64")
        self.assertIn("no changes made", self.update().stdout)
        self.assertIn("no changes made", self.update("--install").stdout)
        self.patch.write_text(self.patch.read_text() + "\n")
        self.update()
        second = (self.data / "active").resolve()
        self.assertNotEqual(first, second)
        self.assertEqual((self.data / "previous").resolve(), first)
        result = subprocess.run(["bash", str(SOURCE / "dot_local/bin/executable_opencode-rollback")],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.data / "active").resolve(), first)
        self.assertEqual((self.data / "previous").resolve(), second)

    def test_linux_wrong_architecture_keeps_active(self):
        self.setup_updater()
        self.linux_fixture()
        self.env["TEST_FILE_OUTPUT"] = "ELF 64-bit LSB executable, aarch64"
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("candidate lacks Linux x86-64 architecture", result.stderr)
        self.assertEqual((self.data / "active").resolve().name, "initial")

    def test_linux_musl_is_rejected_before_build(self):
        self.setup_updater()
        self.linux_fixture()
        self.env["TEST_LIBC"] = "musl"
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Linux builds require glibc", result.stderr)
        self.assertFalse((self.home / "build-count").exists())

    def test_bootstrap_patch_failure_does_not_create_install(self):
        self.prepare_bootstrap()
        self.patch.write_text(self.patch.read_text().replace("onMouseOver", "renamedUpstreamHandler"))
        result = self.update("--install", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local UI patch no longer matches upstream", result.stderr)
        self.assertFalse((self.data / "active").exists())
        self.assertFalse((self.data / "previous").exists())
        self.assertFalse((self.home / ".local/bin/opencode").exists())

    def test_partial_bootstrap_recovers_verified_generation(self):
        self.setup_updater()
        (self.data / "active").unlink()
        (self.data / "previous").unlink()
        (self.data / "previous").symlink_to(self.data / "releases/initial")
        (self.data / "pointer-transaction").write_text(json.dumps({"kind": "install", "new_active": "initial"}))
        # Recovery completes the first install, then the normal patch rebuild runs.
        self.update()
        self.assertEqual((self.data / "previous").resolve().name, "initial")
        self.assertFalse((self.data / "pointer-transaction").exists())

    def test_install_does_not_replace_invalid_pointers(self):
        self.setup_updater()
        (self.data / "active").unlink()
        (self.data / "active").write_text("user data")
        result = self.update("--install", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("active must point to a managed generation", result.stderr)
        self.assertEqual((self.data / "active").read_text(), "user data")
        self.assertFalse((self.home / "build-count").exists())

    def test_install_clones_missing_source_only_on_explicit_request(self):
        self.prepare_bootstrap()
        clone = self.root / "new-source"
        wrapper = self.root / "tools/git"
        wrapper.write_text(wrapper.read_text().replace(
            f'exec "{self.git}" "$@"',
            f'''if [[ "$1" = clone ]]; then
  exec "{self.git}" clone --no-checkout "{self.upstream}" "${{@: -1}}"
fi
exec "{self.git}" "$@"'''))
        self.env["OPENCODE_UPDATE_SOURCE"] = str(clone)
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(clone.exists())
        self.update("--install")
        self.assertTrue((clone / ".git").is_dir())
        self.assertTrue((self.data / "active/opencode").is_file())

    def test_install_repairs_missing_launcher_without_rebuilding(self):
        self.prepare_bootstrap()
        self.update("--install")
        public = self.home / ".local/bin/opencode"
        public.unlink()
        self.assertIn("no changes made", self.update("--install").stdout)
        self.assertTrue(public.is_symlink())
        self.assertEqual((self.home / "build-count").read_text().splitlines(), ["build"])

    def test_failed_public_verification_restores_previous_install(self):
        self.setup_updater()
        self.executable(self.home / ".local/bin/opencode", '#!/bin/bash\necho wrong-version\n')
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("restoring previous pointers", result.stderr)
        self.assertEqual((self.data / "active").resolve().name, "initial")
        self.assertFalse((self.data / "pointer-transaction").exists())

    def test_failed_bootstrap_public_verification_preserves_other_launcher(self):
        self.prepare_bootstrap()
        public = self.home / ".local/bin/opencode"
        original = '#!/bin/bash\necho wrong-version\n'
        self.executable(public, original)
        result = self.update("--install", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bootstrap pointers removed", result.stderr)
        self.assertEqual(public.read_text(), original)
        self.assertFalse((self.data / "active").exists())
        self.assertFalse((self.data / "previous").exists())

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

    def test_incompatible_bun_stops_before_build(self):
        self.setup_updater()
        for version in ("1.4.2", "2.0.0", "1.4.4-canary"):
            with self.subTest(version=version):
                self.env["TEST_BUN_VERSION"] = version
                result = self.update(check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Bun", result.stderr)
                self.assertEqual((self.data / "active").resolve().name, "initial")
                self.assertFalse((self.home / "build-count").exists())
                self.assertFalse((self.data / "operation.lock").exists())

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
        result = self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], self.commit)
        self.assertEqual(manifest["source_ref"], self.commit)
        self.assertIn(f"Upstream:   v2.0.26 ({older} @ {older[:10]})", result.stdout)
        self.assertIn("Active source is newer than selected upstream", result.stdout)
        self.assertIn("no changes made", self.update().stdout)

    def release_commit(self, version):
        self.write("packages/cli/package.json", json.dumps({"version": version}) + "\n")
        self.run_git("add", "packages/cli/package.json")
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                     "commit", "-qm", f"release {version}")
        return self.run_git("rev-parse", "HEAD").stdout.strip()

    def remote_git(self, *args):
        return subprocess.run([self.git, "--git-dir", str(self.upstream), *args],
                              check=True, text=True, capture_output=True)

    def test_default_selects_highest_stable_v2_tag_not_stale_branch(self):
        self.run_git("branch", "v2", self.commit)
        self.run_git("tag", "v2.0.26")
        self.release_commit("2.9.9")
        self.run_git("tag", "v2.9.9")
        target = self.release_commit("2.10.0")
        # Annotated tags must be peeled to commits, not recorded as tag objects.
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                     "tag", "-a", "v2.10.0", "-m", "release")
        self.release_commit("2.11.0-beta.1")
        for tag in ("v2.11.0-beta.1", "v2.99.0-rc.1", "v2.100.0+build", "v3.0.0", "v1.99.0"):
            self.run_git("tag", tag)
        self.setup_updater()
        self.env.pop("OPENCODE_UPDATE_REF")
        result = self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], target)
        self.assertEqual(manifest["version"], "2.10.0")
        self.assertEqual(manifest["source_ref"], "refs/tags/v2.10.0")
        self.assertIn(f"Upstream:   v2.10.0 (refs/tags/v2.10.0 @ {target[:10]})", result.stdout)
        self.assertIn("Repository: https://github.com/anomalyco/opencode.git", result.stdout)
        self.assertIn("no changes made", self.update().stdout)

    def test_default_ignores_local_tags_and_prunes_deleted_remote_tags(self):
        self.run_git("tag", "v2.0.26")
        self.setup_updater()
        self.run_git("tag", "v2.99.0")
        self.run_git("update-ref", "refs/remotes/origin/tags/v2.98.0", self.commit)
        self.env.pop("OPENCODE_UPDATE_REF")
        self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_ref"], "refs/tags/v2.0.26")
        self.assertNotEqual(self.run_git("rev-parse", "--verify", "refs/remotes/origin/tags/v2.98.0",
                                         check=False).returncode, 0)

    def test_default_without_stable_tags_fails_without_build(self):
        self.run_git("tag", "v2.1.0-beta.1")
        self.setup_updater()
        self.env.pop("OPENCODE_UPDATE_REF")
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no stable V2 tags found", result.stderr)
        self.assertEqual((self.data / "active").resolve().name, "initial")
        self.assertFalse((self.home / "build-count").exists())

    def test_branch_override_fetches_fresh_remote_tip(self):
        self.run_git("branch", "v2", self.commit)
        self.setup_updater()
        target = self.release_commit("2.1.1")
        self.run_git("push", "origin", "HEAD:refs/heads/v2")
        # This deliberately stale local ref must not determine the build target.
        self.run_git("update-ref", "refs/remotes/origin/v2", self.commit)
        self.env["OPENCODE_UPDATE_REF"] = "origin/v2"
        self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], target)
        self.assertEqual(manifest["source_ref"], "origin/v2")
        for ref in ("refs/remotes/origin/v2", "refs/heads/v2"):
            with self.subTest(ref=ref):
                self.env["OPENCODE_UPDATE_REF"] = ref
                result = self.update()
                self.assertIn(f"({ref} @ {target[:10]})", result.stdout)
                self.assertIn("no changes made", result.stdout)

    def test_tag_override_fetches_tag_absent_locally(self):
        self.setup_updater()
        target = self.release_commit("2.1.1")
        self.run_git("push", "origin", "HEAD:refs/tags/v2.1.1")
        self.env["OPENCODE_UPDATE_REF"] = "refs/tags/v2.1.1"
        self.update()
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], target)
        self.assertEqual(manifest["source_ref"], "refs/tags/v2.1.1")

    def test_override_fetch_failure_keeps_active_build(self):
        self.setup_updater()
        self.env["OPENCODE_UPDATE_REF"] = "origin/missing"
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("fetch of upstream ref failed", result.stderr)
        self.assertEqual((self.data / "active").resolve().name, "initial")
        self.assertFalse((self.home / "build-count").exists())

    def test_divergent_stable_release_updates_without_approval(self):
        older = self.commit
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                     "commit", "--allow-empty", "-qm", "active branch")
        self.commit = self.run_git("rev-parse", "HEAD").stdout.strip()
        self.run_git("checkout", "--detach", older)
        target = self.release_commit("2.1.1")
        self.run_git("tag", "v2.1.1")
        self.setup_updater()
        self.env.pop("OPENCODE_UPDATE_REF")
        result = self.update()
        self.assertIn("Upstream history diverges; building fetched target", result.stdout)
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], target)
        self.assertEqual((self.data / "previous").resolve().name, "initial")
        self.assertIn("no changes made", self.update().stdout)


    def test_divergent_explicit_ref_ignores_obsolete_approval(self):
        older = self.commit
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                     "commit", "--allow-empty", "-qm", "active branch")
        self.commit = self.run_git("rev-parse", "HEAD").stdout.strip()
        self.run_git("checkout", "--detach", older)
        target = self.release_commit("2.1.1")
        self.setup_updater()
        self.env["OPENCODE_UPDATE_REF"] = target
        self.env["OPENCODE_UPDATE_APPROVE_DIVERGENT_SHA"] = "obsolete-value"
        result = self.update()
        self.assertIn("Upstream history diverges; building fetched target", result.stdout)
        manifest = json.loads((self.data / "active/manifest.json").read_text())
        self.assertEqual(manifest["source_commit"], target)
        self.assertEqual((self.data / "previous").resolve().name, "initial")

    def test_help_needs_no_helpers_and_makes_no_changes(self):
        for flag in ("-h", "--help"):
            with self.subTest(flag=flag):
                result = subprocess.run(
                    ["bash", str(SOURCE / "dot_local/bin/executable_opencode-update"), flag],
                    env=dict(os.environ, HOME=str(self.home)), text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Usage: opencode-update", result.stdout)
                self.assertFalse(self.home.exists())


if __name__ == "__main__":
    unittest.main()
