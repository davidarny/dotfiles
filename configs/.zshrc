# Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
export EDITOR=nvim
export BAT_THEME="TwoDark"

set -o ignoreeof

autoload -U compinit
compinit -i

export PATH=$HOME/.local/bin:$PATH
export ZSH=$HOME/.oh-my-zsh

plugins=(
    git
    gitgo
    gitfast
    gitignore
    fnm
    brew
    httpie
    common-aliases
    command-not-found
    gh
    fzf
    macos
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# https://github.com/folke/tokyonight.nvim/tree/main/extras/fzf
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

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source "$HOME/.config/zsh/fzf-git.sh"

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
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

source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -f "$HOME/.config/zsh/functions.zsh" ]] && source "$HOME/.config/zsh/functions.zsh"
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

source /opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh
if [ -f $(brew --prefix)/etc/zsh_completion ]; then
  . $(brew --prefix)/etc/zsh_completion
fi

eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
eval "$(thefuck --alias)"
eval "$(thefuck --alias fk)"
eval "$(starship init zsh)"
eval "$(gh copilot alias -- zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

PATH=$(pyenv root)/shims:$PATH
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source $(pyenv root)/completions/pyenv.zsh

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"

export PATH=$PATH:"$HOME/fvm/default/bin"
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"

HB_CNF_HANDLER="$(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
if [ -f "$HB_CNF_HANDLER" ]; then
  source "$HB_CNF_HANDLER";
fi

bindkey -s ^f "tmux-sessionizer\n"
bindkey -s ^z "zellij-sessionizer\n"

# https://github.com/3rd/image.nvim?tab=readme-ov-file#installing-imagemagick
export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

# Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
