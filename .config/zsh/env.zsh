# Default tools
export PAGER=bat
export EDITOR=nvim
export VISUAL=${VISUAL:-${commands[cursor]:-$EDITOR}}

# XDG
export XDG_CONFIG_HOME="$HOME/.config"

# 1Password CLI
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Disable Corepack auto-pin
export COREPACK_ENABLE_AUTO_PIN=0

# ImageMagick for image.nvim
if command -v brew >/dev/null 2>&1; then
  export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:${DYLD_LIBRARY_PATH:-}"
fi
