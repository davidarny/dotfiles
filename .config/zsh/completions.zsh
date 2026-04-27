# Add Homebrew completions to fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Remove stale Zinit completion symlinks before compinit scans fpath.
zinit_completions_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/completions"
if [[ -d "$zinit_completions_dir" ]]; then
  for completion in "$zinit_completions_dir"/_*(N); do
    [[ -h "$completion" && ! -e "$completion" ]] && rm -f -- "$completion"
  done
fi

# Initialize completion system
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh"
autoload -Uz compinit
compinit -C -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# Replay Zinit commands quietly
command -v zinit >/dev/null 2>&1 && zinit cdreplay -q

# Tool completions
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
