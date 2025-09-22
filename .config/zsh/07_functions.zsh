# Migrate npm global packages to a new Node.js version using fnm
#
# This function helps migrate all globally installed npm packages
# from one Node.js version to another using fnm (Fast Node Manager).
# It lists all global packages in the current version and reinstalls
# them in the target version.
#
# Usage:
#   nmg <target_version>
#
# Arguments:
#   target_version - The Node.js version to migrate packages to (e.g., "18" or "20.0.0")
#
# Example:
#   nmg 20
#   # -> migrates all global packages to Node.js 20.x
#
#   nmg 18.15.0
#   # -> migrates all global packages to Node.js 18.15.0
function nmg {
  fnm exec --using=$1 npm ls --global --json \
    | jq -r '.dependencies | to_entries[] | .key+"@"+.value.version' \
    | xargs npm i -g
}
