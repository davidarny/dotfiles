# Add Homebrew completions to fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Initialize completion system
autoload -Uz compinit
compinit -C -d ~/.cache/zsh/zcompdump-$ZSH_VERSION

# Replay Zinit commands quietly
command -v zinit >/dev/null 2>&1 && zinit cdreplay -q

# Tool completions
command -v op >/dev/null 2>&1 && eval "$(op completion zsh)"
command -v opencode >/dev/null 2>&1 && eval "$(opencode completion zsh)"
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons=always $realpath | head -200'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --color=always --icons=always $realpath | head -200'
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:*:make:*' tag-order 'targets'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
