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
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light g-plane/pnpm-shell-completion

  # Load Oh My Zsh snippets
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::npm
  zinit snippet OMZP::brew
  zinit snippet OMZP::node
  zinit snippet OMZP::command-not-found

  autoload -Uz compinit
  compinit

  # Replay Zinit commands quietly
  zinit cdreplay -q
fi

# Completion styling (only if zinit is available)
if command -v zinit >/dev/null 2>&1; then
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
  zstyle ':completion:*:make:*:targets' call-command true
  zstyle ':completion:*:*:make:*' tag-order 'targets'
  zstyle ':completion:*:*:docker:*' option-stacking yes
  zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi
