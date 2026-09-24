# Recipes may run before the shell is reloaded; put mise-managed runtimes (bun, node)
# and global Bun packages (codegraph) on PATH, as path.zsh does.
export PATH := env("HOME") / ".local/share/mise/shims:" + env("HOME") / ".bun/bin:" + env("PATH")

# Show available recipes by default
default:
	@just --list

# Set up this machine end to end; safe to rerun and stops where it needs you
[group('setup')]
bootstrap: brew-install mise-install link _mcp-secrets-once mcp-launchagent skills-sync bun-sync claude-restore codex-restore pi-restore yazi-plugins bat-cache file-defaults macos
    @echo "✓ Bootstrap done. tmux installs TPM and its plugins on first start; run just doctor to verify."

# Read-only report of links, secrets, packages, MCP commands, skills, and plugins
[group('setup')]
doctor:
    @bun ./bin/doctor.ts

# Resolve MCP secrets unless they already exist (each run costs a 1Password prompt)
[private]
_mcp-secrets-once:
    #!/usr/bin/env zsh
    if [[ -s ~/.config/mcp/mcp-secrets.env ]]; then
      echo "✓ ~/.config/mcp/mcp-secrets.env exists; run just mcp-secrets to refresh it"
    elif ! just mcp-secrets; then
      echo "✗ Sign in to the 1Password app, enable Settings → Developer → Integrate with 1Password CLI, then rerun just bootstrap" >&2
      exit 1
    fi

