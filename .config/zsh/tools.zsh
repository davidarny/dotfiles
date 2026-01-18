# Initialize various tools (only if available)
# Note: Some tool initializations are deferred until after completion system is set up

# Basic tool checks and path setup
zsh_cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
mkdir -p "$zsh_cache_dir" 2>/dev/null
cache_writable=0
[[ -d "$zsh_cache_dir" && -w "$zsh_cache_dir" ]] && cache_writable=1

# Skip heavy tool init for fast startup shells (interactive -c by default)
if [[ -n "${ZSH_FAST_STARTUP:-}" ]]; then
  return 0
fi

if [[ -r "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
elif [[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
elif [[ -r /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
elif (( $+commands[fzf] )); then
  fzf_cache="${zsh_cache_dir}/fzf-init.zsh"
  fzf_bin="${commands[fzf]}"
  if (( cache_writable )); then
    if [[ ! -s "$fzf_cache" || "$fzf_bin" -nt "$fzf_cache" ]]; then
      fzf --zsh >| "$fzf_cache" 2>/dev/null
    fi
    if [[ -s "$fzf_cache" ]]; then
      source "$fzf_cache"
    else
      eval "$(fzf --zsh)"
    fi
  else
    eval "$(fzf --zsh)"
  fi
fi

if (( $+commands[zoxide] )); then
  zoxide_cache="${zsh_cache_dir}/zoxide-init.zsh"
  zoxide_bin="${commands[zoxide]}"
  if (( cache_writable )); then
    if [[ ! -s "$zoxide_cache" || "$zoxide_bin" -nt "$zoxide_cache" ]]; then
      zoxide init zsh >| "$zoxide_cache" 2>/dev/null
    fi
    if [[ -s "$zoxide_cache" ]]; then
      source "$zoxide_cache"
    else
      eval "$(zoxide init zsh)"
    fi
  else
    eval "$(zoxide init zsh)"
  fi
fi

if (( $+commands[starship] )); then
  starship_cache="${zsh_cache_dir}/starship-init.zsh"
  starship_bin="${commands[starship]}"
  starship_config="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
  if (( cache_writable )); then
    if [[ ! -s "$starship_cache" || "$starship_bin" -nt "$starship_cache" || ( -f "$starship_config" && "$starship_config" -nt "$starship_cache" ) ]]; then
      starship init zsh --print-full-init >| "$starship_cache" 2>/dev/null || \
        starship init zsh >| "$starship_cache" 2>/dev/null
    fi
    if [[ -s "$starship_cache" ]]; then
      source "$starship_cache"
    else
      eval "$(starship init zsh --print-full-init 2>/dev/null || starship init zsh)"
    fi
  else
    eval "$(starship init zsh --print-full-init 2>/dev/null || starship init zsh)"
  fi
fi

if (( $+commands[fnm] )); then
  fnm_cache="${zsh_cache_dir}/fnm-env.zsh"
  fnm_bin="${commands[fnm]}"
  if (( cache_writable )); then
    if [[ ! -s "$fnm_cache" || "$fnm_bin" -nt "$fnm_cache" ]]; then
      fnm env --use-on-cd --version-file-strategy=recursive >| "$fnm_cache" 2>/dev/null
    fi
    if [[ -s "$fnm_cache" ]]; then
      source "$fnm_cache"
    else
      eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
    fi
  else
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
  fi
fi

if (( $+commands[pyenv] )); then
  pyenv_cache="${zsh_cache_dir}/pyenv-init.zsh"
  pyenv_bin="${commands[pyenv]}"
  if (( cache_writable )); then
    if [[ ! -s "$pyenv_cache" || "$pyenv_bin" -nt "$pyenv_cache" ]]; then
      pyenv init - >| "$pyenv_cache" 2>/dev/null
    fi
    if [[ -s "$pyenv_cache" ]]; then
      source "$pyenv_cache"
    else
      eval "$(pyenv init -)"
    fi
  else
    eval "$(pyenv init -)"
  fi
fi

# Defer completion-dependent tools until after completion system is loaded
# These will be loaded in the main zshrc after plugins/completion setup
if command -v op >/dev/null 2>&1; then
  # Store for later loading
  export _OP_COMPLETION_AVAILABLE=1
fi

# Kiro integration (safe to load early)
[[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1 && . "$(kiro --locate-shell-integration-path zsh)"
