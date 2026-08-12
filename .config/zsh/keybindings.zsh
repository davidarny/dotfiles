# Match macOS text editing: Option+Arrow moves by word and Shift selects.
_zle_select_left() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-char
}

_zle_select_right() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-char
}

_zle_select_word_left() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-word
}

_zle_select_word_right() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-word
}

zle -N _zle_select_left
zle -N _zle_select_right
zle -N _zle_select_word_left
zle -N _zle_select_word_right

bindkey '\e[1;2D' _zle_select_left
bindkey '\e[1;2C' _zle_select_right
bindkey '\e[1;4D' _zle_select_word_left
bindkey '\e[1;4C' _zle_select_word_right
bindkey '\e[1;5D' undefined-key
bindkey '\e[1;5C' undefined-key
bindkey -M emacs '\e' deactivate-region

# Edit the current command in $EDITOR with Ctrl-X.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs '^X' edit-command-line
