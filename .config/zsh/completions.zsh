# Keep completion paths unique across reloads.
typeset -gU fpath

# Add Homebrew completions to fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Initialize completion system
[[ -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh"
autoload -Uz compinit
local zdump="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"
# compinit -C replays the cached dump without scanning fpath. The dump maps
# commands to completion functions, so rebuild it when a completion is added or
# removed: that changes its fpath directory's mtime (brew link, plugin update).
local zdump_stale=0 zdump_dir
if [[ ! -s $zdump ]]; then
  zdump_stale=1
else
  for zdump_dir in $fpath; do
    [[ $zdump_dir -nt $zdump ]] && { zdump_stale=1; break }
  done
fi
if (( zdump_stale )); then
  compinit -d "$zdump"
  # compinit keeps an unchanged dump as is; mark it fresh so the next start is fast.
  command touch "$zdump"
else
  compinit -C -d "$zdump"
fi
unset zdump_stale zdump_dir

# Load plugins that require compinit first.
if command -v antidote >/dev/null 2>&1 && (( ${+functions[_antidote_load_bundle]} )); then
  _antidote_load_bundle \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/antidote/post-completion-plugins.txt" \
    "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/antidote-post-completion-plugins.zsh" \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/plugins.zsh"
  unfunction _antidote_load_bundle
fi

# Tool completions not shipped into fpath by their package manager
_eval_cached lazygit completion zsh
_eval_cached lazyssh completion zsh
_eval_cached ngrok completion

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
