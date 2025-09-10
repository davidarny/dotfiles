# Main Zsh configuration entry point
# This file sources the modular configuration from .config/zsh/

# Set ZDOTDIR to ensure Zsh looks for configuration in the right place
export ZDOTDIR="$HOME"

# Source the main configuration file
if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
  source "$HOME/.config/zsh/zshrc"
fi
