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
