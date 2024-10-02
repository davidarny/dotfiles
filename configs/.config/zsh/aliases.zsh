alias c="clear"
alias t="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lg="lazygit"
alias man="batman"
alias npmung="npm list -g --no-unicode | awk '/(\+|\`)--/ {print $2}' | cut -c5- | fzf --multi | cut -d'@' -f1 | xargs npm un -g"

alias dev="cd ~/Developer"

alias zj="zellij"
alias tm="tmux"

alias tms="tmux-sessionizer"
alias zjs="zellij-sessionizer"

