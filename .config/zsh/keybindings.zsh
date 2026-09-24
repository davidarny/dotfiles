# Match macOS text editing: Option+Arrow moves by word and Shift selects.

_zle_select_left() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-char
}

_zle_select_right() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-char
}

_zle_select_up() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle up-line
}

_zle_select_down() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle down-line
}

_zle_select_word_left() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-word
}

_zle_select_word_right() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-word
}

_zle_select_line_start() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle beginning-of-line
}

_zle_select_line_end() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle end-of-line
}

_zle_backspace() {
  if (( REGION_ACTIVE )); then
    zle kill-region
  elif (( ${+widgets[autopair-delete]} )); then
    zle autopair-delete
  else
    zle backward-delete-char
  fi
}

_zle_insert_newline() {
  LBUFFER+=$'\n'
}

zle -N _zle_select_left
zle -N _zle_select_right
zle -N _zle_select_up
zle -N _zle_select_down
zle -N _zle_select_word_left
zle -N _zle_select_word_right
zle -N _zle_select_line_start
zle -N _zle_select_line_end
zle -N _zle_backspace
zle -N _zle_insert_newline

bindkey '\e[1;2D' _zle_select_left
bindkey '\e[1;2C' _zle_select_right
bindkey '\e[1;2A' _zle_select_up
bindkey '\e[1;2B' _zle_select_down
bindkey '\e[1;4D' _zle_select_word_left
bindkey '\e[1;4C' _zle_select_word_right
bindkey '\e[1;10D' _zle_select_line_start
bindkey '\e[1;10C' _zle_select_line_end
bindkey '\e[1;5D' undefined-key
bindkey '\e[1;5C' undefined-key
bindkey -M emacs '\e' deactivate-region
bindkey -M emacs '^?' _zle_backspace
bindkey -M emacs '^H' _zle_backspace
# Shift+Enter: xterm form, and the CSI u form tmux sends with extended-keys always.
bindkey -M emacs '\e[27;2;13~' _zle_insert_newline
bindkey -M emacs '\e[13;2u' _zle_insert_newline

# /etc/zshrc binds Home, End, and Delete in the keymap that bindkey -e replaces.
# With ESC bound above, an unbound key sequence would type its tail into the line.
# Terminals send the CSI or SS3 form; tmux sends \e[1~ and \e[4~.
bindkey -M emacs '\e[3~' delete-char
bindkey -M emacs '\e[H' beginning-of-line
bindkey -M emacs '\eOH' beginning-of-line
bindkey -M emacs '\e[1~' beginning-of-line
bindkey -M emacs '\e[F' end-of-line
bindkey -M emacs '\eOF' end-of-line
bindkey -M emacs '\e[4~' end-of-line

# Edit the current command in $EDITOR with Ctrl-X.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs '^X' edit-command-line
