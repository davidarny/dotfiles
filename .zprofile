eval "$(/opt/homebrew/bin/brew shellenv zsh)"

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell zsh --use-on-cd --version-file-strategy=recursive)"
fi

source ~/.config/zsh/aliases.zsh
