#!/bin/sh
# Runs only in the disposable container created by run-claude-cloud.sh.
set -eu
test "$(readlink /bin/sh)" = dash
apt-get update -qq
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  git curl nodejs python3-venv python3-pip ca-certificates > /tmp/cloud-prerequisites.log 2>&1; then
  cat /tmp/cloud-prerequisites.log
  exit 1
fi
mkdir -p /home/user/probe
cd /home/user/probe
python3 - <<'PY'
import json
import os
from pathlib import Path
import subprocess

home = Path.home()
assert str(home) == "/root"
assert not Path.cwd().is_relative_to(home)
sentinels = {
    ".gitconfig": '[commit]\n\tgpgsign = true\n[user]\n\tsigningkey = cloud-signing-key\n',
    ".claude.json": '{"cloudOwned": true}\n',
    ".claude/launcher.json": '{"launcher": "cloud"}\n',
    ".claude/sessions/probe.json": '{"session": "cloud"}\n',
    ".claude/synced-skills/cloud/SKILL.md": "cloud-synced state\n",
    ".claude/skills/cloud-owned/SKILL.md": "---\nname: cloud-owned\ndescription: Cloud state fixture\n---\nCloud-owned skill\n",
    ".claude/agents/cloud-owned.md": "---\nname: cloud-owned\ndescription: Cloud state fixture\n---\nCloud-owned agent\n",
}
for name, content in sentinels.items():
    path = home / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
original_settings = {
    "env": {"CLOUD_SENTINEL": "keep"},
    "hooks": {"PreToolUse": [{"hooks": [{"type": "command", "command": "true"}]}]},
}
settings_path = home / ".claude/settings.json"
settings_path.write_text(json.dumps(original_settings))

env = dict(os.environ, GIT_CONFIG_GLOBAL=str(home / ".gitconfig"), GIT_CONFIG_NOSYSTEM="1")
for key in list(env):
    if key.startswith("GITHUB_APM_PAT") or key in ("GITHUB_TOKEN", "GH_TOKEN", "CLAUDE_CONFIG_DIR"):
        del env[key]

def run(command, **kwargs):
    result = subprocess.run(command, env=env, text=True, capture_output=True, **kwargs)
    if result.returncode:
        print(result.stdout, end="")
        print(result.stderr, end="")
        result.check_returncode()
    return result

bootstrap = ["/bin/sh", "/dotfiles/scripts/bootstrap-claude-cloud.sh"]
first = run(bootstrap, stdin=subprocess.DEVNULL)
(home / "bootstrap-first.log").write_text(first.stdout + first.stderr)
second = run(bootstrap, stdin=subprocess.DEVNULL)
assert not (second.stdout + second.stderr).strip(), "second setup reran installers"

command = [str(home / ".local/bin/chezmoi"), "--source", "/dotfiles"]
assert "v2.65.0," in run(command + ["--version"]).stdout
apm = home / ".local/share/claude-cloud/apm/bin/apm"
assert run([str(apm), "--version"]).stdout.strip() == "Agent Package Manager (APM) CLI version 0.28.0"
assert not run(command + ["diff"]).stdout
assert set(run(command + ["managed"]).stdout.splitlines()) == {
    ".apm", ".apm/apm.yml", ".claude", ".claude/CLAUDE.md", "claude-cloud-apm.sh",
}
assert (home / ".claude/CLAUDE.md").read_text().strip() == Path("/dotfiles/.chezmoitemplates/AGENTS.md").read_text().strip()
assert not (home / ".claude/AGENTS.md").exists()
for path in (".config/mise", ".config/zsh", ".config/nvim", ".zshenv", ".codex",
             ".local/bin/ai-check", ".local/bin/runlog"):
    assert not (home / path).exists(), path

settings = json.loads(settings_path.read_text())
assert settings["env"] == original_settings["env"]
assert settings["hooks"]["PreToolUse"] == original_settings["hooks"]["PreToolUse"]
for event in ("SessionStart", "UserPromptSubmit"):
    for entry in settings["hooks"][event]:
        for hook in entry["hooks"]:
            assert str(home) in hook["command"], hook
            result = run(hook["command"], shell=True, input="{}")
            if event == "SessionStart":
                assert "CAVEMAN MODE ACTIVE" in result.stdout

# Replay the actual rendered deployment script to cover settings checks on reruns.
deployment = run(command + ["cat", str(home / "claude-cloud-apm.sh")]).stdout
settings_path.unlink()  # Remove only this container's test-owned settings fixture.
run(["/bin/sh"], input=deployment)
rebuilt = json.loads(settings_path.read_text())
assert "SessionStart" in rebuilt["hooks"] and "UserPromptSubmit" in rebuilt["hooks"]
valid_bytes = settings_path.read_bytes()

for invalid in (b'{"env": {"CLOUD_SENTINEL": "keep"}, "hooks": ', b'[]', b'\xff'):
    settings_path.write_bytes(invalid)
    result = subprocess.run(["/bin/sh"], input=deployment, env=env, text=True,
                            capture_output=True, timeout=30)
    assert result.returncode != 0
    assert "refusing APM deployment" in result.stderr, result.stderr
    assert settings_path.read_bytes() == invalid
settings_path.write_bytes(valid_bytes)

# Root ignores mode-000 permissions; use an unprivileged uid for a real read failure.
unreadable_home = Path("/home/cloud-unreadable")
unreadable_path = unreadable_home / ".claude/settings.json"
unreadable_path.parent.mkdir(parents=True)
unreadable_bytes = b'{"cloudOwned": true}'
unreadable_path.write_bytes(unreadable_bytes)
unreadable_path.chmod(0)
result = subprocess.run(["/bin/sh"], input=deployment,
                        env=dict(env, HOME=str(unreadable_home)), text=True,
                        capture_output=True, timeout=30, user=65534, group=65534,
                        extra_groups=[])
assert result.returncode != 0
assert "refusing APM deployment" in result.stderr, result.stderr
assert unreadable_path.read_bytes() == unreadable_bytes
assert not (unreadable_home / ".local").exists()

for name, content in sentinels.items():
    assert (home / name).read_text() == content, name
skills = sorted(p.parent.name for p in (home / ".claude/skills").glob("*/SKILL.md"))
agents = sorted(p.name for p in (home / ".claude/agents").glob("*.md"))
assert len(skills) == 12 and "brain-vault" not in skills, skills
assert len(agents) == 4, agents
assert not run(command + ["diff"]).stdout
print("PASS: Ubuntu 24.04 amd64/dash, pinned bootstrap/APM, real settings merge,")
print("      missing/malformed/unreadable settings, host-state preservation, and idempotency")
PY
