[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Login shells that skip .zshrc (zsh -lc) resolve mise runtimes through the
# shims; mise activate in .zshrc puts the active versions ahead of them.
[[ -d ~/.local/share/mise/shims ]] && path=(~/.local/share/mise/shims $path)

source ~/.config/zsh/env.zsh
source ~/.config/zsh/aliases.zsh
