# Auto-sync Brewfile after install/uninstall
function brew() {
  command brew "$@"
  local brew_status=$?

  if (( brew_status == 0 )) && [[ "$1" =~ ^(install|uninstall|remove|rmtree)$ ]]; then
    command brew bundle dump --file=~/.dotfiles/Brewfile --force --no-vscode --no-go --no-cargo
  fi

  return $brew_status
}
