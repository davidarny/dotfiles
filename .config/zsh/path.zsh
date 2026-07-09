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
export BUN_HOME="$HOME/.bun"
_path_prepend "$BUN_HOME/bin"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"
_path_prepend "$PNPM_HOME"

# Java
_path_prepend "/opt/homebrew/opt/openjdk/bin"

# MimoCode
_path_prepend "$HOME/.mimocode/bin"

unfunction _path_prepend
