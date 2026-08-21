# Auto-sync Brewfile after install/uninstall
typeset -g _dotfiles_brewfile="${${(%):-%x}:A:h:h:h}/Brewfile"

function brew() {
  command brew "$@"
  local brew_status=$?

  if (( brew_status == 0 )) && [[ "$1" =~ ^(install|uninstall|remove|rmtree)$ ]]; then
    gum spin --title "Syncing Brewfile" --show-error -- \
      brew bundle dump --file="$_dotfiles_brewfile" --force --brews --casks --cargo --uv --taps
  fi

  return $brew_status
}

# Print git remotes for every immediate git subdirectory
function grall() {
  local dir found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    if command -v gum >/dev/null 2>&1; then
      printf '%s\n\n%s\n' "$(CLICOLOR_FORCE=1 gum style --bold --foreground=4 "${dir%/}")" "$(cd "$dir" && git remote -vv)" \
        | gum style --border=rounded --border-foreground=8 --padding='0 2' --no-strip-ansi
      echo
    else
      print -P "%F{magenta}────────── $dir ──────────%f"
      (cd "$dir" && git remote -vv)
      echo
    fi
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}

# Git status for every immediate git subdirectory
function gsall() {
  local dir out found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    out=$(cd "$dir" && git -c color.ui=always status --branch --show-stash --untracked-files=all 2>&1)
    if command -v gum >/dev/null 2>&1; then
      printf '%s\n\n%s\n' "$(CLICOLOR_FORCE=1 gum style --bold --foreground=4 "${dir%/}")" "$out" \
        | gum style --border=rounded --border-foreground=8 --padding='0 2' --no-strip-ansi
      echo
    else
      print -P "%F{magenta}────────── $dir ──────────%f"
      print -r -- "$out"
      echo
    fi
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}

# Fetch + ff-only pull for every immediate git subdirectory
function gpall() {
  local dir out found=0
  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    out=$(cd "$dir" && git fetch --all --prune --tags && git pull --ff-only 2>&1)
    if command -v gum >/dev/null 2>&1; then
      printf '%s\n\n%s\n' "$(CLICOLOR_FORCE=1 gum style --bold --foreground=4 "${dir%/}")" "$out" \
        | gum style --border=rounded --border-foreground=8 --padding='0 2' --no-strip-ansi
      echo
    else
      print -P "%F{magenta}────────── $dir ──────────%f"
      print -r -- "$out"
      echo
    fi
  done
  (( found )) || print -P "%F{240}no git repos found in $PWD%f"
}
