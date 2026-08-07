#!/bin/sh

set -eu

die() {
  printf 'regenerate-commits: %s\n' "$*" >&2
  exit 1
}

if [ "$#" -ne 4 ]; then
  die 'expected range start, range end, author name, and author email'
fi

range_from=$1
range_to=$2
author_name=$3
author_email=$4

command -v git >/dev/null 2>&1 || die 'git is required'

[ -n "$author_name" ] || die 'author name cannot be empty'
[ -n "$author_email" ] || die 'author email cannot be empty'

if [ -n "$(git status --porcelain)" ]; then
  die 'working tree must be clean before rewriting history'
fi

if ! branch=$(git symbolic-ref --quiet --short HEAD); then
  die 'HEAD must point to a local branch'
fi

original_ref="refs/original/refs/heads/$branch"
if git show-ref --verify --quiet "$original_ref"; then
  die "temporary filter-branch ref already exists: $original_ref"
fi

selection='all commits'
# LazyGit exposes the cursor commit as a one-item range when no range is active.
if [ -z "$range_from" ] && [ -z "$range_to" ]; then
  selected_commits=$(git rev-list --topo-order "$branch")
elif [ -n "$range_from" ] && [ "$range_from" = "$range_to" ]; then
  selected_commits=$(git rev-list --topo-order "$branch")
elif [ -n "$range_from" ] && [ -n "$range_to" ] && [ "$range_from" != "$range_to" ]; then
  if ! from_sha=$(git rev-parse --verify "$range_from^{commit}" 2>/dev/null); then
    die "selected range start is not a commit: $range_from"
  fi
  if ! to_sha=$(git rev-parse --verify "$range_to^{commit}" 2>/dev/null); then
    die "selected range end is not a commit: $range_to"
  fi
  if ! git merge-base --is-ancestor "$from_sha" "$branch"; then
    die 'selected range is outside the checked-out branch'
  fi
  if ! git merge-base --is-ancestor "$to_sha" "$branch"; then
    die 'selected range is outside the checked-out branch'
  fi

  if git merge-base --is-ancestor "$from_sha" "$to_sha"; then
    range_start=$from_sha
    range_end=$to_sha
  elif git merge-base --is-ancestor "$to_sha" "$from_sha"; then
    range_start=$to_sha
    range_end=$from_sha
  else
    die 'selected commits must belong to one ancestry path'
  fi

  if parent_sha=$(git rev-parse --verify "$range_start^" 2>/dev/null); then
    selected_commits=$(git rev-list --topo-order --ancestry-path "$parent_sha..$range_end")
  else
    selected_commits=$(git rev-list --topo-order "$range_end")
  fi
  selection="selected range $range_start..$range_end"
else
  die 'LazyGit returned an incomplete commit range'
fi

[ -n "$selected_commits" ] || die 'no commits matched the requested scope'

export BIZ_REGENERATE_AUTHOR_NAME="$author_name"
export BIZ_REGENERATE_AUTHOR_EMAIL="$author_email"
export BIZ_REGENERATE_SELECTED_COMMITS="$selected_commits"

if ! FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --env-filter '
  selected=false
  for selected_commit in $BIZ_REGENERATE_SELECTED_COMMITS; do
    if [ "$selected_commit" = "$GIT_COMMIT" ]; then
      selected=true
      break
    fi
  done

  if [ "$selected" = true ]; then
    GIT_AUTHOR_NAME="$BIZ_REGENERATE_AUTHOR_NAME"
    GIT_AUTHOR_EMAIL="$BIZ_REGENERATE_AUTHOR_EMAIL"
    GIT_COMMITTER_NAME="$BIZ_REGENERATE_AUTHOR_NAME"
    GIT_COMMITTER_EMAIL="$BIZ_REGENERATE_AUTHOR_EMAIL"
    export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  fi
' -- "$branch"; then
  die "history rewrite failed; inspect $original_ref before retrying"
fi

if ! git update-ref -d "$original_ref"; then
  die "history was rewritten, but the temporary ref could not be removed: $original_ref"
fi

printf 'Regenerated %s on %s as %s <%s>.\n' "$selection" "$branch" "$author_name" "$author_email"
