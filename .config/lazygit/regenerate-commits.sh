#!/bin/sh
# Rewrite the author and committer of the selected commits on the checked-out
# branch. LazyGit passes the cursor commit as a one-item range when no range is
# selected, so a single commit rewrites only that commit. Commits that any
# remote branch already has are refused: rewriting them would force-push over
# shared history.

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
[ -n "$range_from" ] && [ -n "$range_to" ] || die 'LazyGit returned an incomplete commit range'

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

from_sha=$(git rev-parse --verify "$range_from^{commit}" 2>/dev/null) || die "selected range start is not a commit: $range_from"
to_sha=$(git rev-parse --verify "$range_to^{commit}" 2>/dev/null) || die "selected range end is not a commit: $range_to"
for sha in "$from_sha" "$to_sha"; do
  git merge-base --is-ancestor "$sha" "$branch" || die "selected commits are not on the checked-out branch $branch"
done

if git merge-base --is-ancestor "$from_sha" "$to_sha"; then
  range_start=$from_sha
  range_end=$to_sha
elif git merge-base --is-ancestor "$to_sha" "$from_sha"; then
  range_start=$to_sha
  range_end=$from_sha
else
  die 'selected commits must belong to one ancestry path'
fi

if [ -n "$(git for-each-ref --contains "$range_start" refs/remotes)" ]; then
  die "$(git rev-parse --short "$range_start") is already on a remote branch; rewrite only unpushed commits"
fi

# The rewrite starts at the oldest selected commit's parent, so older history is never touched.
selected_file=$(mktemp)
trap 'rm -f "$selected_file"' EXIT
if parent_sha=$(git rev-parse --verify --quiet "$range_start^"); then
  git rev-list --ancestry-path "$parent_sha..$range_end" >"$selected_file"
  rewrite_range="$parent_sha..$branch"
else
  git rev-list "$range_end" >"$selected_file"
  rewrite_range=$branch
fi
count=$(wc -l <"$selected_file" | tr -d ' ')

export BIZ_REGENERATE_AUTHOR_NAME="$author_name"
export BIZ_REGENERATE_AUTHOR_EMAIL="$author_email"
export BIZ_REGENERATE_SELECTED_FILE="$selected_file"

if ! FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --env-filter '
  if grep -qx "$GIT_COMMIT" "$BIZ_REGENERATE_SELECTED_FILE"; then
    GIT_AUTHOR_NAME="$BIZ_REGENERATE_AUTHOR_NAME"
    GIT_AUTHOR_EMAIL="$BIZ_REGENERATE_AUTHOR_EMAIL"
    GIT_COMMITTER_NAME="$BIZ_REGENERATE_AUTHOR_NAME"
    GIT_COMMITTER_EMAIL="$BIZ_REGENERATE_AUTHOR_EMAIL"
    export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  fi
' -- "$rewrite_range"; then
  die "history rewrite failed; inspect $original_ref before retrying"
fi

if ! git update-ref -d "$original_ref"; then
  die "history was rewritten, but the temporary ref could not be removed: $original_ref"
fi

[ "$count" = 1 ] && noun=commit || noun=commits
printf 'Regenerated %s %s (%s..%s) on %s as %s <%s>.\n' "$count" "$noun" \
  "$(git rev-parse --short "$range_start")" "$(git rev-parse --short "$range_end")" "$branch" "$author_name" "$author_email"
