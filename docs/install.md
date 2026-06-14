# Installation

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Package installation and host-specific setup are handled by chezmoi scripts.

## Package Management Policy

This dotfiles repository splits tools across three layers:

- **apt/brew** manages OS-level bootstrap packages, compiler toolchains, build
  dependencies, and tools that should exist before the shell plugin layer starts.
- **mise** manages pinned development runtimes and developer CLIs that benefit
  from explicit version control.
- **Zinit** manages interactive shell tools distributed as portable GitHub
  release binaries or zsh-oriented integrations.

In practice:

- apt/brew should contain tools such as `git`, `gpg`, `gawk`, `mise`, and build
  dependencies for Python/Ruby/Lua.
- mise should contain tools such as Python, Node.js, Ruby, Go, Lua, Deno, pnpm,
  Poetry, just, and direnv.
- Zinit should contain user-facing interactive CLIs such as bat, delta, fzf,
  ripgrep, ghq, hyperfine, Neovim, chafa, and viu.

Avoid installing the same tool through multiple layers unless there is a clear
bootstrap reason.

## System Dependencies

System dependencies are installed by the chezmoi
`run_once_install-packages.sh.tmpl` script during `chezmoi apply`.

On macOS, Homebrew is used for OS-level dependencies.

On Debian/Ubuntu Linux, apt is used for OS-level dependencies. mise is also
installed through apt where possible.

## Runtime Setup

Development runtimes are managed by mise. The global tool versions are defined in
`.tool-versions`.

After bootstrapping, install the configured runtimes and developer CLIs:

```zsh
mise install
```

Verify the runtime environment:

```zsh
mise doctor
mise current
```

Check for outdated tools:

```zsh
mise outdated
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

## Shell Tools

Interactive shell tools are managed by Zinit when they are primarily user-facing
CLI tools or zsh integrations.

Examples include fzf, bat, delta, ripgrep, ghq, hyperfine, Neovim, chafa, and
viu.

These tools are intentionally kept out of apt/brew unless they are required for
bootstrap or OS integration.

## Font

MesloLGS Nerd Font is borrowed from
[romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for
macOS.

```zsh
install-meslo-nerd-font
```