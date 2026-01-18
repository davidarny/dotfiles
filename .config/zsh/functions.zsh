# Migrate npm global packages to a new Node.js version using fnm
#
# This function helps migrate all globally installed npm packages
# from one Node.js version to another using fnm (Fast Node Manager).
# It lists all global packages in the current version and reinstalls
# them in the target version.
#
# Usage:
#   migrate_npm_globals <target_version>
#
# Arguments:
#   target_version - The Node.js version to migrate packages to (e.g., "18" or "20.0.0")
#
# Example:
#   migrate_npm_globals 20
#   # -> migrates all global packages to Node.js 20.x
#
#   migrate_npm_globals 18.15.0
#   # -> migrates all global packages to Node.js 18.15.0
migrate_npm_globals() {
  local target="${1:?Usage: migrate_npm_globals <node_version>}"
  local packages
  packages="$(fnm exec --using="$target" npm ls -g --json \
    | jq -r '.dependencies // {} | to_entries[] | "\(.key)@\(.value.version)"')"
  if [[ -z "$packages" ]]; then
    echo "No global packages to migrate for Node $target."
    return 0
  fi
  xargs -r -n1 -I{} fnm exec --using="$target" npm i -g {} <<<"$packages"
}

# Refresh cached init scripts for shell tools.
zsh_refresh_init_cache() {
  local cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
  local refreshed=()
  mkdir -p "$cache_dir" 2>/dev/null

  if (( $+commands[fzf] )); then
    fzf --zsh >| "$cache_dir/fzf-init.zsh" 2>/dev/null && refreshed+=("fzf")
  fi

  if (( $+commands[zoxide] )); then
    zoxide init zsh >| "$cache_dir/zoxide-init.zsh" 2>/dev/null && refreshed+=("zoxide")
  fi

  if (( $+commands[starship] )); then
    starship init zsh --print-full-init >| "$cache_dir/starship-init.zsh" 2>/dev/null || \
      starship init zsh >| "$cache_dir/starship-init.zsh" 2>/dev/null
    [[ -s "$cache_dir/starship-init.zsh" ]] && refreshed+=("starship")
  fi

  if (( $+commands[fnm] )); then
    fnm env --use-on-cd --version-file-strategy=recursive >| "$cache_dir/fnm-env.zsh" 2>/dev/null && refreshed+=("fnm")
  fi

  if (( $+commands[pyenv] )); then
    pyenv init - >| "$cache_dir/pyenv-init.zsh" 2>/dev/null && refreshed+=("pyenv")
  fi

  if (( $+commands[op] )); then
    op completion zsh >| "$cache_dir/op-completion.zsh" 2>/dev/null && refreshed+=("op")
  fi

  if (( ${#refreshed[@]} > 0 )); then
    echo "Refreshed: ${refreshed[*]}"
  else
    echo "No tool caches refreshed."
  fi
}
