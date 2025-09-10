# Initialize various tools
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(op completion zsh)"
eval "$(gh copilot alias -- zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
eval "$(pyenv init -)"

# Bun completions
[ -s "/Users/david_arutiunian/.bun/_bun" ] && source "/Users/david_arutiunian/.bun/_bun"

# Kiro integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
