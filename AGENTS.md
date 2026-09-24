# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

macOS dotfiles managed with **GNU stow**. All config files live in this repo and are symlinked into `$HOME` via stow.

## Commands

```bash
just bootstrap     # full, rerunnable setup: brew, link, secrets, skills, bun, agent configs, plugins
just doctor        # read-only health report of the setup
just link          # stow --restow --adopt --no-folding --target="$HOME" . (refuses a dirty tree)
just unlink        # stow --delete --target="$HOME" .
just brew-install  # brew bundle --file=Brewfile
just brew-dump     # brew bundle dump to Brewfile
just check         # zsh syntax, Brewfile, and whitespace checks
source ~/.zshrc    # reload shell after changes
```

No tests or linting — this is a shell configuration repo.

## How Stow Works Here

The repo root mirrors `$HOME`. Running `just link` symlinks everything (except files in `.stow-local-ignore`) into the home directory. For example, `.config/zsh/aliases.zsh` becomes `~/.config/zsh/aliases.zsh`.

Files excluded from stow: `.git`, `.gitignore`, `AGENTS.md`, `Brewfile`, `CLAUDE.md`, `LICENSE.md`, `README.md`, `justfile`, `.DS_Store`.

## Architecture

### ZSH Configuration (Modular)

`.zshrc` sources 10 modules from `~/.config/zsh/` in a specific order:

1. **env.zsh** — Environment variables (`EDITOR=nvim`, `PAGER=bat`, 1Password SSH, XDG)
2. **options.zsh** — Shell options
3. **path.zsh** — PATH additions (bun, pyenv, Java)
4. **history.zsh** — History settings
5. **plugins.zsh** — Antidote plugin manager; plugin lists live in `.config/antidote/`
6. **completions.zsh** — Completion system
7. **fzf.zsh** — FZF configuration and theme
8. **aliases.zsh** — Shell aliases
9. **functions.zsh** — Custom functions (`brew` wrapper for auto-syncing Brewfile, `tm` for tmux)
10. **tools.zsh** — Tool initialization via `eval` (fzf, zoxide, starship, pyenv)

**Order matters** — plugins.zsh must load before completions.zsh, and tools.zsh comes last to initialize tools after plugins are loaded.

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

`.config/tmux/tmux.conf` — TPM-managed plugins, vim-style navigation, and Tokyo Night status styling.

## Conventions

- **Tokyo Night theme** is applied consistently across all tools (ghostty, neovim, tmux, fzf, bat, eza, lazygit, starship).
- **Guard all tool usage** with `command -v <tool> >/dev/null 2>&1` before referencing it.
- **SSH uses 1Password agent** — `SSH_AUTH_SOCK` points to `~/.1password/agent.sock`.
- **Run `just check` before committing shell/config changes**.
- **Use Conventional Commits for every commit** — format commit messages like `feat: ...`, `fix: ...`, `chore: ...`, `docs: ...`, etc. Do not create non-conventional commit messages.
- **Do not add documentation to the repository unless the user explicitly requests it.**

## Secrets

The repo is private, but git history outlives any access setting — never commit plaintext API keys or tokens. Agent/MCP secrets flow through 1Password:

- `.config/mcp/mcp-secrets.env.tpl` (tracked) holds the `op://` references; `just mcp-secrets` resolves them into `~/.config/mcp/mcp-secrets.env` (gitignored, `chmod 600`, one TouchID prompt), which `env.zsh` sources on shell startup.
- GUI apps (Claude desktop from Dock or login) do not read zsh files: the `com.davidarutyunyan.mcp-secrets-env` LaunchAgent runs `~/.local/bin/mcp-secrets-launchctl` at login to `launchctl setenv` every exported variable; `just mcp-secrets` reruns it. Enable once with `just link && just mcp-launchagent`; restart an app to pick up new values.
- Configs reference variables, not values: `${VAR}` in Pi `mcp.json` (`~/.pi/agent/mcp.json`, `~/.agents/mcp.json`), `{env:VAR}` in OpenCode config.
- Adding or rotating a secret: update the reference in the template, run `just mcp-secrets`. If a config fails auth with an empty variable, the generated file is stale or missing — regenerate it there; never paste the secret value into the config.

## Skills

- External skills: `.agents/skills.json` maps each name to its `owner/repo` source; `just skills-sync` installs them with the Skills CLI.
- Locally authored skills live in `.agents/skills/<name>/` (not stowed). `just skills-sync` links `~/.agents/skills/<name>` to the repo directory and adds the four harness symlinks, so edits land in git. Create new local skills here.

## Adding New Configuration

1. Place files in the repo mirroring their `$HOME` location (e.g., `.config/toolname/config`)
2. Run `just link` to create the symlink
3. If adding a new ZSH module, source it from `.zshrc` in the appropriate position
