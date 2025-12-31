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

