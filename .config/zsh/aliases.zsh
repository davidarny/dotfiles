# Aliases: editor
alias e="$EDITOR"
alias E="sudo -e"

# Aliases: ls
alias l='eza -1A --group-directories-first --color=always'
alias t='l'
alias ls='l'
alias la='l -l --time-style="+%Y-%m-%d %H:%M" --no-permissions --octal-permissions'
alias tree='l --tree'

# Aliases: rg
alias rg="rg --hidden --smart-case --glob='!.git/' --no-search-zip --trim --colors=line:fg:black --colors=line:style:bold --colors=path:fg:magenta --colors=match:style:nobold"


# Aliases: caddy
alias cdr="caddy start --config ~/.dotfiles/Caddyfile"
alias cds="caddy stop"

# Aliases: dev
alias c="clear"
alias dev="cd ~/Developer"

# Aliases: tmux
alias tm="tmux"
alias tms="tmux-sessionizer"

# Aliases: macOS
alias zs="source ~/.zshrc"
alias allowapp="sudo xattr -r -d com.apple.quarantine"
alias lprst="sudo find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock"

# Aliases: misc
alias rf='trash'
alias man="batman"
alias ff="fastfetch"
alias yz="yazi"
alias lg="lazygit"
