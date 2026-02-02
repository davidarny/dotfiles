# Source configuration modules in order
for config_file in ~/.config/zsh/*.zsh; do
  [[ "$config_file" != *"/zshrc" ]] && [[ -f "$config_file" ]] && source "$config_file"
done

# Load completion-dependent tools after completion system is set up
[[ $_OP_COMPLETION_AVAILABLE ]] && eval "$(op completion zsh)"
