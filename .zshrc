# History settings
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Ignore EOF to prevent accidental shell exit
set -o ignoreeof

# Set PATH for various tools and environments
export PATH=$HOME/.local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Java and Android SDK configuration
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"

# Flutter and fnm configuration
export PATH=$PATH:"$HOME/fvm/default/bin"
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"

# FZF configuration
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none
  --color=bg+:#283457 \
  --color=bg:#16161e \
  --color=border:#27a1b9 \
  --color=fg:#c0caf5 \
  --color=gutter:#16161e \
  --color=header:#ff9e64 \
  --color=hl+:#2ac3de \
  --color=hl:#2ac3de \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#2ac3de \
  --color=query:#c0caf5:regular \
  --color=scrollbar:#27a1b9 \
  --color=separator:#ff9e64 \
  --color=spinner:#ff007c \
"

# FZF commands for file and directory search
export FZF_CTRL_T_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# FZF preview settings
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# ImageMagick configuration for image.nvim
export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

# Zinit configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load Zsh plugins using Zinit
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load Oh My Zsh snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# Replay Zinit commands quietly
zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# FZF custom path and directory generation
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# Advanced FZF customization
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# Source additional configuration files
[[ -f "$HOME/.config/zsh/functions.zsh" ]] && source "$HOME/.config/zsh/functions.zsh"
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

# Initialize various tools
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(gh copilot alias -- zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

# Key bindings
bindkey -s ^f "tmux-sessionizer\n"
bindkey -s ^z "zellij-sessionizer\n"