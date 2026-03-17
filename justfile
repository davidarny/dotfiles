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
