# Keep PATH entries unique while preserving order
typeset -U path

# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# fnm
export PATH="$HOME/Library/Application Support/fnm:$PATH"
export PATH="$HOME/fvm/default/bin:$PATH"

# Bun
export BUN_HOME="$HOME/.bun"
export PATH="$BUN_HOME/bin:$PATH"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
