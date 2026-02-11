# editor
alias e="$EDITOR"
alias E='sudo -e'

# ls
alias l='eza -1A --group-directories-first --color=always'
alias la='eza -la --git --git-repos --group-directories-first --color=always --octal-permissions --time-style=long-iso'
alias tree='eza --tree --group-directories-first --color=always'

# rg
alias rg="command rg --hidden --smart-case --glob='!.git/' --no-search-zip --trim --colors=line:fg:black --colors=line:style:bold --colors=path:fg:magenta --colors=match:style:nobold"

# caddy
alias caddystart='caddy start --config ~/.config/caddy/caddy.json'
alias caddystop='caddy stop'

# macOS
alias reload='source ~/.zshrc'
alias allowapp='sudo xattr -r -d com.apple.quarantine'
alias dsclean='fd -H '^\.DS_Store$' -tf -X rm'
alias lnclean="fd . --type l -x sh -c 'if [ ! -e \"\$1\" ]; then rm \"\$1\"; fi' --"

# tools
alias t='l'
alias tm='tmux'
alias c='clear'
alias rf='trash'
alias man='batman'
alias ff='fastfetch'
alias yz='yazi'
alias lg='lazygit'
alias lzd='lazydocker'

# ai
alias ccc='claude --dangerously-skip-permissions'
alias xxx='codex --yolo'
alias ooo='opencode'
