# Auto-sync Brewfile after install/uninstall
typeset -g _dotfiles_brewfile="${${(%):-%x}:A:h:h:h}/Brewfile"

function brew() {
  command brew "$@"
  local brew_status=$?

  if (( brew_status == 0 )) && [[ "$1" =~ ^(install|uninstall|remove|rmtree)$ ]]; then
    command brew bundle dump --file="$_dotfiles_brewfile" --force --no-vscode --no-go --no-cargo
  fi

  return $brew_status
}
