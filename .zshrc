# Main Zsh configuration file
# This file sources all the modular configuration files in the correct order

# Cache directory for generated Zsh files
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR" 2>/dev/null

# Fast startup for interactive -c runs (opt out with ZSH_FAST_STARTUP=0)
if [[ -n "${ZSH_EXECUTION_STRING:-}" && -z "${ZSH_FAST_STARTUP:-}" ]]; then
  export ZSH_FAST_STARTUP=1
fi

# Source configuration modules in order (numbered files first)
for config_file in ~/.config/zsh/*.zsh; do
  # Skip the main zshrc file itself to avoid infinite loop
  [[ "$config_file" != *"/zshrc" ]] && [[ -f "$config_file" ]] && source "$config_file"
done

# Load completion-dependent tools after completion system is set up
if [[ $_OP_COMPLETION_AVAILABLE ]]; then
  op_completion_cache="${ZSH_CACHE_DIR}/op-completion.zsh"
  _zsh_load_op_completion() {
    if [[ -s "$op_completion_cache" ]]; then
      source "$op_completion_cache"
    else
      op completion zsh >| "$op_completion_cache" 2>/dev/null
      [[ -s "$op_completion_cache" ]] && source "$op_completion_cache"
    fi
  }
  if typeset -p _zsh_post_compinit_hooks >/dev/null 2>&1; then
    _zsh_post_compinit_hooks+=("_zsh_load_op_completion")
  else
    _zsh_load_op_completion
  fi
fi
