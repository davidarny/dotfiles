# Recipes may run before the shell is reloaded; put mise-managed runtimes (bun, node)
# and global Bun packages (codegraph) on PATH, as path.zsh does.
export PATH := env("HOME") / ".local/share/mise/shims:" + env("HOME") / ".bun/bin:" + env("PATH")

# Show available recipes by default
default:
	@just --list

# Set up this machine end to end; safe to rerun and stops where it needs you
[group('setup')]
bootstrap: brew-install mise-install link _mcp-secrets-once mcp-launchagent skills-sync bun-sync _agents-closed claude-restore codex-restore pi-restore yazi-plugins file-defaults
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

# Stop before restore while an agent app runs: it would overwrite the restored config
[private]
_agents-closed:
    #!/usr/bin/env zsh
    running=(${(f)"$(ps -axo comm= | awk -F/ '{ print $NF }' | grep -xE 'claude|Claude|codex|Codex|ChatGPT|pi' | sort -u)"})
    if (( ${#running} )); then
      echo "✗ Quit ${(j:, :)running} (including this terminal's agent session), then rerun just bootstrap" >&2
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
    stow --restow --adopt --no-folding --target="$HOME" .
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "✗ stow --adopt pulled these files from \$HOME into the repo; review with git diff," >&2
      echo "  then keep them with a commit or restore the repo version with git checkout -- <file>:" >&2
      git status --short --no-branch >&2
      exit 1
    fi
    # Karabiner rewrites its config and needs the whole directory linked, not single files.
    bun ./bin/link-dir.ts .config/karabiner

# Remove dotfiles symlinks from home directory
[group('stow')]
unlink:
    @stow --delete --target="$HOME" .

# Install packages from Brewfile
[group('brew')]
brew-install:
    @brew bundle --file=Brewfile

# Dump installed packages to Brewfile
[group('brew')]
brew-dump:
    @brew bundle dump --file=Brewfile --force --force --brews --casks --cargo --uv --taps

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

# Verify shell config, Brewfile dependencies, and whitespace
[group('check')]
check:
    @zsh -n .zshrc .config/zsh/*.zsh
    @brew bundle check --file=Brewfile
    @git diff --check
    @echo "✓ Checks passed"

# Install runtimes pinned in the mise config (bun, node, go, ...). Reads the repo copy,
# so it works before just link, which needs bun.
[group('tools')]
mise-install:
    MISE_GLOBAL_CONFIG_FILE=.config/mise/config.toml mise install

# Install yazi plugins pinned in the stowed package.toml
[group('tools')]
yazi-plugins:
    ya pkg install

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
    launchctl bootout gui/$(id -u)/com.davidarutyunyan.mcp-secrets-env 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.davidarutyunyan.mcp-secrets-env.plist

# Snapshot agent settings and user-scope MCP servers into the repo (home paths become ${HOME})
[group('mcp')]
claude-dump:
    @bun ./bin/claude-config.ts dump .claude

[group('mcp')]
codex-dump:
    @bun ./bin/codex-config.ts dump ~/.codex/config.toml .codex

[group('mcp')]
pi-dump:
    @bun ./bin/pi-config.ts dump .pi/agent/settings.json

# Restore agent settings and MCP servers from the repo snapshots (close the respective app first)
[group('mcp')]
claude-restore:
    @bun ./bin/claude-config.ts restore .claude

[group('mcp')]
pi-restore:
    @bun ./bin/pi-config.ts restore .pi/agent/settings.json

[group('mcp')]
codex-restore:
    @bun ./bin/codex-config.ts restore ~/.codex/config.toml .codex
