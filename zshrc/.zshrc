# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh"
# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
export EDITOR=nvim

autoload -U compinit
compinit -i

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="/Users/david_arutiunian/.oh-my-zsh"

plugins=(
    lol
    git
    npm
    nvm
    yarn
    brew
    rsync
    docker
    httpie
    common-aliases
    docker-compose
    zsh-autosuggestions
)

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -f "$HOME/.config/zsh/plugins.zsh" ]] && source "$HOME/.config/zsh/plugins.zsh"
[[ -f "$HOME/.config/zsh/functions.zsh" ]] && source "$HOME/.config/zsh/functions.zsh"
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH

source /opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh
if [ -f $(brew --prefix)/etc/zsh_completion ]; then
. $(brew --prefix)/etc/zsh_completion
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
eval $(thefuck --alias)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
if command -v ngrok &>/dev/null; then
    eval "$(ngrok completion)"
fi

PATH=$(pyenv root)/shims:$PATH
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source $(pyenv root)/completions/pyenv.zsh

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"


export PATH=$PATH:"$HOME/fvm/default/bin"
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"


# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh"
