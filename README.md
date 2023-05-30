![Linux](https://img.shields.io/static/v1?style=for-the-badge&message=Linux&color=222222&logo=Linux&logoColor=FCC624&label=)
![macOS](https://img.shields.io/static/v1?style=for-the-badge&message=macOS&color=000000&logo=macOS&logoColor=FFFFFF&label=)
![Neovim](https://img.shields.io/static/v1?style=for-the-badge&message=Neovim&color=57A143&logo=Neovim&logoColor=FFFFFF&label=)
![Zsh](https://img.shields.io/static/v1?style=for-the-badge&message=Zsh&color=224466&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI2NzIiIGhlaWdodD0iNjcyIj48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjY3MiIgaGVpZ2h0PSI2NjAiIGZpbGw9Im5vbmUiIHZpZXdCb3g9Ijg5IDc2IDY3MiA2NzIiPjxnIHN0cm9rZT0iI2YxNWEyNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTQwMyAyMzAgMTA0LjUgNTg1LjUiLz48Y2lyY2xlIGN4PSIxODAuMjE2IiBjeT0iMzA5LjcxNiIgcj0iNjEuNjE0IiBzdHJva2Utd2lkdGg9IjUwLjIwNCIvPjxjaXJjbGUgY3g9IjMyNi4yNjUiIGN5PSI1MDUuOTciIHI9IjYxLjYxNCIgc3Ryb2tlLXdpZHRoPSI1MC4yMDQiLz48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTczOS42NDUgNTc2LjYxSDUyNi40ODYiLz48L2c+PC9zdmc+PHN0eWxlPkBtZWRpYSAocHJlZmVycy1jb2xvci1zY2hlbWU6bGlnaHQpezpyb290e2ZpbHRlcjpub25lfX08L3N0eWxlPjwvc3ZnPg==&logoColor=FFFFFF&label=)

dotfiles powered by [chezmoi](https://www.chezmoi.io/)

---

<!--toc:start-->

- [Synopsis](#synopsis)
- [Notes](#notes)
  - [Zsh: order of executions](#zsh-order-of-executions)
  - [Zsh: diagnosing the slow start](#zsh-diagnosing-the-slow-start)
  - [Zsh: manage binaries with zinit and z-a-linkbin](#zsh-manage-binaries-with-zinit-and-z-a-linkbin)

<!--toc:end-->

## Synopsis

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Go, Lua, NodeJS, and Python runtimes used by Neovim are managed by asdf (asdf itself is installed at the first time zsh starts), and it is not automated by Zinit.

Deno and Rust runtimes are taken cared by `~/.zshenv`.

1. Install the dependencies

- macOS

```bash
brew install gpg gawk openssl readline sqlite3 xz zlib tcl-tk
```

- Debian

```bash
sudo apt install -y dirmngr gpg curl gawk build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev linux-headers-$(uname -r)
```

2. Install Go, Lua (with LuaRocks), NodeJS, and Python via asdf

```bash
for i in golang lua nodejs, python; do
    IFS=","; set -- $i;
    lang=$1; repo=$2
    asdf plugin-add $lang $repo && \
        asdf install $lang latest && \
        asdf global $lang latest;
done
```

3. Install the neovim module for Python

```bash
pip install --upgrade pip && pip install neovim
```

## Notes

### Zsh: order of executions

The setup loads in the order of

```
$HOME/.zshenv → $HOME/.config/zsh/.zshrc → $ZDOTDIR/rc.d/**
```

while the default is

```
.zshenv → .zprofile → .zshrc → .zlogin → .zlogout
```

1. `.zshenv` is always sourced.
   It often contains exported variables that should be available to other programs.
   For example, `$PATH`, `$EDITOR`, and `$PAGER` are often set in `.zshenv`.
   Also, you can set `$ZDOTDIR` in `.zshenv` to specify an alternative location for the rest of your zsh configuration.
2. `.zprofile` is for login shells.
   It is basically the same as `.zlogin` except that it's sourced before `.zshrc` whereas `.zlogin` is sourced after `.zshrc`.
   According to the zsh documentation, "`.zprofile` is meant as an alternative to `.zlogin` for ksh fans; the two are not intended to be used together, although this could certainly be done if desired."
3. `.zshrc` is for interactive shells.
   You set options for the interactive shell there with the setopt and unsetopt commands.
   You can also load shell modules, set your history options, change your prompt, set up zle and completion, et cetera.
   You also set any variables that are only used in the interactive shell (e.g. `$LS_COLORS`).
4. `.zlogin` is for login shells.
   It is sourced on the start of a login shell but after `.zshrc`, if the shell is also interactive.
   This file is often used to start X using startx.
   Some systems start X on boot, so this file is not always very useful.
5. `.zlogout` is sometimes used to clear and reset the terminal.
   It is called when exiting, not when opening.

`~/.profile` is only loaded when running zsh in sh compatibility mode, otherwise it reads `.zprofile`, as well as `.zshrc` for interactive and `.zlogin` for login shells.

cf. [What should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?](https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout)

### Zsh: diagnosing the slow start

Sometimes there are "bugs" hard to identify during the startup process, and they might cause inconsistent behaviors that are hard to be logged.

In addition to the `$ZPROF` environmental value set before starting zsh, also make use of `${ENABLE_ZPROFTIME}`.

When you start zsh with `${ENABLE_ZPROFTIME}`, it writes out a log to `/tmp/zproftime.XXXX` and can be examined with the autoloaded function (for example):

```console
zproftime-sort /tmp/zproftime.* | head
```

cf. [How to profile your zsh startup time by Benjamin Esham](https://esham.io/2018/02/zsh-profiling)

### Zsh: manage binaries with zinit and z-a-linkbin

[Zinit](https://github.com/zdharma-continuum/zinit) automatically downloads some binaries and creates links in `$ZPFX/bin` (i.e., `~/.local/share/zinit/polaris/bin`) with the [zinit-annex-binary-symlink](https://github.com/zdharma-continuum/zinit-annex-binary-symlink).

See the config file at https://github.com/iomz/dotfiles/blob/main/dot_config/zsh/rc.d/03-polaris.zsh
