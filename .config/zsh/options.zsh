# Ignore EOF to prevent accidental shell exit
set -o ignoreeof

# Shell behavior
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt interactive_comments

# Delete path segments individually with Ctrl+W
WORDCHARS='${WORDCHARS//[\/.]}'
