"""Shared test helpers: a throwaway chezmoi home, command stubs, a terminal run."""

import json
import os
from pathlib import Path
import pty
import shutil
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parents[1]
# Absolute, so a test may give chezmoi a PATH of stubs only.
CHEZMOI = shutil.which("chezmoi")


class ChezmoiHome:
    """One temporary directory holding a home, config, state and cache.

    By default chezmoi reads the repository itself; `copy` switches to a
    private source holding only the named repository files.
    """

    def __init__(self, test, home="home"):
        temp = tempfile.TemporaryDirectory(prefix="chezmoi-test-")
        test.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.home = self.root / home
        self.home.mkdir()
        self.source = SOURCE
        self.config = self.root / "config.toml"
        self.config.write_text("")
        self.env = dict(os.environ, HOME=str(self.home))
        self.env.pop("CHEZMOI_VARIANT", None)
        self.cwd = self.root

    def configure(self, host=None, variant="helm", extra=""):
        lines = ["[data]", f'variant = "{variant}"']
        if host is not None:
            lines.append(f'host = "{host}"')
        lines += ['git_name = "Test"', 'git_email = "test@example.org"']
        self.config.write_text("\n".join(lines) + "\n" + extra)

    def copy(self, *names):
        if self.source == SOURCE:
            self.source = self.root / "source"
        for name in names:
            target = self.source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(SOURCE / name, target)

    def run(self, *args, check=True, timeout=None):
        return subprocess.run(
            [CHEZMOI, "--source", str(self.source), "--destination", str(self.home),
             "--config", str(self.config), "--persistent-state", str(self.root / "state"),
             "--cache", str(self.root / "cache"), "--no-tty", *args],
            env=self.env, cwd=self.cwd, stdin=subprocess.DEVNULL, text=True,
            capture_output=True, check=check, timeout=timeout)

    def render(self, template, data=None):
        """Render template text, optionally with --override-data."""
        extra = ["--override-data", json.dumps(data)] if data is not None else []
        return self.run(*extra, "execute-template", template).stdout


def stub(directory, name, body="exit 0", calls=None):
    """Write an executable stub; with `calls`, it logs each invocation there."""
    log = f'echo "{name} $*" >> "{calls}"\n' if calls else ""
    path = Path(directory) / name
    path.write_text(f"#!/bin/sh\n{log}{body}\n")
    path.chmod(0o755)
    return path


def run_on_terminal(script, env):
    """Run a shell script on a pseudo-terminal; return (exit code, output)."""
    pid, fd = pty.fork()
    if pid == 0:
        os.execve(shutil.which("sh"), ["sh", str(script)], env)
    output = b""
    try:
        while chunk := os.read(fd, 4096):
            output += chunk
    except OSError:  # EIO at end of output on Linux
        pass
    return os.waitstatus_to_exitcode(os.waitpid(pid, 0)[1]), output.decode()
