# Auto-sync Brewfile after install/uninstall
function brew() {
  command brew "$@"
  if [[ "$1" =~ ^(install|uninstall|remove|rmtree)$ ]]; then
    command brew bundle dump --file=~/.dotfiles/Brewfile --force --no-vscode --no-go --no-cargo
  fi
}
