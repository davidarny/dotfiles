# Main Zsh configuration entry point
# This file sources the modular configuration from .config/zsh/

# Source the main configuration file
if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
  source "$HOME/.config/zsh/zshrc"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/david.arutyunyan/.lmstudio/bin"
# End of LM Studio CLI section

