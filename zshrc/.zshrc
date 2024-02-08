# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
export EDITOR=nvim

# Set gh autocompletion
autoload -U compinit
compinit -i

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/david_arutiunian/.oh-my-zsh"

# Set up plugins
plugins=(
    common-aliases
    rsync
    lol
    brew
    git
    npm
    nvm
    httpie
    yarn
    docker
    docker-compose
    zsh-autosuggestions
)

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# Set up oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Set up fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Set up plugins
[[ -f "$HOME/.config/zsh/plugins.zsh" ]] && source "$HOME/.config/zsh/plugins.zsh"
# Set up functions
[[ -f "$HOME/.config/zsh/functions.zsh" ]] && source "$HOME/.config/zsh/functions.zsh"
# Set up aliases
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

# Homebrew
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH

# Zsh completions
if [ -f $(brew --prefix)/etc/zsh_completion ]; then
. $(brew --prefix)/etc/zsh_completion
fi

# Set up Yarn home
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# TheFuck
eval $(thefuck --alias)

# Set up pyenv
PATH=$(pyenv root)/shims:$PATH
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source $(pyenv root)/completions/pyenv.zsh

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Ngrok
if command -v ngrok &>/dev/null; then
    eval "$(ngrok completion)"
fi

export PATH=$PATH:"$HOME/fvm/default/bin"

# Autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# Android SKD
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"

# Git completions
source /opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh

# fnm
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

# Set up starship
eval "$(starship init zsh)"

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
