# Keep completion paths unique across reloads.
typeset -gU fpath

# Add Homebrew completions to fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Initialize completion system
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh"
autoload -Uz compinit
local zdump="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"
# compinit -C replays the cached dump without scanning fpath, so rebuild the
# dump when any completion file in fpath is newer than it (brew install/upgrade).
if [[ ! -s $zdump ]] || [[ -n $(find $fpath -name '_*' -newer "$zdump" 2>/dev/null | head -1) ]]; then
  compinit -d "$zdump"
else
  compinit -C -d "$zdump"
fi

# Load plugins that require compinit first.
if command -v antidote >/dev/null 2>&1 && (( ${+functions[_antidote_load_bundle]} )); then
  _antidote_load_bundle \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/antidote/post-completion-plugins.txt" \
    "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/antidote-post-completion-plugins.zsh" \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/plugins.zsh"
  unfunction _antidote_load_bundle
fi

# Tool completions not shipped into fpath by their package manager
command -v lazygit >/dev/null 2>&1 && eval "$(lazygit completion zsh)"
command -v lazyssh >/dev/null 2>&1 && eval "$(lazyssh completion zsh)"
command -v ngrok >/dev/null 2>&1 && eval "$(ngrok completion)"

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:make:*:targets' call-command true
zstyle ':completion:*:*:make:*' tag-order 'targets'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons=always $realpath | head -200'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --color=always --icons=always $realpath | head -200'
