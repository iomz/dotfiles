# dotfiles powered by [chezmoi](https://www.chezmoi.io/)

<!--toc:start-->

- [synopsis](#synopsis)
- [memo](#memo)
  - [zsh: order of executions](#zsh-order-of-executions)

<!--toc:end-->

# synopsis

```console
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

# memo

## zsh: order of executions

My setup loads

```
$HOME/.zshenv → $HOME/.config/zsh/.zshrc → $ZDOTDIR/rc.d/**
```

while the default is

```
.zshenv → .zprofile → .zshrc → .zlogin → .zlogout
```

cf. What should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?

- https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout

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
