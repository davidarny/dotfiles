# Show available recipes by default
default:
	@just --list

# Symlink dotfiles to home directory
[group('stow')]
link:
    @gum confirm "Link dotfiles to $HOME?" || exit 0; \
    repo_root="$(pwd)"; \
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
    gum spin --title "Linking dotfiles" --show-error -- stow --restow --adopt --target="$HOME" .

# Remove dotfiles symlinks from home directory
[group('stow')]
unlink:
    @gum confirm "Remove dotfiles symlinks?" || exit 0; \
    gum spin --title "Removing dotfiles links" --show-error -- stow --delete --target="$HOME" .

# Install packages from Brewfile
[group('brew')]
brew-install:
    @gum spin --title "Installing Brewfile packages" --show-error -- brew bundle --file=Brewfile

# Dump installed packages to Brewfile
[group('brew')]
brew-dump:
    @gum spin --title "Syncing Brewfile" --show-error -- brew bundle dump --file=Brewfile --force --force --brews --casks --taps

# Remove packages not listed in Brewfile
[group('brew')]
brew-cleanup:
    @gum confirm "Remove packages not in Brewfile?" || exit 0; \
    gum spin --title "Removing unmanaged packages" --show-error -- brew bundle cleanup --file=Brewfile --force

# Install Brewfile packages and remove extras
[group('brew')]
brew-sync: brew-install brew-cleanup

# Restore global Bun packages declared in the stowed manifest.
[group('bun')]
bun-sync:
    ./bin/bun-sync

# Restore global skills declared in the stowed lockfile.
[group('skills')]
skills-sync:
    bun ./bin/skills-sync.ts "$HOME/.agents/.skill-lock.json"

# Verify shell config, Brewfile dependencies, and whitespace
[group('check')]
check:
    @gum spin --title "Checking shell syntax" --show-error -- zsh -n .zshrc .config/zsh/*.zsh
    @gum spin --title "Checking Brewfile" --show-error -- brew bundle check --file=Brewfile
    @gum spin --title "Checking whitespace" --show-error -- git diff --check
    @gum style --bold "✓ Checks passed"

# Apply the repo's default macOS file associations
[group('macos')]
file-defaults:
    @gum confirm "Set Zed as the default editor?" || exit 0; \
    ./.config/duti/set-file-defaults.sh
