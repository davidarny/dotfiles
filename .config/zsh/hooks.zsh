# Notify on long-running commands via noti (only when terminal is unfocused)
NOTI_THRESHOLD=30

_noti_preexec() {
  _noti_cmd="$1"
  _noti_start=$EPOCHSECONDS
}

_noti_precmd() {
  [[ -z "$_noti_start" ]] && return
  local elapsed=$(( EPOCHSECONDS - _noti_start ))
  if (( elapsed >= NOTI_THRESHOLD )) && ! _noti_terminal_focused; then
    noti -t "${_noti_cmd%% *}" -m "Completed in ${elapsed}s" &>/dev/null &!
  fi
  unset _noti_start _noti_cmd
}

# Check if the frontmost macOS app is an ancestor of this shell.
# Works with any terminal (Ghostty, iTerm2, Terminal.app, etc.) and tmux.
_noti_terminal_focused() {
  local front_pid
  front_pid=$(osascript -e \
    'tell application "System Events" to unix id of first application process whose frontmost is true' \
    2>/dev/null) || return 1
  local pid
  if [[ -n "$TMUX" ]]; then
    pid=$(tmux display-message -p '#{client_pid}' 2>/dev/null) || pid=$$
  else
    pid=$$
  fi
  while (( pid > 1 )); do
    (( pid == front_pid )) && return 0
    pid=$(ps -o ppid= -p $pid 2>/dev/null | tr -d ' ')
  done
  return 1
}

if command -v noti >/dev/null 2>&1; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _noti_preexec
  add-zsh-hook precmd _noti_precmd
fi
