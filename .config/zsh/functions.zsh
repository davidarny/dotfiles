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

# Git repos overview in eza --git-repos style for every immediate git subdirectory
# One line per repo: folder, dirty status, branch, remotes, unpushed commits
# (unpushed counted from local remote refs, no fetch; needs a Nerd Font)
function gsall() {
  local dir l remotes unpushed oid branch stmark rem_joined st_disp br_disp rem_disp num_disp i
  local -a dirs lines sts branches remotes_col unpushed_col
  integer width=0 maxbranch=0 maxremote=0 maxnum=0 dirty brw

  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    dirs+=("$dir")
    (( ${#dir} > width )) && width=${#dir}
  done
  (( ${#dirs} )) || { print -P "%F{240}no git repos found in $PWD%f"; return }

  # eza colors: bold blue dir, green clean |, bold yellow dirty +, bold grey no commits
  local C_DIR=$'\e[1;34m' C_ICON=$'\e[34m' C_GREEN=$'\e[32m' C_DIRTY=$'\e[1;33m'
  local C_GREY=$'\e[1;90m' C_RED=$'\e[31m' C_YEL=$'\e[33m' C_DIM=$'\e[38;5;240m' C_R=$'\e[0m'
  local icon=$'\uf07b' ico_branch=$'\ue0a0' ico_remote=$'\uf0c2'

  for dir in $dirs; do
    dirty=0 branch='' oid=''
    lines=("${(f)$(git -C "$dir" status --porcelain=v2 --branch --untracked-files=all)}")
    for l in $lines; do
      if [[ $l == '1 '* || $l == '2 '* || $l == 'u '* || $l == '?'* ]]; then
        dirty=1
      elif [[ $l == '# branch.oid '* ]]; then
        oid=${l#'# branch.oid '}
      elif [[ $l == '# branch.head '* ]]; then
        branch=${l#'# branch.head '}
      fi
    done

    remotes=$(git -C "$dir" remote)
    unpushed=$(git -C "$dir" rev-list --count --branches --not --remotes 2>/dev/null)
    [[ -n "$unpushed" ]] || unpushed=0

    if (( dirty )); then
      stmark='+'
    elif [[ $oid == '(initial)' ]]; then
      stmark='-'
    else
      stmark='|'
    fi
    [[ $oid == '(initial)' || -z $branch ]] && branch='-'

    rem_joined=${remotes//$'\n'/, }
    [[ -z $rem_joined ]] && rem_joined='no remote'

    sts+=("$stmark")
    branches+=("$branch")
    remotes_col+=("$rem_joined")
    unpushed_col+=("$unpushed")
    (( ${#branch} > maxbranch )) && maxbranch=${#branch}
    (( ${#rem_joined} > maxremote )) && maxremote=${#rem_joined}
    (( ${#unpushed} > maxnum )) && maxnum=${#unpushed}
  done

  brw=$(( maxbranch + 2 ))  # dash rows have no icon, pad to icon+branch width
  for (( i=1; i<=${#dirs}; i++ )); do
    dir=${dirs[i]}
    case ${sts[i]} in
      +) st_disp="$C_DIRTY+$C_R" ;;
      -) st_disp="$C_GREY-$C_R" ;;
      *) st_disp="$C_GREEN|$C_R" ;;
    esac
    if [[ ${branches[i]} == '-' ]]; then
      br_disp="$C_GREY${(r:brw:)${branches[i]}}$C_R"
    else
      br_disp="$C_GREEN$ico_branch ${(r:maxbranch:)${branches[i]}}$C_R"
    fi
    if [[ ${remotes_col[i]} == 'no remote' ]]; then
      rem_disp="$C_RED$ico_remote ${(r:maxremote:)${remotes_col[i]}}$C_R"
    else
      rem_disp="$C_GREEN$ico_remote ${(r:maxremote:)${remotes_col[i]}}$C_R"
    fi
    if (( ${unpushed_col[i]} > 0 )); then
      num_disp="$C_YEL↑${(l:maxnum:)${unpushed_col[i]}}$C_R"
    else
      num_disp="$C_DIM↑${(l:maxnum:)${unpushed_col[i]}}$C_R"
    fi

    print -r -- "$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R $st_disp $br_disp   $rem_disp   $num_disp"
  done
}

# Fetch + ff-only pull for every immediate git subdirectory
# One line per repo with the result; skips repos without remote/upstream
function gpall() {
  local dir remotes fetch_out pull_out upd up_from up_to commits files cw fw detail summary i res
  local -a dirs kinds details
  integer width=0 nff=0 nok=0 nerr=0 nskip=0

  for dir in */; do
    [[ -d "$dir/.git" ]] || continue
    dirs+=("$dir")
    (( ${#dir} > width )) && width=${#dir}
  done
  (( ${#dirs} )) || { print -P "%F{240}no git repos found in $PWD%f"; return }

  local C_DIR=$'\e[1;34m' C_ICON=$'\e[34m' C_GREEN=$'\e[32m' C_RED=$'\e[31m' C_DIM=$'\e[38;5;240m' C_R=$'\e[0m'
  local icon=$'\uf07b' ico_ok=$'\uf00c' ico_err=$'\uf00d'

  for dir in $dirs; do
    remotes=$(git -C "$dir" remote)
    if [[ -z $remotes ]]; then
      kinds+=('skip'); details+=('no remote'); (( nskip++ ))
      continue
    fi
    if ! git -C "$dir" rev-parse -q --abbrev-ref '@{u}' >/dev/null 2>&1; then
      kinds+=('skip'); details+=('no upstream'); (( nskip++ ))
      continue
    fi

    fetch_out=$(git -C "$dir" fetch --all --prune --tags 2>&1)
    if (( $? != 0 )); then
      kinds+=('err')
      detail=${${(M)${(f)fetch_out}:#(fatal|error|warning):*}[1]}
      [[ -n $detail ]] || detail='fetch failed'
      details+=("$detail")
      (( nerr++ ))
      continue
    fi

    pull_out=$(git -C "$dir" pull --ff-only 2>&1)
    if (( $? != 0 )); then
      kinds+=('err')
      detail=${${(M)${(f)pull_out}:#(fatal|error|warning):*}[1]}
      [[ -n $detail ]] || detail='pull failed'
      details+=("$detail")
      (( nerr++ ))
      continue
    fi

    if [[ $pull_out == *'Already up to date'* ]]; then
      kinds+=('ok'); details+=('up to date'); (( nok++ ))
      continue
    fi

    # fast-forward: count commits from "Updating <old>..<new>" and changed files
    commits=''
    upd=${${(M)${(f)pull_out}:#Updating*}[1]}
    if [[ -n $upd ]]; then
      up_from=${${upd#Updating }%%..*}
      up_to=${${upd#Updating }##*..}
      commits=$(git -C "$dir" rev-list --count "${up_from}..${up_to}" 2>/dev/null)
    fi
    files=$(awk '/files? changed/ {print $1; exit}' <<<"$pull_out")
    detail='fast-forward'
    if [[ $commits == <-> ]]; then
      (( commits == 1 )) && cw=commit || cw=commits
      detail+=" · ${commits} ${cw}"
    fi
    if [[ $files == <-> ]]; then
      (( files == 1 )) && fw=file || fw=files
      detail+=" · ${files} ${fw}"
    fi

    kinds+=('ff'); details+=("$detail"); (( nff++ ))
  done

  for (( i=1; i<=${#dirs}; i++ )); do
    dir=${dirs[i]}
    case ${kinds[i]} in
      ok)  res="$C_GREEN$ico_ok$C_R $C_DIM${details[i]}$C_R" ;;
      ff)  res="$C_GREEN$ico_ok$C_R $C_GREEN${details[i]}$C_R" ;;
      err) res="$C_RED$ico_err$C_R $C_RED${details[i]}$C_R" ;;
      *)   res="$C_DIM·$C_R $C_DIM${details[i]}$C_R" ;;
    esac
    print -r -- "$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R  $res"
  done

  summary=''
  (( nok )) && summary+="$C_GREEN${nok} up to date$C_R · "
  (( nff )) && summary+="$C_GREEN${nff} updated$C_R · "
  (( nerr )) && summary+="$C_RED${nerr} failed$C_R · "
  (( nskip )) && summary+="$C_DIM${nskip} skipped$C_R · "
  summary=${summary% · }
  if [[ -n $summary ]]; then
    print -r -- "$C_DIM──$C_R  $summary"
  fi
}
