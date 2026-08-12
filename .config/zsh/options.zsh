# Ignore EOF to prevent accidental shell exit
set -o ignoreeof

# Shell behavior
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt interactive_comments

# Set the primary keymap before plugins register their bindings.
bindkey -e

# Delete path segments individually with Ctrl+W
WORDCHARS=${WORDCHARS//[\/.]}
