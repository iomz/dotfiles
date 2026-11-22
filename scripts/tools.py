#!/usr/bin/env python3
"""Edit the per-host tool inventory (.chezmoidata/tools.toml).

Edits are scoped to one entry's lines. Every save then normalizes the layout
(entries in sections derived from their managers, sorted by name, keys in a
fixed order) and is re-validated with the inventory schema test, rolling back
if it fails.
"""

import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tomllib

SOURCE = Path(__file__).resolve().parents[1]
INVENTORY = SOURCE / ".chezmoidata/tools.toml"
NAME = re.compile(r"^[A-Za-z0-9_-]+$")
OS_FIELDS = {"brew": "darwin.brew", "apt": "linux.apt", "linux-brew": "linux.brew"}
# New entries go before this section so the guard settings stay last.
TAIL_MARKER = "# --- Homebrew guard"
MISE_ONLY_KEYS = ("mise_id", "mise", "hold", "homebrew_guard")
# Sections derived from an entry's managers, in file order.
SECTIONS = (("mise", "mise"), ("both", "macOS and Linux packages"),
            ("darwin", "macOS packages"), ("linux", "Linux packages"))
MARKER_WIDTH = 74
# Key order inside an entry; a prefix ending in "." covers an OS table.
KEY_ORDER = ("mise_id", "mise", "hold", "homebrew_guard", "bin", "darwin.", "linux.",
             "hosts", "groups", "arch")


class ToolError(Exception):
    pass


class Inventory:
    def __init__(self, path):
        self.path = Path(path)
        self.text = self.path.read_text()
        self.data = tomllib.loads(self.text)

    @property
    def tools(self):
        return self.data["tools"]

    def entry_span(self, name):
        """Return (start, end) line indexes of an entry, excluding trailing blanks."""
        lines = self.text.splitlines(keepends=True)
        header = f"[tools.{name}]\n"
        if header not in lines:
            raise ToolError(f"no entry: {name}")
        start = lines.index(header)
        end = start + 1
        while end < len(lines) and not lines[end].startswith(("[", "# ---")):
            end += 1
        while end > start + 1 and not lines[end - 1].strip():
            end -= 1
        return start, end

    def entry_lines(self, name):
        start, end = self.entry_span(name)
        return self.text.splitlines(keepends=True)[start + 1:end]

    def replace_entry(self, name, body):
        lines = self.text.splitlines(keepends=True)
        start, end = self.entry_span(name)
        lines[start + 1:end] = [line + "\n" for line in body]
        self.text = "".join(lines)

    def append_entry(self, name, body):
        block = f"[tools.{name}]\n" + "".join(line + "\n" for line in body)
        index = self.text.find("\n" + TAIL_MARKER)
        if index == -1:
            self.text = self.text.rstrip("\n") + "\n\n" + block
        else:
            self.text = self.text[:index].rstrip("\n") + "\n\n" + block + self.text[index:]

    def save(self, validate=True):
        """Write atomically; restore the previous file if validation fails."""
        self.text = normalize(self.text)
        previous = self.path.read_text()
        temp = self.path.with_name(self.path.name + ".tmp")
        temp.write_text(self.text)
        os.replace(temp, self.path)
        if validate:
            result = subprocess.run(
                [sys.executable, "-m", "unittest", "-q", "tests.test_tool_inventory.InventorySchemaTest"],
                cwd=SOURCE, capture_output=True, text=True,
                env=dict(os.environ, TOOLS_INVENTORY=str(self.path.resolve())))
            if result.returncode != 0:
                self.path.write_text(previous)
                raise ToolError("inventory validation failed; change reverted\n" + result.stderr)


def section_marker(title):
    marker = f"# --- {title} "
    return marker + "-" * (MARKER_WIDTH - len(marker))


def entry_kind(tool):
    if "mise" in tool:
        return "mise"
    darwin, linux = "darwin" in tool, "linux" in tool
    return "both" if darwin and linux else "darwin" if darwin else "linux"


