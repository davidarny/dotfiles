# Initialize various tools (only if available)
if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook zsh)"

  _direnv_hook() {
    trap -- '' SIGINT
    eval "$(DIRENV_WORK_DIR="$PWD" direnv export zsh)"
    trap - SIGINT
  }

  _direnv_reload_on_chpwd() {
    direnv reload >/dev/null 2>&1 || true
  }

  chpwd_functions=(_direnv_reload_on_chpwd $chpwd_functions)
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh --print-full-init)"
fi
