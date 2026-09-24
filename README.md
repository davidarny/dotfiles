# dotfiles

Configuration for macOS on Apple Silicon. The repository root mirrors `$HOME`, and [GNU stow](https://www.gnu.org/software/stow/) symlinks it into place. [just](https://github.com/casey/just) runs the setup and maintenance tasks. Run `just --list` to see all of them.

## Set up a new machine

Install these by hand first:

- Command Line Tools: `xcode-select --install`
- [Homebrew](https://brew.sh), then `brew install just gh`
- [1Password](https://1password.com/downloads/mac). Sign in and enable two options under Settings, Developer: "Integrate with 1Password CLI" and "Use the SSH agent".
- [Zed](https://zed.dev). `just file-defaults` makes it the default editor for text files.

The Brewfile lists command line tools only. Desktop apps are installed by hand.

The repository is private, and SSH does not work until the dotfiles are linked. Clone it over HTTPS with `gh`:

```sh
gh auth login
gh repo clone davidarny/dotfiles ~/.dotfiles
cd ~/.dotfiles
just bootstrap
just doctor
```

Run `just bootstrap` from a plain terminal with Claude, Codex, and Pi closed, because it restores their settings. It installs the Brewfile and the mise runtimes, links the dotfiles, resolves secrets from 1Password, installs skills, Bun packages, and yazi plugins, restores agent settings, sets file associations, and applies the macOS settings. When a step needs you, it stops with a hint. Do what it says and run it again. Repeated runs install what is missing and upgrade nothing; `just upgrade` does upgrades. tmux installs its plugins the first time it starts. If writing the Safari or Accessibility settings fails, give the terminal Full Disk Access in System Settings, Privacy & Security, and run `just macos`.

`just doctor` checks the result without changing anything. Restart the terminal and the agent apps afterwards so they pick up the secrets.

If `just link` stops because stow adopted files from `$HOME` (a `~/.zprofile` from the Homebrew installer, for example), it saves copies of them under `~/.cache/dotfiles/adopted/` first. Inspect them with `git diff` and restore the repository version with `git checkout -- <file>`. It also refuses to link files git does not track, such as a stray secrets file in the repo.

## Change the configuration

Edit files in `~/.dotfiles`. Most files in `$HOME` are symlinks, so edits in either place show up in git. Two groups of files are copies instead:

- Claude Code, Codex, and Pi settings live in `.claude/`, `.codex/`, and `.pi/agent/settings.json` as snapshots. After changing them in the app, run `just claude-dump`, `just codex-dump`, or `just pi-dump`. The matching `*-restore` recipe writes them back; close the app first. Effort and model choices stay on each machine.
- MCP servers for all four agents are defined in `mcp/servers.toml`. After editing it, run `just mcp-sync`, then `just mcp-restore` with Claude and Codex closed. OpenCode and Pi read their generated files through the symlinks. Server packages are pinned; `just mcp-upgrade` moves them to the latest releases.
- macOS settings live in `macos/defaults.toml` as `defaults` keys; `just macos` applies them and `just doctor` reports drift. macOS ignores symlinked preference files, so they are written key by key. To find the key behind a control, run `just macos-diff`, change the setting in System Settings, run `just macos-diff` again, and paste the printed lines into the file.
- Skills written here live in `.agents/skills/<name>/`. Skills from other repositories are listed in `.agents/skills.json`. `just skills-sync` installs and links both.

The `brew` and `skills` shell functions update the Brewfile and `.agents/skills.json` after every install or removal.

To add a new config file, put it at the same path it has under `$HOME` and run `just link`.

`just upgrade` updates Homebrew, mise runtimes, Bun and uv tools, skills, Pi, and the tmux, yazi, and Neovim plugins, one step after another; `just upgrade-brew` and the other `upgrade-*` recipes run a single step. The `dot` alias runs any recipe from another directory, for example `dot upgrade`.

Run `just check` before committing.

## Secrets

Secrets never enter the repository. `.config/mcp/mcp-secrets.env.tpl` holds `op://` references to 1Password items. `just mcp-secrets` resolves them into `~/.config/mcp/mcp-secrets.env`, which zsh loads at startup. A LaunchAgent exports the same variables to apps started from the Dock. Configs refer to the variables by name. To add or rotate a secret, edit the template and run `just mcp-secrets` again.

## Remove

`just unlink` removes the symlinks. Installed packages and copied agent settings stay in place.
