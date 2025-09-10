# Initialize various tools (only if available)
# Note: Some tool initializations are deferred until after completion system is set up

# Basic tool checks and path setup
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh --print-full-init 2>/dev/null || starship init zsh)"
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

# Defer completion-dependent tools until after completion system is loaded
# These will be loaded in the main zshrc after plugins/completion setup
if command -v op >/dev/null 2>&1; then
  # Store for later loading
  export _OP_COMPLETION_AVAILABLE=1
fi

if command -v gh >/dev/null 2>&1; then
  # Store for later loading
  export _GH_COMPLETION_AVAILABLE=1
fi

# Kiro integration (safe to load early)
[[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1 && . "$(kiro --locate-shell-integration-path zsh)"
