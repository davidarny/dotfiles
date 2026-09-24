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
    if [ -n "$(git status --porcelain)" ]; then \
    echo "✗ Commit or stash repo changes first: stow --adopt moves existing home files into the repo" >&2; \
    git status --short --no-branch >&2; exit 1; \
    fi; \
    stow --restow --adopt --no-folding --target="$HOME" . || exit 1; \
    if [ -n "$(git status --porcelain)" ]; then \
    echo "✗ stow --adopt pulled these files from \$HOME into the repo; review with git diff," >&2; \
    echo "  then keep them with a commit or restore the repo version with git checkout -- <file>:" >&2; \
    git status --short --no-branch >&2; exit 1; \
    fi; \
    just _link-dir .config/karabiner

# Link a whole directory for apps that break on per-file symlinks (e.g. Karabiner rewrites its config)
[private]
_link-dir path:
    #!/usr/bin/env zsh
    set -euo pipefail
    source="${PWD:A}/{{path}}"
    target="$HOME/{{path}}"
    [[ "$(readlink "$target" 2>/dev/null)" == "$source" ]] && exit 0
    if [[ -d "$target" && ! -L "$target" ]]; then
      # Replace a directory that holds only per-file symlinks left by stow --no-folding.
      repo_links=() others=()
      for entry in "$target"/*(DN); do
        if [[ -L "$entry" && "${entry:A}" == "$source"/* ]]; then repo_links+=("$entry"); else others+=("${entry:t}"); fi
      done
      if (( ${#others} )); then
        echo "✗ $target has files that are not repo symlinks; move them away and rerun:" >&2
        print -l -- "${others[@]}" >&2
        exit 1
      fi
      for entry in "${repo_links[@]}"; do unlink "$entry"; done
      rmdir "$target"
    elif [[ -e "$target" && ! -L "$target" ]]; then
      echo "✗ $target is a file; move it away and rerun" >&2
      exit 1
    fi
    mkdir -p "${target:h}"
    ln -sfn "$source" "$target"
    echo "✓ Linked ~/{{path}}"

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
    mkdir -p .claude
    jq --arg home "$HOME/" '.mcpServers // {} | walk(if type == "string" then split($home) | join("${HOME}/") else . end)' ~/.claude.json > .claude/mcp-servers.json
    jq --arg home "$HOME/" 'walk(if type == "string" then split($home) | join("${HOME}/") else . end)' ~/.claude/settings.json > .claude/settings.json

[group('mcp')]
codex-dump:
    bun ./bin/codex-config.ts dump ~/.codex/config.toml .codex

# Restore agent settings and MCP servers from the repo snapshots (close the respective app first)
[group('mcp')]
claude-restore:
    mkdir -p ~/.claude
    test -f ~/.claude.json || echo '{}' > ~/.claude.json
    tmp=$(mktemp); \
    jq --arg home "$HOME/" --slurpfile mcp .claude/mcp-servers.json '.mcpServers = ($mcp[0] | walk(if type == "string" then split("${HOME}/") | join($home) else . end))' ~/.claude.json > $tmp && \
    mv $tmp ~/.claude.json
    tmp=$(mktemp); \
    jq --arg home "$HOME/" 'walk(if type == "string" then split("${HOME}/") | join($home) else . end)' .claude/settings.json > $tmp && \
    mv $tmp ~/.claude/settings.json

[group('mcp')]
codex-restore:
    bun ./bin/codex-config.ts restore ~/.codex/config.toml .codex
