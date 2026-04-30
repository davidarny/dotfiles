# Antidote configuration
export ANTIDOTE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}/antidote"

for antidote_script in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" \
  "/usr/local/opt/antidote/share/antidote/antidote.zsh"; do
  [[ -f "$antidote_script" ]] && source "$antidote_script" && break
done
unset antidote_script

_antidote_load_bundle() {
  local antidote_plugins="$1"
  local antidote_bundle="$2"
  local antidote_dependency="${3:-$antidote_plugins}"
  local antidote_bundle_tmp="${antidote_bundle}.tmp"

  [[ -f "$antidote_plugins" ]] || return

  if [[ ! -f "$antidote_bundle" || "$antidote_plugins" -nt "$antidote_bundle" || ( -f "$antidote_dependency" && "$antidote_dependency" -nt "$antidote_bundle" ) ]]; then
    mkdir -p "${antidote_bundle:h}"
    if antidote bundle <"$antidote_plugins" >|"$antidote_bundle_tmp"; then
      mv -f "$antidote_bundle_tmp" "$antidote_bundle"
    else
      rm -f "$antidote_bundle_tmp"
      return 1
    fi
  fi

  [[ -f "$antidote_bundle" ]] && source "$antidote_bundle"
}

# Plugin configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Load Zsh plugins using Antidote.
if command -v antidote >/dev/null 2>&1; then
  _antidote_load_bundle \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/antidote/plugins.txt" \
    "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/antidote-plugins.zsh" \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/plugins.zsh"
fi
