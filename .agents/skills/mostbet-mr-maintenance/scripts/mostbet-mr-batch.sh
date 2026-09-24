#!/usr/bin/env bash
# Проверяет и перебазирует Mostbet MR; отправляет подготовленные SHA с точным lease.
# Конфликты остаются в worktree для семантического разрешения агентом.
set -o pipefail

PROJECT='datsteam%2Fmostbet%2Fmostbet_next'
HOST='gitlab.dats.tech'
MODE=''
ASSIGNEE=''
TARGET='master'
SOURCE_BRANCH=''
EXPECTED_REMOTE=''
PREPARED_SHA=''
FAILED=0

usage() {
  cat <<'EOF'
Usage:
  mostbet-mr-batch.sh audit --assignee <username> [--target <branch>]
  mostbet-mr-batch.sh rebase --assignee <username> [--target <branch>]
  mostbet-mr-batch.sh push --assignee <username> --branch <KEY> --expected-remote <sha> --prepared-sha <sha> [--target <branch>]

Run from mostbet-next. Requires git, glab, jq and curl.
Rebase prepares clean sibling <repo-name>-<JIRA-KEY> checkouts and prints source/target/prepared SHAs.
Run required project checks before push, then pass the original remote and verified prepared SHA.
Push verifies the current MR, local head and target ancestry, then uses the explicit remote SHA lease.
EOF
}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
fail() { printf '%s\n' "$*"; FAILED=1; }
while [ "$#" -gt 0 ]; do
  case "$1" in
    audit|rebase|push) [ -z "$MODE" ] || die 'choose one mode'; MODE="$1"; shift ;;
    --assignee|--target|--branch|--expected-remote|--prepared-sha)
      [ "$#" -ge 2 ] && [ -n "$2" ] || die "missing value for $1"
      case "$1" in
        --assignee) ASSIGNEE="$2" ;; --target) TARGET="$2" ;; --branch) SOURCE_BRANCH="$2" ;;
        --expected-remote) EXPECTED_REMOTE="$2" ;; --prepared-sha) PREPARED_SHA="$2" ;;
      esac
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[ -n "$MODE" ] && [ -n "$ASSIGNEE" ] || die 'mode and --assignee are required'
case "$ASSIGNEE" in *[!A-Za-z0-9._-]*) die 'invalid assignee' ;; esac
for cmd in git glab jq curl; do command -v "$cmd" >/dev/null 2>&1 || die "missing command: $cmd"; done
git check-ref-format "refs/heads/$TARGET" >/dev/null || die 'invalid target branch'
if [ "$MODE" = push ]; then
  [[ "$SOURCE_BRANCH" =~ ^[A-Z]+-[0-9]+$ ]] || die 'push needs --branch with an exact Jira key'
  [[ "$EXPECTED_REMOTE" =~ ^[0-9a-f]{40}$|^[0-9a-f]{64}$ ]] || die 'push needs --expected-remote with the original full SHA'
  [[ "$PREPARED_SHA" =~ ^[0-9a-f]{40}$|^[0-9a-f]{64}$ ]] || die 'push needs --prepared-sha with the verified full SHA'
fi
REPO_ROOT="$(git rev-parse --show-toplevel)" || die 'run from mostbet-next'
cd "$REPO_ROOT" || die 'cannot enter repository'
REPO_PARENT="$(dirname "$REPO_ROOT")"
REPO_NAME="$(basename "$REPO_ROOT")"
REMOTE="$(git remote get-url origin)" || die 'missing origin'
case "${REMOTE%.git}" in
  git@gitlab.dats.tech:datsteam/mostbet/mostbet_next|https://gitlab.dats.tech/datsteam/mostbet/mostbet_next|ssh://git@gitlab.dats.tech/datsteam/mostbet/mostbet_next) ;;
  *) die 'origin must be the Mostbet Next project on gitlab.dats.tech' ;;
esac

curl --silent --show-error --fail --connect-timeout 5 --max-time 10 https://jira.dats.tech/rest/api/2/serverInfo |
  jq -e '.baseUrl == "https://jira.dats.tech"' >/dev/null || die 'Jira preflight failed; check GlobalProtect before retrying'
git fetch origin --prune || die 'cannot fetch origin'
git show-ref --verify --quiet "refs/remotes/origin/$TARGET" || die 'remote target is missing'
BASE="$(git rev-parse "origin/$TARGET")" || die 'cannot resolve target'
MRS="$(glab api --hostname "$HOST" --paginate "projects/$PROJECT/merge_requests?state=opened&assignee_username=$ASSIGNEE&scope=all&per_page=100" | jq -sr 'add // [] | .[] | [.iid,.source_branch,.target_branch,.web_url] | @tsv')" || die 'cannot list MRs'

