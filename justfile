# Show available recipes by default
default:
	@just --list

# Symlink dotfiles to home directory
[group('stow')]
link:
    @repo_root="$(pwd)"; \
    config_target="$HOME/.config"; \
    repo_config="$repo_root/.config"; \
    if [ -L "$config_target" ]; then \
    link_target="$(readlink "$config_target")"; \
    case "$link_target" in \
    /*) resolved_target="$link_target" ;; \
    *) resolved_target="$(cd "$(dirname "$config_target")" && cd "$(dirname "$link_target")" && pwd -P)/$(basename "$link_target")" ;; \
    esac; \
    if [ "$resolved_target" = "$repo_config" ]; then \
    rm "$config_target"; \
    fi; \
    fi; \
    mkdir -p "$config_target"; \
    stow --restow --adopt --no-folding --target="$HOME" .

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
    ./bin/bun-sync

# Restore global skills declared in the tracked manifest.
[group('skills')]
skills-sync:
    bun ./bin/skills-sync.ts .agents/skills.json

# Verify shell config, Brewfile dependencies, and whitespace
[group('check')]
check:
    @zsh -n .zshrc .config/zsh/*.zsh
    @brew bundle check --file=Brewfile
    @git diff --check
    @echo "✓ Checks passed"

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

# Snapshot user-scope MCP servers from live configs into the repo
[group('mcp')]
claude-dump:
    mkdir -p .claude
    jq '.mcpServers // {}' ~/.claude.json > .claude/mcp-servers.json

[group('mcp')]
codex-dump:
    mkdir -p .codex
    awk '/^[ \t]*\[/ { in_mcp = ($0 ~ /^\[mcp_servers[.\]]/) } in_mcp { print }' ~/.codex/config.toml > .codex/mcp-servers.toml

# Restore MCP servers from the repo snapshots (close the respective app first)
[group('mcp')]
claude-restore:
    tmp=$(mktemp); \
    jq --slurpfile mcp .claude/mcp-servers.json '.mcpServers = $mcp[0]' ~/.claude.json > $tmp && \
    mv $tmp ~/.claude.json

[group('mcp')]
codex-restore:
    tmp=$(mktemp); \
    awk '/^[ \t]*\[/ { in_mcp = ($0 ~ /^\[mcp_servers[.\]]/) } !in_mcp { print }' ~/.codex/config.toml > $tmp && \
    printf '\n' >> $tmp && \
    cat .codex/mcp-servers.toml >> $tmp && \
    mv $tmp ~/.codex/config.toml
