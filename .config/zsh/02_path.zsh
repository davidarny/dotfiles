# Default tools
export PAGER=bat
export EDITOR=nvim
export VISUAL=cursor

# Ignore EOF to prevent accidental shell exit
set -o ignoreeof

# Set PATH for various tools and environments
export PATH=$HOME/.local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt/ruby/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Java and Android SDK configuration
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"

# Flutter and fnm configuration
export PATH=$PATH:"$HOME/fvm/default/bin"
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"

# Bun
export BUN_HOME="$HOME/.bun"
export PATH="$BUN_HOME/bin:$PATH"

# Set config default directory to ~/.config
export XDG_CONFIG_HOME="$HOME/.config"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/david_arutiunian/.lmstudio/bin"

# PNPM configuration
export PNPM_HOME="/Users/david_arutiunian/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Disable Corepack auto-pin
export COREPACK_ENABLE_AUTO_PIN=0

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
