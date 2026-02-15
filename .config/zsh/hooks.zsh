# Notify on long-running commands via noti
NOTI_THRESHOLD=30
_NOTI_IGNORE=(nvim vim vi neovim lazygit claude codex htop btop top less more man ssh tmux)

_noti_preexec() {
  _noti_cmd="$1"
  _noti_start=$EPOCHSECONDS
}

_noti_precmd() {
  [[ -z "$_noti_start" ]] && return
  local cmd="${_noti_cmd%% *}"
  local elapsed=$(( EPOCHSECONDS - _noti_start ))
  if (( elapsed >= NOTI_THRESHOLD )) && (( ! ${_NOTI_IGNORE[(Ie)$cmd]} )); then
    noti -t "$cmd" -m "Completed in ${elapsed}s" &>/dev/null &!
  fi
  unset _noti_start _noti_cmd
}

if command -v noti >/dev/null 2>&1; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _noti_preexec
  add-zsh-hook precmd _noti_precmd
fi
