# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

macOS dotfiles managed with **GNU stow**. All config files live in this repo and are symlinked into `$HOME` via stow.

## Commands

```bash
just link      # stow --restow --adopt --target="$HOME" .
just unlink    # stow --delete --target="$HOME" .
source ~/.zshrc  # reload shell after changes
```

No tests or linting — this is a shell configuration repo.

## How Stow Works Here

The repo root mirrors `$HOME`. Running `just link` symlinks everything (except files in `.stow-local-ignore`) into the home directory. For example, `.config/zsh/aliases.zsh` becomes `~/.config/zsh/aliases.zsh`.

Files excluded from stow: `.git`, `.gitignore`, `LICENSE.md`, `README.md`, `justfile`, `.DS_Store`.

## Architecture

### ZSH Configuration (Modular)

`.zshrc` sources 12 modules from `~/.config/zsh/` in a specific order:

1. **env.zsh** — Environment variables (`EDITOR=nvim`, `PAGER=bat`, 1Password SSH, XDG)
2. **options.zsh** — Shell options
3. **path.zsh** — PATH additions (fnm, bun, pnpm, pyenv, Java)
4. **history.zsh** — History settings
5. **plugins.zsh** — Zinit plugin manager and all ZSH plugins
6. **completions.zsh** — Completion system
7. **fzf.zsh** — FZF configuration and theme
8. **keybindings.zsh** — Key bindings
9. **aliases.zsh** — Shell aliases
10. **functions.zsh** — Custom functions (e.g., `tm` for tmux)
11. **hooks.zsh** — Preexec/precmd hooks (noti notifications for long commands)
12. **tools.zsh** — Tool initialization via `_evalcache` (fzf, zoxide, starship, fnm, pyenv)

**Order matters** — plugins.zsh must load before completions.zsh, and tools.zsh must come last because it depends on `_evalcache` from the Zinit plugins.

### Git Configuration (Modular)

`.gitconfig` uses `[include]` to compose from `~/.config/git/`:
- `core.gitconfig` — Editor, EOL, compression
- `user.gitconfig` — Author identity
- `appearance.gitconfig` — Colors, diff, blame
- `behavior.gitconfig` — Push/pull/rebase/merge
- `tools.gitconfig` — Submodules, tags
- `credentials.gitconfig` — 1Password / gh CLI auth

### Neovim

LazyVim-based config in `.config/nvim/`. Plugin specs in `lua/plugins/`. Uses folke/snacks.nvim for UI and file explorer (neo-tree is disabled).

### Tmux

`.config/tmux/tmux.conf` — TPM-managed plugins, vim-style navigation, tmux-resurrect/continuum for session persistence.

## Conventions

- **Tokyo Night theme** is applied consistently across all tools (ghostty, neovim, tmux, fzf, bat, eza, lazygit, starship).
- **Tool initialization uses `_evalcache`** (from mroth/evalcache zinit plugin) to cache eval output and speed up shell startup. Use `_evalcache <tool> <args>` instead of `eval "$(<tool> <args>)"` in tools.zsh.
- **Guard all tool usage** with `command -v <tool> >/dev/null 2>&1` before referencing it.
- **SSH uses 1Password agent** — `SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.

## Adding New Configuration

1. Place files in the repo mirroring their `$HOME` location (e.g., `.config/toolname/config`)
2. Run `just link` to create the symlink
3. If adding a new ZSH module, source it from `.zshrc` in the appropriate position
