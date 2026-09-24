# Default tools
if command -v bat >/dev/null 2>&1; then
  # --plain: gh and glab page plain text, without bat's header, grid, and line numbers.
  export PAGER='bat --plain'
else
  export PAGER=less
fi

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

export VISUAL=$EDITOR

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
# eza on macOS ignores XDG_CONFIG_HOME and would never read ~/.config/eza/theme.yml.
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

# 1Password SSH agent (sandboxed app path). An SSH session keeps its forwarded agent.
op_ssh_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [[ -S $op_ssh_sock && -z $SSH_CONNECTION ]]; then
  export SSH_AUTH_SOCK=$op_ssh_sock
fi
unset op_ssh_sock

# Disable Corepack auto-pin
export COREPACK_ENABLE_AUTO_PIN=0

# MCP secrets resolved from 1Password (see `just mcp-secrets`)
if [[ -f "$XDG_CONFIG_HOME/mcp/mcp-secrets.env" ]]; then
  source "$XDG_CONFIG_HOME/mcp/mcp-secrets.env"
fi
