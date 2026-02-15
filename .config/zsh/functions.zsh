function tm() {
  if [[ $# -gt 0 ]]; then
    tmux "$@"
    return
  fi
  if tmux has-session 2>/dev/null; then
    tmux attach
    return
  fi
  local save_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
  local save_file="$save_dir/$(/usr/bin/readlink "$save_dir/last" 2>/dev/null)"
  if [[ -f "$save_file" ]]; then
    local first=$(awk '/^pane/ {print $2; exit}' "$save_file")
    tmux new-session -d -s "${first:-main}"
    tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
    sleep 1
    tmux attach -t "${first:-main}"
  else
    tmux new-session
  fi
}
