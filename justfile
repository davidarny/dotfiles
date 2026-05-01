# Show available recipes by default
default:
	@just --list

# Symlink dotfiles to home directory
[group('stow')]
link:
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
    stow --restow --adopt --target="$HOME" .

# Remove dotfiles symlinks from home directory
[group('stow')]
unlink:
    stow --delete --target="$HOME" .

# Install packages from Brewfile
[group('brew')]
brew-install:
    brew bundle --file=Brewfile

# Dump installed packages to Brewfile
[group('brew')]
brew-dump:
    brew bundle dump --file=Brewfile --force --no-vscode --no-go --no-cargo

# Remove packages not listed in Brewfile
[group('brew')]
brew-cleanup:
    brew bundle cleanup --file=Brewfile --force

# Install Brewfile packages and remove extras
[group('brew')]
brew-sync: brew-install brew-cleanup

# Verify shell config, Brewfile dependencies, and whitespace
[group('check')]
check:
    for file in .zshrc .config/zsh/*.zsh; do zsh -n "$file" || exit $?; done
    brew bundle check --file=Brewfile
    git diff --check

# Apply the repo's default macOS file associations
[group('macos')]
file-defaults:
    ./.config/duti/set-file-defaults.sh
