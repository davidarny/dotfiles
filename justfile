# Symlink dotfiles to home directory
[group('stow')]
link:
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