def key_rank(line):
    key = line.split("=", 1)[0].strip()
    for index, prefix in enumerate(KEY_ORDER):
        if key == prefix or (prefix.endswith(".") and key.startswith(prefix)):
            # Within an OS table the manager comes before its arch filter.
            return (index, key.endswith(".arch"), key)
    return (len(KEY_ORDER), False, key)


def sort_entry_lines(lines):
    """Order key lines; a comment stays attached to the key line after it."""
    units, comments = [], []
    for line in lines:
        if line.lstrip().startswith("#"):
            comments.append(line)
        else:
            units.append((key_rank(line), comments + [line]))
            comments = []
    ordered = [line for _, unit in sorted(units, key=lambda u: u[0]) for line in unit]
    return ordered + comments


def normalize(text):
    """Return the inventory with entries in derived sections, sorted by name."""
    data = tomllib.loads(text)
    lines = text.splitlines(keepends=True)
    head_end = next((i for i, line in enumerate(lines)
                     if line.startswith(("[tools.", "# ---"))), len(lines))
    tail_start = next((i for i, line in enumerate(lines) if line.startswith(TAIL_MARKER)),
                      len(lines))
    blocks, current, leading = {}, None, []
    for line in lines[head_end:tail_start]:
        if line.startswith("# ---"):
            leading = []
        elif line.startswith("[tools."):
            current = line.strip()[len("[tools."):-1]
            blocks[current] = {"lead": leading, "body": []}
            leading = []
        elif not line.strip():
            current = None
        elif current is None:
            leading.append(line)
        else:
            blocks[current]["body"].append(line)
    out = "".join(lines[:head_end]).rstrip("\n") + "\n"
    for kind, title in SECTIONS:
        names = sorted(n for n in blocks if entry_kind(data["tools"][n]) == kind)
        if not names:
            continue
        out += "\n" + section_marker(title) + "\n"
        for name in names:
            block = blocks[name]
            out += "\n" + "".join(block["lead"]) + f"[tools.{name}]\n"
            out += "".join(sort_entry_lines(block["body"]))
    if tail_start < len(lines):
        out += "\n" + "".join(lines[tail_start:])
    if tomllib.loads(out) != data:
        raise ToolError("normalizing would change inventory data; file left unchanged")
    return out


