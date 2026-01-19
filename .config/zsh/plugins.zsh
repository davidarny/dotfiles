# Zinit configuration (only if available)
if command -v git >/dev/null 2>&1; then
  ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  if [ ! -d "$ZINIT_HOME" ]; then
     mkdir -p "$(dirname $ZINIT_HOME)" 2>/dev/null
     git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null
  fi
  [ -f "${ZINIT_HOME}/zinit.zsh" ] && source "${ZINIT_HOME}/zinit.zsh"
fi

# Load Zsh plugins using Zinit (only if zinit is available)
if command -v zinit >/dev/null 2>&1; then
  zinit light Aloxaf/fzf-tab
  zinit light zsh-users/zsh-completions
  zinit light g-plane/pnpm-shell-completion

  # Load Oh My Zsh snippets
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::npm
  zinit snippet OMZP::brew
  zinit snippet OMZP::node

  autoload -Uz compinit

  # Lazy-load compinit on first completion to reduce startup time.
  zsh_cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
  mkdir -p "$zsh_cache_dir" 2>/dev/null
  typeset -g _zsh_compinit_done=0
  typeset -g -a _zsh_post_compinit_hooks=()
  _zsh_run_post_compinit() {
    local hook
    for hook in "${_zsh_post_compinit_hooks[@]}"; do
      eval "$hook"
    done
    _zsh_post_compinit_hooks=()
  }
  _zsh_compinit() {
    (( _zsh_compinit_done )) && return
    _zsh_compinit_done=1
    compinit -C -d "$zsh_cache_dir/zcompdump-$ZSH_VERSION"
    zinit cdreplay -q
    _zsh_run_post_compinit
  }

  if [[ -o interactive ]]; then
    if [[ -z "${_zsh_lazy_compinit_installed:-}" ]]; then
      typeset -g _zsh_lazy_compinit_installed=1
      _zsh_lazy_compinit() {
        _zsh_compinit
        zle -A _zsh_orig_expand_or_complete expand-or-complete
        zle -A _zsh_orig_complete_word complete-word
        zle expand-or-complete
      }
      zle -A expand-or-complete _zsh_orig_expand_or_complete
      zle -A complete-word _zsh_orig_complete_word
      zle -N expand-or-complete _zsh_lazy_compinit
      zle -N complete-word _zsh_lazy_compinit
    fi

    if [[ -z "${_zsh_line_init_installed:-}" ]]; then
      typeset -g _zsh_line_init_installed=1
      if (( $+widgets[zle-line-init] )); then
        zle -A zle-line-init _zsh_orig_zle_line_init
      else
        unset _zsh_orig_zle_line_init
      fi
      _zsh_line_init() {
        _zsh_compinit
        if (( $+widgets[_zsh_orig_zle_line_init] )) && [[ "$_zsh_orig_zle_line_init" != "_zsh_line_init" ]]; then
          zle _zsh_orig_zle_line_init
        fi
      }
      zle -N zle-line-init _zsh_line_init
    fi
  else
    _zsh_compinit
  fi

  # Defer UI-heavy plugins to reduce startup latency
  zinit ice wait"0" lucid
  zinit light zsh-users/zsh-autosuggestions
  zinit ice wait"1" lucid
  zinit light zsh-users/zsh-syntax-highlighting

  # Completion styling
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath | head -200'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --color=always $realpath | head -200'
  zstyle ':completion:*:make:*:targets' call-command true
  zstyle ':completion:*:*:make:*' tag-order 'targets'
  zstyle ':completion:*:*:docker:*' option-stacking yes
  zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi
