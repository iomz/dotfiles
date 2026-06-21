![Linux](https://img.shields.io/static/v1?style=for-the-badge&message=Linux&color=222222&logo=Linux&logoColor=FCC624&label=)
![macOS](https://img.shields.io/static/v1?style=for-the-badge&message=macOS&color=000000&logo=macOS&logoColor=FFFFFF&label=)
![Neovim](https://img.shields.io/static/v1?style=for-the-badge&message=Neovim&color=57A143&logo=Neovim&logoColor=FFFFFF&label=)
![Zsh](https://img.shields.io/static/v1?style=for-the-badge&message=Zsh&color=224466&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmciIHdpZHRoPSI2NzIiIGhlaWdodD0iNjcyIj48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZyIgd2lkdGg9IjY3MiIgaGVpZ2h0PSI2NjAiIGZpbGw9Im5vbmUiIHZpZXdCb3g9Ijg5IDc2IDY3MiA2NzIiPjxnIHN0cm9rZT0iI2YxNWEyNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTQwMyAyMzAgMTA0LjUgNTg1LjUiLz48Y2lyY2xlIGN4PSIxODAuMjE2IiBjeT0iMzA5LjcxNiIgcj0iNjEuNjE0IiBzdHJva2Utd2lkdGg9IjUwLjIwNCIvPjxjaXJjbGUgY3g9IjMyNi4yNjUiIGN5PSI1MDUuOTciIHI9IjYxLjYxNCIgc3Ryb2tlLXdpZHRoPSI1MC4yMDQiLz48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTczOS42NDUgNTc2LjYxSDUyNi40ODYiLz48L2c+PC9zdmc+PHN0eWxlPkBtZWRpYSAocHJlZmVycy1jb2xvci1zY2hlbWU6bGlnaHQpezpyb290e2ZpbHRlcjpub25lfX08L3N0eWxlPjwvc3ZnPg==&logoColor=FFFFFF&label=)

# dotfiles

Personal dotfiles powered by [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Use `TINY_CHEZMOI=1` for a smaller shell setup.

## Responsibility Split

| Layer | Owns | Source of truth |
|---|---|---|
| apt/brew | OS bootstrap packages, compiler dependencies, and system integration | `run_once_install-packages.sh.tmpl` |
| mise | Pinned development runtimes and developer CLIs | `dot_tool-versions` |
| zinit | Interactive shell tools, portable GitHub release binaries, and zsh integrations | `dot_config/zsh/rc.d/02-plugin-manager.zsh` and `03-tools.zsh` |
| chezmoi | Reproducible dotfiles, templates, and public helper scripts | Managed files in this repository |

Each tool should have one owner. Duplicate installation is reserved for explicit bootstrap requirements.

## Common Operations

| Change | Edit | Apply or verify |
|---|---|---|
| Add OS dependency | `run_once_install-packages.sh.tmpl` | Review script branch for target OS; run package manager manually on existing hosts |
| Add or update runtime/CLI | `dot_tool-versions` | `mise install`, then `mise current` |
| Add interactive shell tool | `dot_config/zsh/rc.d/03-tools.zsh` | Start interactive zsh and verify command resolution |
| Change zsh integration | Relevant numbered file under `dot_config/zsh/rc.d/` | `zsh -n <file>`, then start interactive zsh |
| Change managed dotfile | Corresponding chezmoi source path | `chezmoi diff`, then `chezmoi apply` |
| Add managed file | Target file through `chezmoi add` | Inspect source and `chezmoi diff` before commit |

## Docs

- [Installation](docs/install.md)
- [Chezmoi policy](docs/chezmoi.md)
- [Codex](docs/codex.md)
- [Zsh](docs/zsh.md)
- [Neovim](docs/nvim.md)
- [Ansible](docs/ansible.md)
