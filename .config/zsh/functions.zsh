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

# Auto-sync the global skills manifest after add/remove/update
typeset -g _dotfiles_skills_manifest="${${(%):-%x}:A:h:h:h}/.agents/skills.json"
typeset -g _dotfiles_skills_dump_script="${${(%):-%x}:A:h:h:h}/bin/skills-dump.ts"

function skills() {
  local lock="$HOME/.agents/.skill-lock.json" before=''
  [[ -f "$lock" ]] && before=$(<"$lock")

  command skills "$@"
  local skills_status=$?

  if (( skills_status == 0 )) && [[ "$1" =~ ^(add|a|remove|rm|update|upgrade)$ ]]; then
    print -r -- "$before" | command bun "$_dotfiles_skills_dump_script" "$lock" "$_dotfiles_skills_manifest"
  fi

  return $skills_status
}

# Parse dotenv data with Bun; never evaluate it as shell code.
typeset -g _dotfiles_dotenv_script="${${(%):-%x}:A:h:h:h}/bin/dotenv-export.ts"

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

# Pad text to a column width and assign it to <var>
# Values wider than the column keep their full length (they shift the row, never get cut)
# Usage: _dotfiles_pad <var> <width> <text> [l]   # l = right-align, default left-align
function _dotfiles_pad() {
  local -i w=$2
  local t=$3
  if (( ${#t} >= w )); then
    typeset -g "$1=$t"
  elif [[ $4 == l ]]; then
    typeset -g "$1=${(l:w:)t}"
  else
    typeset -g "$1=${(r:w:)t}"
  fi
}

# Git repos overview in eza --git-repos style for every immediate git subdirectory
# One line per repo: folder, dirty status, branch, remotes, unpushed commits
# (unpushed counted from local remote refs, no fetch; needs a Nerd Font)
function gsall() {
  local dir l remotes unpushed oid branch stmark rem_joined st_disp br_disp rem_disp num_disp
  local br_pad rem_pad num_pad
  local -a dirs lines
  integer width=0 dirty
  # fixed column widths: rows print as each repo is read, nothing is buffered
  integer wbranch=16 wremote=12 wnum=2 wbranchdash=18  # dash rows have no icon: wbranch + 2

  for dir in */(N); do
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

    case $stmark in
      +) st_disp="$C_DIRTY+$C_R" ;;
      -) st_disp="$C_GREY-$C_R" ;;
      *) st_disp="$C_GREEN|$C_R" ;;
    esac
    if [[ $branch == '-' ]]; then
      _dotfiles_pad br_pad $wbranchdash "$branch"
      br_disp="$C_GREY${br_pad}$C_R"
    else
      _dotfiles_pad br_pad $wbranch "$branch"
      br_disp="$C_GREEN$ico_branch ${br_pad}$C_R"
    fi
    _dotfiles_pad rem_pad $wremote "$rem_joined"
    if [[ $rem_joined == 'no remote' ]]; then
      rem_disp="$C_RED$ico_remote ${rem_pad}$C_R"
    else
      rem_disp="$C_GREEN$ico_remote ${rem_pad}$C_R"
    fi
    _dotfiles_pad num_pad $wnum "$unpushed" l
    if (( unpushed > 0 )); then
      num_disp="$C_YEL↑${num_pad}$C_R"
    else
      num_disp="$C_DIM↑${num_pad}$C_R"
    fi

    print -r -- "$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R $st_disp $br_disp   $rem_disp   $num_disp"
  done
}