# Stop before a restore while one of the given agents (claude, codex, pi) runs: it would overwrite the restored config
[private]
_closed +agents:
    #!/usr/bin/env zsh
    set -euo pipefail
    names=(${(f)"$(ps -axo comm= | awk -F/ '{ print $NF }')"})
    running=()
    for agent in {{agents}}; do
      case $agent in
        claude) (( ${names[(Ie)claude]} || ${names[(Ie)Claude]} )) && running+=Claude ;;
        codex) (( ${names[(Ie)codex]} || ${names[(Ie)Codex]} || ${names[(Ie)ChatGPT]} )) && running+=Codex ;;
        # Pi runs on node but renames its process to pi.
        pi) (( ${names[(Ie)pi]} )) && running+=Pi ;;
      esac
    done
    if (( ${#running} )); then
      echo "✗ Quit ${(j:, :)running} (including this terminal's agent session), then rerun" >&2
      exit 1
    fi

# Symlink dotfiles to home directory
[group('stow')]
link:
    #!/usr/bin/env zsh
    set -euo pipefail
    # stow --adopt moves existing home files into the repo; start clean so git shows exactly what it took.
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "✗ Commit or stash repo changes first: stow --adopt moves existing home files into the repo" >&2
      git status --short --no-branch >&2
      exit 1
    fi
    # git status hides ignored files, which stow would link (and adopt) too: a secrets file, a tool's local
    # config. Link only files git tracks.
    tracked=(${(f)"$(git ls-files)"})
    untracked=()
    for target in ${(f)"$(stow --no --verbose --restow --no-folding --target="$HOME" . 2>&1 | sed -nE 's/^LINK: (.*) => .*$/\1/p')"}; do
      (( ${tracked[(Ie)$target]} )) || untracked+=$target
    done
    if (( ${#untracked} )); then
      echo "✗ These repo files are not tracked by git; move them out or add them to .stow-local-ignore:" >&2
      print -l -- "  "${^untracked} >&2
      exit 1
    fi
    # stow would create a missing ~/.ssh readable by others; ssh wants it private.
    [[ -d "$HOME/.ssh" ]] || mkdir -m 700 "$HOME/.ssh"
    stow --restow --adopt --no-folding --target="$HOME" .
    if [[ -n "$(git status --porcelain)" ]]; then
      # Keep what stow took from $HOME: restoring the repo version with git checkout would otherwise delete it.
      backup="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/adopted/$(date +%Y%m%d-%H%M%S)"
      for file in ${(f)"$(git diff --name-only)"}; do
        mkdir -p "$backup/${file:h}"
        cp -p "$file" "$backup/$file"
      done
      echo "✗ stow --adopt moved these home files into the repo; copies are in $backup." >&2
      echo "  Review with git diff, then commit them or restore the repo version with git checkout -- <file>:" >&2
      git status --short --no-branch >&2
      exit 1
    fi
    # Karabiner and Zed replace their config files, so their directories are linked whole.
    bun ./bin/link-dirs.ts

# Remove dotfiles symlinks from home directory
[group('stow')]
unlink:
    @stow --delete --target="$HOME" .

# Install packages from Brewfile
[group('brew')]
brew-install:
    @brew bundle --file=Brewfile --no-upgrade

# Dump installed packages to Brewfile
[group('brew')]
brew-dump:
    @brew bundle dump --file=Brewfile --force --brews --casks --cargo --uv --taps

# Remove packages not listed in Brewfile
[group('brew')]
brew-cleanup:
    @brew bundle cleanup --file=Brewfile --force

# Install Brewfile packages and remove extras
[group('brew')]
brew-sync: brew-install brew-cleanup

# Restore global Bun packages declared in the stowed manifest.
[group('bun')]
bun-sync:
    #!/usr/bin/env zsh
    set -euo pipefail
    packages=(${(f)"$(jq -r '.dependencies // {} | to_entries[] | "\(.key)@\(.value)"' ~/.bun/install/global/package.json)"})
    (( ${#packages} )) || exit 0
    bun install --global "${packages[@]}"
    echo "✓ Synced ${#packages} global Bun packages"

# Restore global skills declared in the tracked manifest.
[group('skills')]
skills-sync:
    @bun ./bin/skills-sync.ts .agents/skills.json

# Verify shell config, Brewfile dependencies, generated MCP configs, bin/ scripts, and whitespace
[group('check')]
check:
    @just _check-shell
    @brew bundle check --no-upgrade --file=Brewfile
    @bun ./bin/mcp-sync.ts --check
    @bun install --cwd bin/typecheck --frozen-lockfile --silent
    @bin/typecheck/node_modules/.bin/tsc -p bin/typecheck
    @bun test ./bin
    @git diff --check
    @echo "✓ Checks passed"

# Parse every shell file with the shell its shebang names (zsh -n reads only its first file argument)
[private]
_check-shell:
    #!/usr/bin/env zsh
    set -euo pipefail
    for file in .zshenv .zprofile .zshrc .config/zsh/*.zsh .config/zsh/agent/zsh .local/bin/* ${(f)"$(git ls-files '*.sh')"}; do
      case "$(head -1 "$file")" in
        *bash*) bash -n "$file" ;;
        '#!/bin/sh'*|*' sh') sh -n "$file" ;;
        *) zsh -n "$file" ;;
      esac
    done

# mise, yazi, and Neovim record the new versions in the repo, so review git diff afterwards.
# Upgrade every tool, one step after another
[group('upgrade')]
upgrade: upgrade-brew bat-cache upgrade-mise upgrade-bun upgrade-uv upgrade-skills upgrade-pi upgrade-plugins
    @echo "✓ Upgraded. Review git diff for version bumps in mise, yazi, and Neovim."

# Upgrade Homebrew formulae and casks, then remove old versions and unused dependencies
[group('upgrade')]
upgrade-brew:
    brew update
    brew upgrade --greedy-latest
    brew cleanup --prune=all
    brew autoremove

# Upgrade mise runtimes and bump their pins in .config/mise/config.toml
[group('upgrade')]
upgrade-mise:
    mise upgrade --yes --bump

# Upgrade global Bun packages to their latest releases
[group('upgrade')]
upgrade-bun:
    bun update --global --latest
    bun pm trust --all --global

# Upgrade tools installed with uv
[group('upgrade')]
upgrade-uv:
    uv tool upgrade --all

# Upgrade external skills from their source repositories
[group('upgrade')]
upgrade-skills:
    skills update --global --yes

# Upgrade Pi packages and extensions
[group('upgrade')]
upgrade-pi:
    pi update
    pi update --extensions

# Upgrade tmux, zsh, yazi, and Neovim plugins
[group('upgrade')]
upgrade-plugins:
    # tmux installs TPM on its first start; skip it until then.
    if [ -x ~/.tmux/plugins/tpm/bin/update_plugins ]; then ~/.tmux/plugins/tpm/bin/update_plugins all; fi
    # antidote is a zsh function; ANTIDOTE_HOME matches plugins.zsh. Homebrew updates antidote itself.
    ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/antidote" zsh -c 'source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh && antidote update --bundles'
    ya pkg upgrade
    nvim --headless "+Lazy! sync" +qa

# Reads the repo copy of the mise config, so it works before just link, which needs bun.
# Install runtimes pinned in the mise config (bun, node, go, ...)
[group('tools')]
mise-install:
    MISE_GLOBAL_CONFIG_FILE=.config/mise/config.toml mise install

# Install yazi plugins pinned in the stowed package.toml
[group('tools')]
yazi-plugins:
    ya pkg install

# bat reads custom themes only from its cache, and a new bat release refuses a cache built by the old one.
# Build bat's cache of the stowed themes
[group('tools')]
bat-cache:
    bat cache --build

# Apply the macOS settings in macos/defaults.toml and restart what reads them
[group('macos')]
macos:
    @bun ./bin/macos-defaults.ts apply

# List macOS settings that differ from macos/defaults.toml
[group('macos')]
macos-check:
    @bun ./bin/macos-defaults.ts check

# Find the keys behind a System Settings control: run, change the setting, run again
[group('macos')]
macos-diff:
    @bun ./bin/macos-defaults.ts diff

# Apply the repo's default macOS file associations
[group('macos')]
file-defaults:
    @./.config/duti/set-file-defaults.sh

# Resolve 1Password secret references into the sourced MCP env file
[group('mcp')]
mcp-secrets:
    op inject --force --in-file .config/mcp/mcp-secrets.env.tpl --out-file "$HOME/.config/mcp/mcp-secrets.env"
    chmod 600 "$HOME/.config/mcp/mcp-secrets.env"
    .local/bin/mcp-secrets-launchctl

# Load the login agent that publishes MCP secrets to GUI apps (run after just link)
[group('mcp')]
mcp-launchagent:
    launchctl bootout gui/$(id -u)/local.dotfiles.mcp-secrets-env 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.dotfiles.mcp-secrets-env.plist

# Write every agent's MCP config from mcp/servers.toml; then run just mcp-restore
[group('mcp')]
mcp-sync:
    @bun ./bin/mcp-sync.ts

# Install the generated MCP servers into Claude Code and Codex, leaving their other settings alone
[group('mcp')]
mcp-restore: (_closed "claude" "codex")
    @bun ./bin/claude-config.ts restore-mcp .claude
    @bun ./bin/codex-config.ts restore-mcp ~/.codex/config.toml .codex

# List MCP server packages in mcp/servers.toml with a newer release
[group('mcp')]
mcp-outdated:
    @bun ./bin/mcp-packages.ts outdated

# Pin every MCP server package to its latest release and regenerate the agent configs
[group('mcp')]
mcp-upgrade:
    @bun ./bin/mcp-packages.ts upgrade
    @bun ./bin/mcp-sync.ts
    @echo "Review git diff, then run just mcp-restore"

# Snapshot Claude Code settings into the repo (home paths become ${HOME}); MCP servers live in mcp/servers.toml
[group('mcp')]
claude-dump:
    @bun ./bin/claude-config.ts dump .claude

# Snapshot Codex settings into the repo; MCP servers live in mcp/servers.toml
[group('mcp')]
codex-dump:
    @bun ./bin/codex-config.ts dump ~/.codex/config.toml .codex

# Snapshot Pi settings into the repo
[group('mcp')]
pi-dump:
    @bun ./bin/pi-config.ts dump .pi/agent/settings.json

# Replace live Claude Code settings and MCP servers with the repo snapshots; Claude must be closed
[group('mcp')]
claude-restore: (_closed "claude")
    @bun ./bin/claude-config.ts restore .claude

# Replace live Pi settings with the repo snapshot; Pi must be closed
[group('mcp')]
pi-restore: (_closed "pi")
    @bun ./bin/pi-config.ts restore .pi/agent/settings.json

# Replace live Codex settings and MCP servers with the repo snapshots; Codex must be closed
[group('mcp')]
codex-restore: (_closed "codex")
    @bun ./bin/codex-config.ts restore ~/.codex/config.toml .codex
