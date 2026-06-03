# Installation

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Go, Lua, NodeJS, and Python runtimes used by Neovim are managed by asdf.
asdf itself is installed on the first zsh startup, and is not automated by
Zinit.

Other runtimes, such as Deno and Rust, are handled in `~/.zshenv`.

## Runtime Setup

Install dependencies with `run_once_install-packages.sh.tmpl`.

Install Go, Lua with LuaRocks, NodeJS, and Python via asdf:

```zsh
for i in golang lua nodejs python; do
    IFS=","; set -- $i;
    lang=$1; repo=$2;
    asdf plugin add $lang $repo && \
        asdf install $lang latest && \
        asdf set -u $lang latest;
done
```

Install Neovim providers:

```zsh
pip install --upgrade pip && pip install neovim
npm i -g neovim
```

Optional tools:

```zsh
for i in pnpm poetry; do
    IFS=","; set -- $i;
    lang=$1; repo=$2;
    asdf plugin add $lang $repo && \
        asdf install $lang latest && \
        asdf set -u $lang latest;
done
```

## Font

MesloLGS Nerd Font is borrowed from
[romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for
macOS.

```zsh
install-meslo-nerd-font
```
