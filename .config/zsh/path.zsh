# Keep PATH entries unique while preserving order
typeset -U path PATH

_path_prepend() {
  [[ -d "$1" ]] && path=("$1" $path)
}

# Local binaries
_path_prepend "$HOME/.local/bin"

# mise-managed tools
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v bun >/dev/null 2>&1; then
  # Bun
  _path_prepend "$HOME/.bun/bin"
fi

unfunction _path_prepend
