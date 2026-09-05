# Auto-sync Brewfile after install/uninstall
typeset -g _dotfiles_brewfile="${${(%):-%x}:A:h:h:h}/Brewfile"

function brew() {
  command brew "$@"
  local brew_status=$?

  if (( brew_status == 0 )) && [[ "$1" =~ ^(install|uninstall|remove|rmtree)$ ]]; then
    command brew bundle dump --file="$_dotfiles_brewfile" --force --brews --casks --cargo --uv --taps
  fi

  return $brew_status
}

# Parse dotenv data with Bun; never evaluate it as shell code.
typeset -g _dotfiles_dotenv_script="${${(%):-%x}:A:h:h:h}/bin/dotenv-export.mjs"

function dotenv() {
  command -v bun >/dev/null 2>&1 || {
    print -u2 'dotenv: bun is required'
    return 1
  }

  local _dotenv_data _dotenv_key _dotenv_value
  _dotenv_data=$(command bun --no-env-file --install=force "$_dotfiles_dotenv_script" "$@") || return $?

  while IFS= read -r -d '' _dotenv_key && IFS= read -r -d '' _dotenv_value; do
    if [[ "$_dotenv_key" == _dotenv_* ]]; then
      print -u2 'dotenv: cannot overwrite a reserved shell variable'
      return 1
    fi
    case "${parameters[$_dotenv_key]-}" in
      ''|scalar|scalar-export) ;;
      *)
        print -u2 'dotenv: cannot overwrite a typed or reserved shell variable'
        return 1
        ;;
    esac
  done <<< "$_dotenv_data"

  while IFS= read -r -d '' _dotenv_key && IFS= read -r -d '' _dotenv_value; do
    export "$_dotenv_key=$_dotenv_value" || return $?
  done <<< "$_dotenv_data"
}

# Print git remotes for every immediate git subdirectory
function grall() {
  local dir found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    print -P "%F{magenta}────────── $dir ──────────%f"
    (cd "$dir" && git -c color.ui=always remote -vv)
    echo
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}

# Git status for every immediate git subdirectory
function gsall() {
  local dir found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    print -P "%F{magenta}────────── $dir ──────────%f"
    (cd "$dir" && git -c color.ui=always status --branch --show-stash --untracked-files=all 2>&1)
    echo
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}

# Fetch + ff-only pull for every immediate git subdirectory
function gpall() {
  local dir found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    print -P "%F{magenta}────────── $dir ──────────%f"
    (cd "$dir" && git -c color.ui=always fetch --all --prune --tags && git pull --ff-only 2>&1)
    echo
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}
