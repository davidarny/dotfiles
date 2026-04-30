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

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
_path_prepend "$PYENV_ROOT/bin"

# Java
_path_prepend "/opt/homebrew/opt/openjdk/bin"

unfunction _path_prepend
