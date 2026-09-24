# Source the output of a slow init command (`tool init zsh`, `tool completion
# zsh`) from a cache instead of running it on every start. The cache is keyed
# by the command line, so changed flags get their own cache. Use it only for
# output that does not depend on the session: mise activate embeds $PATH and
# runs uncached. Delete ~/.cache/zsh/eval to force a rebuild.
#
# The cache is rebuilt when the resolved binary path changes or the binary is
# newer than the cache. Homebrew and mise keep a release's build time as the
# binary's mtime, so an upgrade can leave the binary older than the cache; its
# resolved path contains the version, so the first line of the cache records
# that path. It records the arguments too: the file name folds punctuation to
# _, so two command lines can share a cache file.
# Usage: _eval_cached <command> [args...]
_eval_cached() {
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 1

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval/${${(j:_:)@}//[^A-Za-z0-9_-]/_}.zsh"
  local stamp="# ${bin:A} ${(q)@[2,-1]}" cached_stamp
  [[ -s $cache ]] && IFS= read -r cached_stamp < "$cache"
  if [[ $cached_stamp != $stamp || ${bin:A} -nt $cache ]]; then
    # A per-shell temp file keeps shells that start together from mixing output.
    local tmp="$cache.$$"
    mkdir -p "${cache:h}"
    # command skips a function of the same name; a prompt would hang the start unseen.
    if ! { print -r -- "$stamp"; command "$@" </dev/null } >| "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      return 1
    fi
    mv -f "$tmp" "$cache"
  fi
  source "$cache"
}
