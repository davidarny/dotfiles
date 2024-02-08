# Reset t alias
unalias t
# Reset tldr alias
unalias tldr

# Custom aliases
alias pfzf='fzf --preview "bat --style=numbers --color=always {}"'
alias vfzf='vim $(pfzf)'
alias cfzf='code $(pfzf)'
alias tb="nc termbin.com 9999"
alias ipinfo="curl ipinfo.io"
alias t="exa -n --long --tree --level=1"
alias c="clear"
