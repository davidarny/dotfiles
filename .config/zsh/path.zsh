# Current user
export CURRENT_USER=$(whoami)

# Default tools
export PAGER=bat
export EDITOR=nvim
export VISUAL=${VISUAL:-${commands[cursor]:-$EDITOR}}

# Ignore EOF to prevent accidental shell exit
set -o ignoreeof

# Set PATH for various tools and environments
export PATH=$HOME/.local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH

# fnm configuration
export PATH=$PATH:"$HOME/fvm/default/bin"
export PATH="/Users/$CURRENT_USER/Library/Application Support/fnm:$PATH"

# Bun
export BUN_HOME="$HOME/.bun"
export PATH="$BUN_HOME/bin:$PATH"

# Set config default directory to ~/.config
export XDG_CONFIG_HOME="$HOME/.config"

# PNPM configuration
export PNPM_HOME="/Users/$CURRENT_USER/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Disable Corepack auto-pin
export COREPACK_ENABLE_AUTO_PIN=0

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# 1Password CLI
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
