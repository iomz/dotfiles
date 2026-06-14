# Installation

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Package installation and host-specific setup are handled by chezmoi scripts.

## Runtime Setup

Install system dependencies with:

```zsh
run_once_install-packages.sh.tmpl
```

Development runtimes are managed by mise. The global tool versions are defined in
`.tool-versions`.

After bootstrapping, install the configured runtimes:

```zsh
mise install
```

Verify the runtime environment:

```zsh
mise doctor
mise current
```

## Neovim Providers

Neovim uses mise-managed Python and Ruby providers.

Install Python provider support:

```zsh
python3 -m pip install --upgrade pip pynvim
```

Install Ruby provider support:

```zsh
gem install neovim
```

Verify providers from Neovim:

```zsh
nvim +'checkhealth provider' +qa
```

## Optional Tools

Additional CLI tools such as pnpm, Poetry, and Lua are managed by mise when they
are listed in `.tool-versions`.

Install or update all configured tools with:

```zsh
mise install
```

Check for outdated tools:

```zsh
mise outdated
```

## Font

MesloLGS Nerd Font is borrowed from
[romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for
macOS.

```zsh
install-meslo-nerd-font
```