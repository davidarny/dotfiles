_alias_if_exists() {
  local command_name="$1"
  shift
  command -v "$command_name" >/dev/null 2>&1 && alias "$@"
}

# editor
alias e="$EDITOR"
alias E='sudo -e'

# ls
_alias_if_exists eza 'l=eza -1A --group-directories-first --color=always --icons=always --tree --level=1'
_alias_if_exists eza 'la=eza -la --git --git-repos --group-directories-first --color=always --octal-permissions --time-style=long-iso --icons=always --tree --level=1'
_alias_if_exists eza 'tree=eza -A --tree --group-directories-first --color=always --icons=always'

# rg
_alias_if_exists rg "rg=command rg --hidden --smart-case --glob='!.git/' --no-search-zip --trim --colors=line:fg:black --colors=line:style:bold --colors=path:fg:magenta --colors=match:style:nobold"

# caddy
_alias_if_exists caddy 'cds=caddy start --config ~/.config/caddy/caddy.json'
_alias_if_exists caddy 'cdx=caddy stop'

# macOS
alias reload='source ~/.zshrc'
_alias_if_exists xattr 'allowapp=sudo xattr -r -d com.apple.quarantine'
_alias_if_exists fd "dsclean=fd -H '^\\.DS_Store$' -tf -X rm"
_alias_if_exists fd "lnclean=fd . --type l -x sh -c 'if [ ! -e \"\$1\" ]; then rm \"\$1\"; fi' --"

# ssh (fix xterm-ghostty terminfo missing on remote servers)
_alias_if_exists ssh 'ssh=TERM=xterm-256color command ssh'

# tools
(( ${+aliases[l]} )) && alias t='l'
alias c='clear'
_alias_if_exists trash 'rf=trash'
_alias_if_exists fastfetch 'ff=fastfetch'
_alias_if_exists yazi 'yz=yazi'
_alias_if_exists pbcopy 'copypath=pwd | pbcopy'
_alias_if_exists lazygit 'lg=lazygit'
_alias_if_exists lazydocker 'lzd=lazydocker'
_alias_if_exists tmux 'tm=tmux'

# bun (use as fast npm alternative without polluting the project with bun.lock)
_alias_if_exists bun 'buni=bun install --no-save && bun pm trust --all && rm -f bun.lock'

# ai
_alias_if_exists claude 'ccc=claude --dangerously-skip-permissions'
_alias_if_exists codex 'xxx=codex --yolo'
_alias_if_exists opencode 'ooo=opencode'

unfunction _alias_if_exists
