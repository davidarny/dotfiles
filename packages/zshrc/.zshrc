# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh"

export EDITOR=nvim

autoload -U compinit
compinit -i

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="/Users/david_arutiunian/.oh-my-zsh"

plugins=(
    git
    gitfast
    gitignore
    fnm
    brew
    httpie
    common-aliases
    command-not-found
    fzf
    gh
    jira
    macos
    zsh-autosuggestions
    zsh-syntax-highlighting
    gitgo
)

export JIRA_URL="https://jira.dats.tech"
export JIRA_NAME="d.arutyunyan"
export JIRA_RAPID_BOARD=true
export JIRA_RAPID_VIEW=687
export JIRA_DEFAULT_ACTION=dashboard

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

export FZF_DEFAULT_OPTS="
	--color=fg:#908caa,bg:#242136,hl:#ebbcba
	--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
	--color=border:#403d52,header:#31748f,gutter:#191724
	--color=spinner:#f6c177,info:#9ccfd8,separator:#403d52
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -f "$HOME/.config/zsh/functions.zsh" ]] && source "$HOME/.config/zsh/functions.zsh"
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/opt/python@3.10/libexec/bin:$PATH

source /opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh
if [ -f $(brew --prefix)/etc/zsh_completion ]; then
  . $(brew --prefix)/etc/zsh_completion
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
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

# Where should I put you?
bindkey -s ^f "tmux-sessionizer\n"

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh"
