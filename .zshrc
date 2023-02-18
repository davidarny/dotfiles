# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
export EDITOR=code

if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
##### WHAT YOU WANT TO DISABLE FOR WARP - BELOW

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

##### WHAT YOU WANT TO DISABLE FOR WARP - ABOVE
fi

if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then

# Set up starship
eval "$(starship init zsh)"

fi

# Set gh autocompletion
autoload -U compinit
compinit -i

# Set up nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

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

source $ZSH/oh-my-zsh.sh

# Antigen
source /opt/homebrew/share/antigen/antigen.zsh

antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle reegnz/jq-zsh-plugin

antigen apply


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# yarn fzf
function fyarn {
    local packages
    packages=$(all-the-package-names | fzf -m) &&
    echo "$packages" &&
    yarn add $(echo $packages)
}

# npm fzf
function fnpm {
    local packages
    packages=$(all-the-package-names | fzf -m) &&
    echo "$packages" &&
    npm i $(echo $packages)
}

# git branch fzf
function fbr {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | 
        fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Homebrew
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH

# Zsh completions
if [ -f $(brew --prefix)/etc/zsh_completion ]; then
. $(brew --prefix)/etc/zsh_completion
fi

# Set up Yarn home
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# thefuck
eval $(thefuck --alias)

# Set up pyenv
PATH=$(pyenv root)/shims:$PATH

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source $(pyenv root)/completions/pyenv.zsh

# Reset t alias
unalias t
# Reset tldr alias
unalias tldr

# Custom aliases
alias pfzf='fzf --preview "bat --style=numbers --color=always {}"'
alias vfzf='vim $(pfzf)'
alias cfzf='code $(pfzf)'
alias tb="nc termbin.com 9999"
alias ipinfo="curl ipinfo.io"
alias t="exa -n --long --tree --level=1"
alias c="clear"

# Zoxide
eval "$(zoxide init zsh)"

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
