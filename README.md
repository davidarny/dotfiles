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

Run `just bootstrap` from a plain terminal with Claude, Codex, and Pi closed, because it restores their settings. It installs the Brewfile and the mise runtimes, links the dotfiles, resolves secrets from 1Password, installs skills, Bun packages, and yazi plugins, restores agent settings, and sets file associations. When a step needs you, it stops with a hint. Do what it says and run it again. Repeated runs change nothing that is already in place. tmux installs its plugins the first time it starts.

`just doctor` checks the result without changing anything. Restart the terminal and the agent apps afterwards so they pick up the secrets.

If `just link` stops because stow adopted files from `$HOME` (a default `~/.zshrc`, for example), inspect them with `git diff` and restore the repository version with `git checkout -- <file>`.

## Change the configuration

Edit files in `~/.dotfiles`. Most files in `$HOME` are symlinks, so edits in either place show up in git. Two groups of files are copies instead:

- Claude Code, Codex, and Pi settings live in `.claude/`, `.codex/`, and `.pi/agent/settings.json` as snapshots. After changing them in the app, run `just claude-dump`, `just codex-dump`, or `just pi-dump`. The matching `*-restore` recipe writes them back; close the app first. Effort and model choices stay on each machine.
- MCP servers for all four agents are defined in `mcp/servers.toml`. After editing it, run `just mcp-sync`, then `just claude-restore` and `just codex-restore`. OpenCode and Pi read their generated files through the symlinks.
- Skills written here live in `.agents/skills/<name>/`. Skills from other repositories are listed in `.agents/skills.json`. `just skills-sync` installs and links both.

The `brew` and `skills` shell functions update the Brewfile and `.agents/skills.json` after every install or removal.

To add a new config file, put it at the same path it has under `$HOME` and run `just link`.

Run `just check` before committing.

## Secrets

Secrets never enter the repository. `.config/mcp/mcp-secrets.env.tpl` holds `op://` references to 1Password items. `just mcp-secrets` resolves them into `~/.config/mcp/mcp-secrets.env`, which zsh loads at startup. A LaunchAgent exports the same variables to apps started from the Dock. Configs refer to the variables by name. To add or rotate a secret, edit the template and run `just mcp-secrets` again.

## Remove

`just unlink` removes the symlinks. Installed packages and copied agent settings stay in place.
