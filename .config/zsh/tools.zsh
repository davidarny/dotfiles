# Initialize various tools (only if available)
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh --print-full-init)"
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init --no-rehash -)"
