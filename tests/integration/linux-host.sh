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
apt-get install -y -qq sudo curl ca-certificates git vim-tiny >/dev/null

useradd -m -s /bin/bash "$user"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$user" > /etc/sudoers.d/$user
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin >/dev/null

mkdir -p "$home/.local/share"
cp -R /dotfiles "$home/.local/share/chezmoi"
rm -rf "$home/.local/share/chezmoi/node_modules"
chown -R "$user:$user" "$home/.local"

as_user() {
    sudo -u "$user" -H env -C "$home" "$@"
}

echo "== chezmoi init --apply (host=$host)"
as_user chezmoi init --apply --no-tty --promptDefaults \
    --promptString "Host profile=$host" 2>/tmp/init.err || { cat /tmp/init.err >&2; exit 1; }
cat /tmp/init.err >&2

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
# useradd gave the user bash; without a terminal the apply only names the command.
check "apply prints how to make zsh the login shell" grep -q 'chsh -s /.*/zsh' /tmp/init.err
usermod -s "$(command -v zsh)" "$user"
check "the login shell script disappears once zsh is the login shell" as_user sh -c \
    'status=$(chezmoi status) && ! printf "%s\n" "$status" | grep -q login-shell'
check "zsh starts without errors" as_user zsh -ic 'exit 0'
check "zsh uses en_US.UTF-8 and the locale exists" as_user zsh -ic \
    '[[ $LANG == en_US.UTF-8 && $LC_ALL == en_US.UTF-8 && -z ${LANGUAGE-} ]] && test -z "$(locale 2>&1 >/dev/null)"'
check "en_US.UTF-8 is the system locale" grep -Eq '^LANG="?en_US\.UTF-8"?$' /etc/default/locale
check "zsh startup prints nothing to stderr" \
    as_user sh -c 'test -z "$(zsh -ic "exit 0" 2>&1 >/dev/null)"'
# Capture first so a failing command cannot pass as empty output.
stem=$(as_user chezmoi execute-template \
    '{{ if hasKey .hosts .host }}{{ if has "stem" (index .hosts .host).groups }}yes{{ end }}{{ end }}')
echo "== stem profile: ${stem:-no}"
if [ "$stem" = yes ]; then
check "mise has no missing tools" as_user sh -c 'missing=$(mise ls --missing) && test -z "$missing"'
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
else
check "leaf host has no mise" as_user sh -c \
    '! test -e ~/.config/mise/config.toml && ! command -v mise >/dev/null && ! test -e /etc/apt/sources.list.d/extrepo_mise.sources'
check "leaf host has no Neovim config" as_user sh -c '! test -e ~/.config/nvim'
check "leaf host has no C toolchain" sh -c '! command -v cc >/dev/null'
fi
check "bash login shell reads .bashrc and ~/.local/bin" as_user bash -lic \
    'alias ll >/dev/null && case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac'
# Most of rc.d returns early without a terminal, so start zsh on a pseudo-terminal.
tty_zsh() {
    as_user env TERM=xterm-256color script -qec "zsh -ilc '$1' 2>$home/zsh.err" /dev/null
}
if [ "$stem" = yes ]; then
    tty_zsh exit >/dev/null 2>&1 || true # the first start clones plugins
fi
check "zsh on a terminal loads the interactive rc.d" tty_zsh '(( ${+widgets[insert-line-break]} ))'
check "zsh on a terminal prints nothing to stderr" sh -c "! grep . $home/zsh.err"
# zsh only uses file.zwc when it holds that same file, so a combined digest is dead weight.
check "zsh login compiles each startup file on its own" as_user zsh -fc '
    valid() {
        [[ -s ~/.config/zsh/.zshrc.zwc && -s ~/.config/zsh/rc.d/00-env.zsh.zwc ]] || return 1
        for z in ~/.zshenv.zwc ~/.config/zsh/{,rc.d/}*.zwc(DN); do
            [[ "$(zcompile -t $z 2>&1 | sed -n 2p)" == ${z%.zwc} ]] || { print -- "$z"; return 1; }
        done
    }
    # Earlier logins compile in the background; wait for them to settle.
    for i in {1..20}; do valid >/dev/null && exit 0; sleep 0.5; done
    valid'
if [ "$stem" != yes ]; then
    check "leaf zsh downloads no plugins" as_user sh -c '! test -e ~/.local/share/zinit'
fi
if [ "$stem" = yes ]; then editor=nvim; else editor=vim; fi
check "zsh sets EDITOR, VISUAL and an absolute SUDO_EDITOR" as_user zsh -ic \
    "[[ \$EDITOR == $editor && \$VISUAL == $editor && \$SUDO_EDITOR == /*/$editor' -i NONE' && -x \${SUDO_EDITOR% -i NONE} ]]"
# A real sudoedit of a root-owned file, as the user would run it.
edit_probe=/etc/sudoedit-probe
secret=root-only-marker
printf '%s\nbefore\n' "$secret" > "$edit_probe"
chmod 600 "$edit_probe"
cat > /tmp/edit.vim <<'EOF_VIM'
1delete
%s/before/after/
wq
EOF_VIM
cat > /tmp/edit.zsh <<EOF_ZSH
SUDO_EDITOR+=" -S /tmp/edit.vim"
timeout --foreground 60 sudo -e $edit_probe
EOF_ZSH
chmod 644 /tmp/edit.vim /tmp/edit.zsh
as_user script -qec "zsh -ic 'source /tmp/edit.zsh'" /dev/null >/dev/null 2>&1 || true
check "sudoedit edits with SUDO_EDITOR" grep -qx after "$edit_probe"
check "sudoedit leaves no file contents in the user's editor state" sh -c \
    "! grep -rlaF $secret $home/.local/state $home/.viminfo 2>/dev/null"
for vim in vim vim.tiny; do
    check "$vim starts without errors" as_user env TERM=xterm-256color sh -c \
        "out=\$(timeout 30 script -qec '$vim +qa' /dev/null) && ! printf '%s' \"\$out\" | grep -E 'E[0-9]+:|Press ENTER'"
done
check "vim starts without errors when its state directory is unusable" as_user env \
    TERM=xterm-256color XDG_STATE_HOME=/proc/unusable sh -c \
    "out=\$(timeout 30 script -qec 'vim +qa' /dev/null) && ! printf '%s' \"\$out\" | grep -E 'E[0-9]+:|Press ENTER'"
# Both zsh directories are glob-loaded, so leftovers must not survive an apply.
as_user sh -c 'touch ~/.config/zsh/rc.d/99-leftover.zsh ~/.config/zsh/functions/leftover'
check "apply removes unmanaged zsh files" as_user sh -c \
    'chezmoi apply --force --no-tty --exclude scripts && ! test -e ~/.config/zsh/rc.d/99-leftover.zsh && ! test -e ~/.config/zsh/functions/leftover'
check "chezmoi reports nothing left to apply" as_user sh -c \
    'status=$(chezmoi status) && test -z "$(printf "%s\n" "$status" | grep -v "^ R install-opencode-")"'

echo "== installed apt packages: $(dpkg-query -f '.\n' -W | wc -l)"
exit $status