def toml_string(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def toml_list(values):
    return "[" + ", ".join(toml_string(v) for v in values) + "]"


def mise_id(name, tool):
    return tool.get("mise_id", name)


def mise_latest(tool_id):
    result = subprocess.run(["mise", "latest", tool_id], capture_output=True, text=True)
    version = result.stdout.strip()
    if result.returncode != 0 or not version:
        raise ToolError(f"mise latest {tool_id} failed: {result.stderr.strip() or 'no version'}")
    return version


def current_version(tool):
    value = tool["mise"]
    return value.get("version") if isinstance(value, dict) else value


def set_mise_version(lines, version):
    """Rewrite the version in the entry's `mise = ...` line."""
    for index, line in enumerate(lines):
        if re.match(r"^mise\s*=", line):
            if line.split("=", 1)[1].strip().startswith("{"):
                new, count = re.subn(r'(\bversion\s*=\s*)"[^"]*"', r"\g<1>" + toml_string(version), line, count=1)
                if not count:
                    raise ToolError("mise table has no version")
            else:
                new = f"mise = {toml_string(version)}\n"
            lines[index] = new
            return lines
    raise ToolError("entry has no mise line")


def command_add(args, inventory):
    if not NAME.match(args.name):
        raise ToolError(f"invalid name: {args.name} (letters, digits, - and _ only)")
    exists = args.name in inventory.tools
    if args.manager == "mise":
        if exists:
            raise ToolError(f"{args.name} already exists; use tool-bump or tool-move")
        tool_id = args.mise_id or args.name
        version = args.package or mise_latest(tool_id)
        body = []
        if args.mise_id:
            body.append(f"mise_id = {toml_string(args.mise_id)}")
        body.append(f"mise = {toml_string(version)}")
    else:
        if args.mise_id:
            raise ToolError("--mise-id requires the mise manager")
        field = OS_FIELDS[args.manager]
        package = args.package or args.name
        os_name, key = field.split(".")
        if exists:
            tool = inventory.tools[args.name]
            if "mise" in tool:
                raise ToolError(f"{args.name} is managed by mise; use tool-move")
            if key in tool.get(os_name, {}):
                raise ToolError(f"{args.name} already declares {field}")
            if args.hosts or args.groups:
                raise ToolError("--hosts/--groups apply to new entries only")
            inventory.replace_entry(args.name, [line.rstrip("\n") for line in inventory.entry_lines(args.name)]
                                    + [f"{field} = {toml_string(package)}"])
            inventory.save()
            print(f"added {field} = {package} to {args.name}")
            apply_all(args, inventory)
            return
        body = [f"{field} = {toml_string(package)}"]
    if args.hosts:
        body.append(f"hosts = {toml_list(args.hosts.split(','))}")
    if args.groups:
        body.append(f"groups = {toml_list(args.groups.split(','))}")
    inventory.append_entry(args.name, body)
    inventory.save()
    print(f"added {args.name}: " + "; ".join(body))
    apply_all(args, inventory)


def command_normalize(args, inventory):
    before = inventory.text
    inventory.save()
    print("layout unchanged" if inventory.text == before else "layout normalized")


def command_bump(args, inventory):
    names = [args.name] if args.name else sorted(inventory.tools)
    changed = 0
    for name in names:
        tool = inventory.tools.get(name)
        if tool is None:
            raise ToolError(f"no entry: {name}")
        if "mise" not in tool:
            if args.name:
                raise ToolError(f"{name} is not a mise entry")
            continue
        version = current_version(tool)
        if tool.get("hold"):
            print(f"hold    {name} {version}")
            continue
        if version == "latest" and not args.include_latest:
            continue
        latest = mise_latest(mise_id(name, tool))
        if latest == version:
            continue
        lines = [line for line in inventory.entry_lines(name)]
        inventory.replace_entry(name, [line.rstrip("\n") for line in set_mise_version(lines, latest)])
        print(f"bump    {name} {version} -> {latest}")
        changed += 1
    print(f"{changed} entr{'y' if changed == 1 else 'ies'} updated")
    if changed:
        inventory.save()
        apply_all(args, inventory)


def run(command, **kwargs):
    print("+ " + " ".join(command))
    return subprocess.run(command, check=True, **kwargs)


def confirm(question):
    if not sys.stdin.isatty():
        print(f"{question} [y/N] skipped (no terminal)")
        return False
    return input(f"{question} [y/N] ").strip().lower() in ("y", "yes")


def apply_all(args, inventory):
    """Apply the whole source so installs follow the edit; git stays manual."""
    if args.no_apply or inventory.path.resolve() != INVENTORY.resolve():
        print("not applied; run chezmoi apply")
        return
    run(["chezmoi", "apply"])


def apply_rendered():
    home = Path.home()
    run(["chezmoi", "apply", str(home / ".config/mise/config.toml"),
         str(home / ".config/zsh/rc.d/00-homebrew-guard.zsh")])


def command_move(args, inventory):
    if sys.platform != "darwin":
        raise ToolError("tool-move handles mise and Homebrew on macOS only")
    tool = inventory.tools.get(args.name)
    if tool is None:
        raise ToolError(f"no entry: {args.name}")
    executable = args.bin or tool.get("bin") or args.name
    keep = [line.rstrip("\n") for line in inventory.entry_lines(args.name)
            if not re.match(r"^(" + "|".join(MISE_ONLY_KEYS + ("darwin\\.brew", "bin")) + r")\s*=", line)]
    bin_line = [f"bin = {toml_string(executable)}"] if executable != args.name else []

    if args.target == "brew":
        if "mise" not in tool:
            raise ToolError(f"{args.name} is not managed by mise")
        tool_id = mise_id(args.name, tool)
        formula = args.package or args.name
        # The guard forbids mise-owned names; this migration lifts it once.
        run(["brew", "install", formula], env=dict(os.environ, HOMEBREW_FORBIDDEN_FORMULAE=""))
        prefix = subprocess.run(["brew", "--prefix"], capture_output=True, text=True, check=True).stdout.strip()
        path = Path(prefix) / "bin" / executable
        if not os.access(path, os.X_OK):
            raise ToolError(f"{path} missing after brew install; inventory unchanged")
        inventory.replace_entry(args.name, keep + bin_line + [f"darwin.brew = {toml_string(formula)}"])
        inventory.save()
        apply_rendered()
        print(f"verified {path}")
        if confirm(f"Uninstall the mise copy of {tool_id}?"):
            run(["mise", "uninstall", "--all", tool_id])
    else:
        if "mise" in tool:
            raise ToolError(f"{args.name} is already managed by mise")
        formula = tool.get("darwin", {}).get("brew")
        if not formula:
            raise ToolError(f"{args.name} has no darwin.brew formula")
        if any(key in tool.get("linux", {}) for key in ("apt", "brew")):
            raise ToolError(f"{args.name} also declares Linux packages; move them by hand")
        tool_id = args.mise_id or args.name
        version = args.package or mise_latest(tool_id)
        body = [line for line in keep if not line.startswith("darwin.")]
        if args.mise_id:
            body.append(f"mise_id = {toml_string(args.mise_id)}")
        body += bin_line + [f"mise = {toml_string(version)}"]
        # Install and verify before touching the inventory, so a failure leaves
        # the entry on Homebrew and the move can simply be retried.
        run(["mise", "install", f"{tool_id}@{version}"])
        found = subprocess.run(["mise", "exec", f"{tool_id}@{version}", "--", "sh", "-c",
                                f"command -v {shlex.quote(executable)}"], capture_output=True, text=True)
        if found.returncode != 0 or "/installs/" not in found.stdout:
            raise ToolError(f"mise does not provide '{executable}'; inventory unchanged")
        inventory.replace_entry(args.name, body)
        inventory.save()
        apply_rendered()
        run(["mise", "reshim"])
        print(f"verified {found.stdout.strip()}")
        if confirm(f"Uninstall Homebrew formula {formula}?"):
            run(["brew", "uninstall", formula])


def main(argv=None):
    parser = argparse.ArgumentParser(prog="tools", description=__doc__.splitlines()[0])
    parser.add_argument("--inventory", default=str(INVENTORY), help=argparse.SUPPRESS)
    sub = parser.add_subparsers(dest="command", required=True)

    add = sub.add_parser("add", help="add a tool entry or an OS package to an entry")
    add.add_argument("name")
    add.add_argument("manager", choices=["mise", *OS_FIELDS])
    add.add_argument("package", nargs="?", help="version for mise, package name otherwise")
    add.add_argument("--mise-id", help="mise tool id when it differs from the name")
    scope = add.add_mutually_exclusive_group()
    scope.add_argument("--hosts", help="comma-separated host names")
    add.add_argument("--no-apply", action="store_true", help="edit only; skip chezmoi apply")
    scope.add_argument("--groups", help="comma-separated group names")

    bump = sub.add_parser("bump", help="update pinned mise versions to mise latest")
    bump.add_argument("name", nargs="?")
    bump.add_argument("--no-apply", action="store_true", help="edit only; skip chezmoi apply")
    bump.add_argument("--include-latest", action="store_true",
                      help='also pin entries currently set to "latest"')

    sub.add_parser("normalize", help="re-sort the inventory after hand edits")

    move = sub.add_parser("move", help="move a tool between mise and Homebrew (macOS)")
    move.add_argument("name")
    move.add_argument("target", choices=["mise", "brew"])
    move.add_argument("package", nargs="?", help="formula for brew, version for mise")
    move.add_argument("--bin", help="executable name when it differs from the tool name")
    move.add_argument("--mise-id", help="mise tool id when it differs from the name")

    args = parser.parse_args(argv)
    try:
        inventory = Inventory(args.inventory)
        {"add": command_add, "bump": command_bump, "move": command_move,
         "normalize": command_normalize}[args.command](args, inventory)
    except (ToolError, subprocess.CalledProcessError) as error:
        print(f"tools: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
