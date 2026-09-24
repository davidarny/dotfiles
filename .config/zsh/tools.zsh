# Initialize various tools (only if available)
[[ -t 0 ]] && _eval_cached fzf --zsh
_eval_cached zoxide init zsh
_eval_cached starship init zsh --print-full-init