existing_worktree() {
  git -c core.quotePath=false worktree list --porcelain | awk -v ref="refs/heads/$1" '
    /^worktree / { path = substr($0, 10) }
    /^branch / && substr($0, 8) == ref { print path }
  '
}
is_clean() {
  local state
  state="$(git -C "$1" status --porcelain --untracked-files=all)" || return 1
  [ -z "$state" ] || return 1
  [ ! -d "$(git -C "$1" rev-parse --git-path rebase-merge)" ] &&
    [ ! -d "$(git -C "$1" rev-parse --git-path rebase-apply)" ] &&
    ! git -C "$1" rev-parse --verify -q MERGE_HEAD >/dev/null
}
if [ "$MODE" = push ]; then
  glab auth status --hostname "$HOST" || die 'GitLab authentication failed'
  glab api --hostname "$HOST" user | jq -er '.username | select(type == "string" and length > 0)' || die 'cannot verify GitLab actor'
  iid="$(printf '%s\n' "$MRS" | awk -F '\t' -v b="$SOURCE_BRANCH" -v t="$TARGET" '$2==b && $3==t {print $1}')"
  [[ "$iid" =~ ^[0-9]+$ ]] || die 'expected exactly one open assigned MR with this source and target'
  branch="$SOURCE_BRANCH"
  source="$EXPECTED_REMOTE"
  prepared="$PREPARED_SHA"
    worktree="$(existing_worktree "$branch")"
    current="$(git rev-parse --verify "refs/heads/$branch" 2>/dev/null)"
    if [ "$current" != "$prepared" ] || { [ -n "$worktree" ] && ! is_clean "$worktree"; }; then
      die "LOCAL_CHANGED $iid $branch"
    fi
    if ! git merge-base --is-ancestor "$BASE" "$prepared"; then
      die "TARGET_CHANGED $iid $branch"
    fi
    remote="$(git ls-remote --exit-code origin "refs/heads/$branch" | awk '{print $1}')" || die "MISSING_REMOTE $iid $branch"
    if [ "$remote" = "$prepared" ]; then printf 'UNCHANGED %s %s\n' "$iid" "$branch"; exit 0; fi
    [ "$remote" = "$source" ] || die "REMOTE_CHANGED $iid $branch"
    if ! git push "--force-with-lease=refs/heads/$branch:$source" origin "$prepared:refs/heads/$branch"; then
      die "PUSH_FAILED $iid $branch"
    fi
    remote="$(git ls-remote --exit-code origin "refs/heads/$branch" | awk '{print $1}')" || die "VERIFY_FAILED $iid $branch"
    if [ "$remote" = "$prepared" ]; then printf 'PUSHED %s %s\n' "$iid" "$branch"; else fail "VERIFY_FAILED $iid $branch"; fi
else
  while IFS=$'\t' read -r iid branch target url; do
    [ -n "$iid" ] || continue
    if [ "$target" != "$TARGET" ]; then printf 'SKIP_TARGET %s %s %s\n' "$iid" "$branch" "$target"; continue; fi
    source="$(git rev-parse --verify "refs/remotes/origin/$branch" 2>/dev/null)" || { fail "MISSING_REMOTE $iid $branch"; continue; }
    worktree="$(existing_worktree "$branch")"
    if [ "$MODE" = audit ]; then
      if git merge-base --is-ancestor "$BASE" "$source"; then state=current; else state=rebase-needed; fi
      if [ -n "$worktree" ] && ! is_clean "$worktree"; then state="$state,dirty"; fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$iid" "$branch" "$target" "$state" "${worktree:--}"
      continue
    fi
    if ! [[ "$branch" =~ ^[A-Z]+-[0-9]+$ ]]; then fail "INVALID_BRANCH $iid $branch"; continue; fi
    local_head="$(git rev-parse --verify "refs/heads/$branch" 2>/dev/null)"
    if [ -n "$local_head" ] && [ "$local_head" != "$source" ]; then fail "SKIP_LOCAL_DIVERGED $iid $branch"; continue; fi
    if git merge-base --is-ancestor "$BASE" "$source"; then
      printf 'ALREADY_CURRENT %s %s\n' "$iid" "$branch"
      continue
    fi
    if [ -n "$worktree" ]; then
      if [ "$worktree" != "$REPO_PARENT/$REPO_NAME-$branch" ]; then fail "SKIP_WORKTREE $iid $branch $worktree"; continue; fi
    else
      worktree="$REPO_PARENT/$REPO_NAME-$branch"
      if [ -e "$worktree" ] || [ -L "$worktree" ]; then fail "SKIP_PATH_EXISTS $iid $branch"; continue; fi
      if [ -n "$local_head" ]; then
        git worktree add "$worktree" "$branch" || { fail "CREATE_FAILED $iid $branch"; continue; }
      else
        git worktree add -b "$branch" "$worktree" "$source" || { fail "CREATE_FAILED $iid $branch"; continue; }
      fi
    fi
    if ! is_clean "$worktree"; then fail "SKIP_DIRTY $iid $branch"; continue; fi
    if ! git -C "$worktree" rebase "$BASE"; then fail "CONFLICT $iid $branch $worktree"; continue; fi
    if ! is_clean "$worktree" || ! git -C "$worktree" diff --check || ! git -C "$worktree" merge-base --is-ancestor "$BASE" HEAD; then
      fail "VERIFY_FAILED $iid $branch"; continue
    fi
    prepared="$(git -C "$worktree" rev-parse HEAD)" || die 'cannot read prepared head'
    printf 'PREPARED\t%s\t%s\t%s\t%s\t%s\t%s\n' "$iid" "$branch" "$source" "$BASE" "$prepared" "$worktree"
  done <<< "$MRS"
fi
exit "$FAILED"
