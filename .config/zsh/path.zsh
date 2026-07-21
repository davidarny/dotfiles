# Keep PATH entries unique while preserving order
typeset -U path PATH

_path_prepend() {
  [[ -d "$1" ]] && path=("$1" $path)
}

# Local binaries
_path_prepend "$HOME/.local/bin"

# fnm
_path_prepend "$HOME/Library/Application Support/fnm"

# Bun
_path_prepend "$HOME/.bun/bin"

# Java
_path_prepend "/opt/homebrew/opt/openjdk/bin"

# MimoCode
_path_prepend "$HOME/.mimocode/bin"

unfunction _path_prepend
