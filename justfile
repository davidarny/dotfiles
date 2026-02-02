# Symlink dotfiles to home directory
link:
    stow --restow --adopt --target="$HOME" .

# Remove dotfiles symlinks from home directory
unlink:
    stow --delete --target="$HOME" .
