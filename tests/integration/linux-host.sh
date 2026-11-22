#!/bin/sh
# Runs inside a fresh Ubuntu container as root: apply these dotfiles as a
# given host profile for a sudo-capable user, then check the result.
set -eu

host=${1:?usage: linux-host.sh <host-profile>}
user=dev
home=/home/$user

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# What a freshly installed server already has, plus chezmoi's installer needs.
apt-get install -y -qq sudo curl ca-certificates git >/dev/null

useradd -m -s /bin/bash "$user"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$user" > /etc/sudoers.d/$user
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin >/dev/null

mkdir -p "$home/.local/share"
cp -R /dotfiles "$home/.local/share/chezmoi"
rm -rf "$home/.local/share/chezmoi/node_modules"
chown -R "$user:$user" "$home/.local"

as_user() {
    sudo -u "$user" -H env -C "$home" "$@"
}

echo "== chezmoi init --apply (host=$host)"
as_user chezmoi init --apply --no-tty --promptDefaults \
    --promptString "Host profile=$host"

echo "== checks"
status=0
check() {
    label=$1
    shift
    if output=$("$@" 2>&1); then
        printf 'ok    %s\n' "$label"
    else
        printf 'FAIL  %s\n%s\n' "$label" "$output" | sed 's/^/      /'
        status=1
    fi
}
check "zsh starts without errors" as_user zsh -ic 'exit 0'
check "zsh startup prints nothing to stderr" \
    as_user sh -c 'test -z "$(zsh -ic "exit 0" 2>&1 >/dev/null)"'
check "mise has no missing tools" as_user sh -c 'test -z "$(mise ls --missing)"'
# First start clones plugins and compiles parsers; let that finish first.
as_user zsh -ic 'nvim --headless "+Lazy! sync" "+sleep 60" +qa' >/dev/null 2>&1 || true
check "neovim starts without errors" as_user zsh -ic \
    'nvim --headless "+lua vim.defer_fn(function() local m = vim.api.nvim_exec2(\"messages\", {output=true}).output; if m:find(\"E%d+:\") or m:find(\"[Ee]rror\") then io.stderr:write(m) vim.cmd(\"cq\") end vim.cmd(\"qa!\") end, 5000)"'
# A release upgrade leaves third-party sources disabled; rerunning the
# package script must re-enable the mise source.
mise_source=/etc/apt/sources.list.d/extrepo_mise.sources
sed -i '/^Enabled:/d' "$mise_source"
echo 'Enabled: no' >> "$mise_source"
check "package script re-enables a disabled mise source" as_user sh -c \
    'chezmoi cat ~/install-packages.sh | sh >/dev/null 2>&1 && ! grep -qi "^Enabled: no" /etc/apt/sources.list.d/extrepo_mise.sources'
check "chezmoi reports nothing left to apply" as_user sh -c \
    'test -z "$(chezmoi status | grep -v "^ R install-opencode-")"'

echo "== installed apt packages: $(dpkg-query -f '.\n' -W | wc -l)"
exit $status