# Fetch + ff-only pull for every immediate git subdirectory
# One line per repo with the result; skips repos without remote/upstream
function gpall() {
  local dir remotes fetch_out pull_out upd up_from up_to commits files cw fw detail summary row
  local -a dirs
  integer width=0 nff=0 nok=0 nerr=0 nskip=0

  for dir in */(N); do
    [[ -d "$dir/.git" ]] || continue
    dirs+=("$dir")
    (( ${#dir} > width )) && width=${#dir}
  done
  (( ${#dirs} )) || { print -P "%F{240}no git repos found in $PWD%f"; return }

  local C_DIR=$'\e[1;34m' C_ICON=$'\e[34m' C_GREEN=$'\e[32m' C_RED=$'\e[31m' C_DIM=$'\e[38;5;240m' C_R=$'\e[0m'
  local icon=$'\uf07b' ico_ok=$'\uf00c' ico_err=$'\uf00d'

  for dir in $dirs; do
    row="$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R "

    remotes=$(git -C "$dir" remote)
    if [[ -z $remotes ]]; then
      print -r -- "$row $C_DIM·$C_R $C_DIM"'no remote'"$C_R"
      (( nskip++ ))
      continue
    fi
    if ! git -C "$dir" rev-parse -q --abbrev-ref '@{u}' >/dev/null 2>&1; then
      print -r -- "$row $C_DIM·$C_R $C_DIM"'no upstream'"$C_R"
      (( nskip++ ))
      continue
    fi

    fetch_out=$(git -C "$dir" fetch --all --prune --tags 2>&1)
    if (( $? != 0 )); then
      detail=${${(M)${(f)fetch_out}:#(fatal|error|warning):*}[1]}
      [[ -n $detail ]] || detail='fetch failed'
      print -r -- "$row $C_RED$ico_err$C_R $C_RED${detail}$C_R"
      (( nerr++ ))
      continue
    fi

    pull_out=$(git -C "$dir" pull --ff-only 2>&1)
    if (( $? != 0 )); then
      detail=${${(M)${(f)pull_out}:#(fatal|error|warning):*}[1]}
      [[ -n $detail ]] || detail='pull failed'
      print -r -- "$row $C_RED$ico_err$C_R $C_RED${detail}$C_R"
      (( nerr++ ))
      continue
    fi

    if [[ $pull_out == *'Already up to date'* ]]; then
      print -r -- "$row $C_GREEN$ico_ok$C_R $C_DIM"'up to date'"$C_R"
      (( nok++ ))
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

    print -r -- "$row $C_GREEN$ico_ok$C_R $C_GREEN${detail}$C_R"
    (( nff++ ))
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

# CodeGraph init (first time) or full reindex for every immediate git subdirectory
# One line per repo with the result; needs the codegraph CLI
function cgall() {
  setopt localoptions extendedglob
  local dir status_json out detail res summary files nodes fw nw word t0 secs kind
  local word_pad files_pad fw_pad nodes_pad nw_pad secs_pad
  local -a dirs
  integer width=0 ninit=0 nidx=0 nerr=0
  # fixed column widths: results stream as each repo finishes, nothing is buffered
  integer wword=11 wfiles=4 wfw=5 wnodes=5 wnw=7 wsecs=5

  if ! command -v codegraph >/dev/null 2>&1; then
    print -u2 'cgall: codegraph is required'
    return 1
  fi
  zmodload -F zsh/datetime b:strftime p:EPOCHREALTIME 2>/dev/null

  for dir in */(N); do
    [[ -d "$dir/.git" ]] || continue
    dirs+=("$dir")
    (( ${#dir} > width )) && width=${#dir}
  done
  (( ${#dirs} )) || { print -P "%F{240}no git repos found in $PWD%f"; return }

  local C_DIR=$'\e[1;34m' C_ICON=$'\e[34m' C_GREEN=$'\e[32m' C_RED=$'\e[31m' C_DIM=$'\e[38;5;240m' C_R=$'\e[0m'
  local icon=$'' ico_ok=$'' ico_err=$''

  for dir in $dirs; do
    status_json=$(codegraph --no-color status --json "$dir" 2>/dev/null)
    if [[ $status_json == *'"initialized":true'* ]]; then
      kind='index'
    else
      kind='init'
    fi

    t0=$EPOCHREALTIME
    if [[ $kind == 'init' ]]; then
      out=$(codegraph --no-color init -y "$dir" 2>&1)
    else
      out=$(codegraph --no-color index -q "$dir" 2>&1)
    fi
    if (( $? != 0 )); then
      detail=${${(M)${(f)out}:#*([Ee]rror|[Ff]atal|failed)*}[1]}
      [[ -n $detail ]] || detail=${${(f)out}[-1]}
      detail=${${detail##[[:space:]│┃╭╰┌└─]##}%%[[:space:]]##}
      [[ -n $detail ]] || detail="${kind} failed"
      (( ${#detail} > 60 )) && detail="${detail[1,59]}…"
      print -r -- "$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R  $C_RED$ico_err$C_R $C_RED${detail}$C_R"
      (( nerr++ ))
      continue
    fi
    printf -v secs '%.1fs' $(( EPOCHREALTIME - t0 ))

    status_json=$(codegraph --no-color status --json "$dir" 2>/dev/null)
    files=${${status_json##*\"fileCount\":}%%,*}
    nodes=${${status_json##*\"nodeCount\":}%%,*}
    [[ $files == <-> ]] || files=0
    [[ $nodes == <-> ]] || nodes=0
    (( files == 1 )) && fw=file || fw=files
    (( nodes == 1 )) && nw=symbol || nw=symbols
    if [[ $kind == 'init' ]]; then
      word='initialized'; (( ninit++ ))
    else
      word='reindexed'; (( nidx++ ))
    fi

    _dotfiles_pad word_pad $wword "$word"
    _dotfiles_pad files_pad $wfiles "$files" l
    _dotfiles_pad fw_pad $wfw "$fw"
    _dotfiles_pad nodes_pad $wnodes "$nodes" l
    _dotfiles_pad nw_pad $wnw "$nw"
    _dotfiles_pad secs_pad $wsecs "$secs" l
    detail="${word_pad} · ${files_pad} ${fw_pad} · ${nodes_pad} ${nw_pad} · ${secs_pad}"
    if [[ $kind == 'init' ]]; then
      res="$C_GREEN$ico_ok$C_R $C_GREEN${detail}$C_R"
    else
      res="$C_GREEN$ico_ok$C_R $C_DIM${detail}$C_R"
    fi
    print -r -- "$C_ICON$icon$C_R $C_DIR${(r:width:)dir}$C_R  $res"
  done

  summary=''
  (( ninit )) && summary+="$C_GREEN${ninit} initialized$C_R · "
  (( nidx )) && summary+="$C_GREEN${nidx} reindexed$C_R · "
  (( nerr )) && summary+="$C_RED${nerr} failed$C_R · "
  summary=${summary% · }
  if [[ -n $summary ]]; then
    print -r -- "$C_DIM──$C_R  $summary"
  fi
}
