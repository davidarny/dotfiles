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

# tmux
alias tm='tmux'

# macOS
alias reload='source ~/.zshrc'
alias allowapp='sudo xattr -r -d com.apple.quarantine'
alias dsclean='fd -H '^\.DS_Store$' -tf -X rm'
alias lnclean="fd . --type l -x sh -c 'if [ ! -e \"\$1\" ]; then rm \"\$1\"; fi' --"

# misc
alias t='l'
alias ls='l'
alias c='clear'
alias rf='trash'
alias man='batman'
alias ff='fastfetch'
alias yz='yazi'
alias lg='lazygit'

# claude
alias ccc='claude --dangerously-skip-permissions'
alias cx='codex --dangerously-bypass-approvals-and-sandbox'
alias claude-mem='bun "/Users/david.arutyunyan/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
