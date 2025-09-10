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

# Z.ai Claude API wrapper function
#
# This function provides a convenient wrapper for interacting with the Z.ai
# Claude API service. It sets up the necessary environment variables and
# calls the claude command with the provided arguments.
#
# Usage:
#   zai <prompt_or_query>
#
# Arguments:
#   prompt_or_query - The text prompt or query to send to the Claude API
#
# Environment Variables Set:
#   ANTHROPIC_BASE_URL - Points to Z.ai's Claude API endpoint
#   ANTHROPIC_AUTH_TOKEN - Authentication token for Z.ai service
#   ANTHROPIC_MODEL - Specifies the GLM-4.5 model to use
#
# Example:
#   zai "Explain how to use Git branches"
#   # -> Sends the prompt to Z.ai's Claude API using GLM-4.5 model
#
#   zai "Write a Python function to calculate fibonacci numbers"
#   # -> Gets code generation help from the AI model
#
# Prerequisites:
#   - claude command must be installed and available in PATH
#   - Valid Z.ai API credentials (configured in the function)
function zai {
  ANTHROPIC_BASE_URL='https://api.z.ai/api/anthropic' ANTHROPIC_AUTH_TOKEN='d7e9265e08924310aaad5a3268d33c07.qtKs1uOs5rizPoAX' ANTHROPIC_MODEL='glm-4.5' claude $1
}
