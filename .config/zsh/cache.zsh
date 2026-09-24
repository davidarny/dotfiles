# Source the output of a slow init command (`tool init zsh`, `tool completion
# zsh`) from a cache instead of running it on every start. The cache is keyed
# by the command line and rebuilt when the tool's binary is newer, so upgrades
# and changed flags take effect. Use it only for output that does not depend on
# the session: mise activate embeds $PATH and runs uncached.
# Usage: _eval_cached <command> [args...]
_eval_cached() {
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 1

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval/${${(j:_:)@}//[^A-Za-z0-9_-]/_}.zsh"
  if [[ ! -s $cache || ${bin:A} -nt $cache ]]; then
    # A per-shell temp file keeps shells that start together from mixing output.
    local tmp="$cache.$$"
    mkdir -p "${cache:h}"
    if ! "$@" >| "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      return 1
    fi
    mv -f "$tmp" "$cache"
  fi
  source "$cache"
}
