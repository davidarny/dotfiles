# AGENTS.md

macOS (Apple Silicon) dotfiles. The repo root mirrors `$HOME`; `just link` runs GNU stow with `--no-folding`, so `$HOME` holds per-file symlinks into the repo. `just --list` shows every task.

## Linking

- `.stow-local-ignore` entries containing `/` are anchored regexes that match repo-root paths only, e.g. `/README\.md$`; entries without `/` match a basename anywhere.
- `just link` requires a clean tree because `stow --adopt` moves existing home files into the repo. When it stops after adopting, inspect `git diff` and restore the repo version with `git checkout -- <file>` unless the user wants the adopted content.
- Apps that replace their config file instead of writing through a symlink (Karabiner, Zed) get the whole directory linked. List such a directory in `DIRECTORY_LINKS` (`bin/lib/paths.ts`) and exclude it in `.stow-local-ignore`.
- `.agents/AGENTS.md` is the global instruction file for Claude, Codex, OpenCode, and Pi; `.claude/CLAUDE.md` and the other harness files are symlinks to it. Edit `.agents/AGENTS.md` itself.

## Copied, not linked

- MCP servers for all four agents are defined only in `mcp/servers.toml`. `just mcp-sync` renders `.claude/mcp-servers.json`, `.codex/mcp-servers.toml`, the `mcp` block of `.config/opencode/opencode.json`, and `.agents/mcp.json` (Pi); never edit those by hand. `just check` fails when they are stale. Write secrets as `${VAR}`; the renderer converts them per agent.
- `.claude/settings.json`, `.codex/settings.toml`, and `.pi/agent/settings.json` are snapshots of live agent settings. The live file is the source: change it, then run `just <agent>-dump`. `just <agent>-restore` writes the snapshot back and needs the app closed. Dumps replace the home prefix with `${HOME}/`; restore expands it. Keys the user toggles often stay machine-local through `LOCAL_KEYS` in `bin/claude-config.ts` and `bin/pi-config.ts`; machine-local Codex tables are listed in `bin/codex-config.ts`.
- Locally authored skills live in `.agents/skills/<name>/`; create new ones there. External skills are listed in `.agents/skills.json`, which the `skills` zsh function updates on add, remove, and update. `just skills-sync` installs and links both into all four harnesses.
- The `brew` zsh function rewrites `Brewfile` after install and uninstall. The Brewfile holds command line tools only; the user installs desktop apps by hand.

## Secrets

The repo is private, and secrets still stay out of it because git history outlives any access setting. `.config/mcp/mcp-secrets.env.tpl` holds `op://` references; `just mcp-secrets` resolves them into the untracked `~/.config/mcp/mcp-secrets.env`, which `env.zsh` sources and a LaunchAgent exports to GUI apps. Configs reference variables by name, never values. For an empty variable or a rotated key, edit the template and rerun `just mcp-secrets`.

## Shell

- `.zshrc` sources `~/.config/zsh/*.zsh` in a fixed order: `plugins.zsh` before `completions.zsh`, `tools.zsh` after both.
- `.zshenv` and `.zprofile` source `aliases.zsh` and `env.zsh` again on purpose: non-interactive agent shells get aliases such as `rf`, and login shells reapply them after `brew shellenv`.
- Guard every external tool with `command -v <tool> >/dev/null 2>&1`.

## Scripts in `bin/`

The justfile orchestrates; logic lives in TypeScript scripts run by Bun, with no dependencies.

- Use Bun APIs (`$`, `Bun.file`, `Bun.which`, `Bun.TOML`, `Bun.argv`, `Bun.env`); use `node:fs` only for symlinks and FIFOs.
- Each script has a `main()` started through `runMain`, which prints a thrown error as one `✗` line.
- Print through `bin/lib/log.ts`, which uses the terminal's ANSI theme colors.
- Share helpers through `bin/lib/`. Module constants are UPPER_CASE, and every function and interface has TSDoc.

## Conventions

- Configs use the Luna theme.
- Commits follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, ...).
- Run `just check` before committing; run `just doctor` after changing linking, snapshots, skills, or plugins.
- Add documentation files only when the user asks for them.
- `.gitignore_global` ignores agent files (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/`, ...) in every repo on purpose: the user keeps AI agent use out of projects where it should not show. Keep these entries.
