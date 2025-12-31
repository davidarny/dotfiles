# Main Zsh configuration file
# This file sources all the modular configuration files in the correct order

# Source configuration modules in order (numbered files first)
for config_file in ~/.config/zsh/*.zsh; do
  # Skip the main zshrc file itself to avoid infinite loop
  [[ "$config_file" != *"/zshrc" ]] && [[ -f "$config_file" ]] && source "$config_file"
done

# Load completion-dependent tools after completion system is set up
[[ $_OP_COMPLETION_AVAILABLE ]] && eval "$(op completion zsh)"
[[ $_GH_COMPLETION_AVAILABLE ]] && eval "$(gh copilot alias -- zsh)"
