# Add Homebrew completions to fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Initialize completion system
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh"
autoload -Uz compinit
compinit -C -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# Load plugins that require compinit first.
if command -v antidote >/dev/null 2>&1 && (( ${+functions[_antidote_load_bundle]} )); then
  _antidote_load_bundle \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/antidote-post-completion-plugins.txt" \
    "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/antidote-post-completion-plugins.zsh"
  unfunction _antidote_load_bundle
fi

# Tool completions
command -v opencode >/dev/null 2>&1 && eval "$(opencode completion zsh)"
[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:*:make:*' tag-order 'targets'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
