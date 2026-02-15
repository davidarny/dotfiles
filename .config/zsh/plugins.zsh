# Zinit configuration (only if available)
if command -v git >/dev/null 2>&1; then
  ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  if [ ! -d "$ZINIT_HOME" ]; then
     mkdir -p "$(dirname $ZINIT_HOME)" 2>/dev/null
     git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null
  fi
  [ -f "${ZINIT_HOME}/zinit.zsh" ] && source "${ZINIT_HOME}/zinit.zsh"
fi

# Plugin configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Load Zsh plugins using Zinit (only if zinit is available)
if command -v zinit >/dev/null 2>&1; then
  zinit light Aloxaf/fzf-tab
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-history-substring-search
  zinit light g-plane/pnpm-shell-completion

  # Load Oh My Zsh snippets
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::npm
  zinit snippet OMZP::brew
  zinit snippet OMZP::node

fi

# Keybindings (after plugins are loaded)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
