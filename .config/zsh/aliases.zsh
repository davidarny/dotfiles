alias c="clear"
alias t="eza --color=always --long --git --icons=always --no-time --group-directories-first"
alias lg="lazygit"
alias man="batman"
alias npmung="npm list -g --no-unicode | awk '/(\+|\`)--/ {print $2}' | cut -c5- | fzf --multi | cut -d'@' -f1 | xargs npm un -g"

alias dev="cd ~/Developer"
alias ..="cd .."

alias zj="zellij"
alias tm="tmux"
alias yz="yazi"

alias tms="tmux-sessionizer"
alias zjs="zellij-sessionizer"

alias zshsource="source ~/.zshrc"
