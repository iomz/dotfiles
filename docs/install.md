# Installation

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Package installation and host-specific setup are handled by chezmoi scripts.

## Package Management Policy

This dotfiles repository splits tools across three layers:

- **apt/brew** manages OS-level bootstrap packages, compiler toolchains, build dependencies, and tools that should exist before the shell plugin layer starts.
- **mise** manages pinned development runtimes and developer CLIs that benefit from explicit version control.
- **Zinit** manages interactive shell tools distributed as portable GitHub release binaries or zsh-oriented integrations.

In practice:

- `apt`/`brew` should contain tools such as `git`, `gpg`, `gawk`, `mise`, and build dependencies for Python, Ruby, and Lua.
- `mise` should contain tools such as Python, Node.js, Ruby, Go, Lua, Deno, `pnpm`, `Poetry`, `just`, and `direnv`.
- `zinit` should contain user-facing interactive CLIs such as `bat`, `delta`, `fzf`, `ripgrep`, `ghq`, `hyperfine`, and `viu`.

Avoid installing the same tool through multiple layers unless there is a clear bootstrap reason.

## System Dependencies

System dependencies are installed by the chezmoi `run_once_install-packages.sh.tmpl` script during `chezmoi apply`.

On macOS, Homebrew is used for OS-level dependencies.

On Debian/Ubuntu Linux, apt is used for OS-level dependencies. mise is also installed through apt where possible.

## Runtime Setup

Development runtimes are managed by mise. Global tool versions are defined in `~/.config/mise/config.toml`.

After bootstrapping, install the configured runtimes and developer CLIs:

```zsh
mise install
mise reshim
```

Run `mise reshim` after installing or changing tools so newly managed CLIs are available through mise shims. The chezmoi `run_onchange_after_mise-install.sh.tmpl` script also runs these commands when the mise configuration changes.

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

Neovim is managed by mise together with other developer tools.

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

Interactive shell tools are managed by Zinit when they are primarily user-facing CLI tools or zsh integrations.

Examples include fzf, bat, delta, ripgrep, ghq, hyperfine, viu, and other standalone CLI utilities distributed through GitHub releases.

These tools are intentionally kept out of apt/brew unless they are required for bootstrap or OS integration.

## Font

On macOS, MesloLGS NF fonts are installed into the user font directory by the chezmoi `run_once_install-meslo-nerd-fonts.sh.tmpl` script during the first `chezmoi apply`.

Only the font files are installed. Terminal application font selection is managed manually.

## WakaTime

WakaTime is intentionally not managed by chezmoi because its API key is a
machine-local secret and should not make `chezmoi apply` depend on a password
manager session.

Configure it manually on machines where WakaTime is used:

```zsh
wakatime --api-key
```
