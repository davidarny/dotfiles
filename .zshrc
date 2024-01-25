# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
export EDITOR=code

# if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
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
#fi

#if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then

# Set up starship
#eval "$(starship init zsh)"

#fi

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

source $ZSH/oh-my-zsh.sh

# Antigen
source /opt/homebrew/share/antigen/antigen.zsh

antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle reegnz/jq-zsh-plugin

antigen apply


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# NPM fzf
function fnpm {
    local packages
    packages=$(all-the-package-names | fzf -m) &&
    echo "$packages" &&
    npm i $(echo $packages)
}

# Git branch fzf
function fbr {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | 
        fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Batch rename
function brn {
    for file in *$1*; do mv "$file" "${file/$1/$2}"; done
}

# Minify svg files in a folder
function svgmin {
    svgo --config /Users/david_arutiunian/svgo.config.js -f $1 -o $2
}

# Copy package version
function cpver {
    echo -n $(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g') | pbcopy
}

# Scaffold react component strucutre
function crc {
    mkdir $1 && cd $1

    if [[ "$@" == *"-i"* ]]; then
        cat << EOF >> index.ts
export * from './${1}';
EOF
    fi

    if [[ "$@" == *"-s"* ]]; then
        cat << EOF >> $1.stories.tsx
import { ComponentMeta, ComponentStory } from '@storybook/react';

import { ${1} } from './${1}';

export default {
  component: ${1},
  title: 'components/${1}',
} as ComponentMeta<typeof ${1}>;

const Template: ComponentStory<typeof ${1}> = (args) => {
  return (
    <div className="story">
      <h2 className="story-title">Default</h2>
      <${1} {...args} />
    </div>
  );
};

export const Default = Template.bind({});
Default.args = {};
EOF
    fi

    cat << EOF >> $1.types.ts
export interface $1Props {
  className?: string;
}
EOF

    cat << EOF >> $1.module.scss
@import 'src/styles/services';
EOF

    cat << EOF >> $1.tsx
import { FC } from 'react';

import { ${1}Props } from './${1}.types';

import styles from './${1}.module.scss';

export const ${1}: FC<${1}Props> = ({ className }) => {
  return <div className={cn(styles.root, className)} />;
};
EOF

    cd ..
}

# Migrate npm global packages to new node version
function fnm_upgrade {
  fnm exec --using=$1 npm ls --global --json \
    | jq -r '.dependencies | to_entries[] | .key+"@"+.value.version' \
    | xargs npm i -g
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

# TheFuck
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

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

if command -v ngrok &>/dev/null; then
    eval "$(ngrok completion)"
fi

export PATH=$PATH:"$HOME/fvm/default/bin"

# Autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"

source /opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh

# fnm
export PATH="/Users/david_arutiunian/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
