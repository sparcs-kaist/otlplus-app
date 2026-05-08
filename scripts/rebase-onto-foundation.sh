#!/usr/bin/env bash
#
# rebase-onto-foundation.sh
#
# After Foundation PR #237 merges to main, run this script from the otl-app repo
# root (not a worktree) to rebase all 5 feature branches onto main, push with
# --force-with-lease, and mark each PR Ready-for-review.
#
# Prerequisites:
#   - gh CLI authenticated
#   - Working tree clean (the script aborts if `git status` is dirty)
#   - Network access to origin
#
# Safe to re-run: each push uses --force-with-lease (so stale remotes are
# detected) and a failing rebase is aborted before the script exits, leaving
# the branch in its pre-rebase state.

set -euo pipefail

MAIN="${MAIN:-main}"
BRANCHES=(
  "ui-redesign/home-timetable:238"
  "ui-redesign/account-settings:236"
  "ui-redesign/search-dictionary:241"
  "ui-redesign/course-lecture-detail:240"
  "ui-redesign/reviews:239"
)

for required in git gh; do
  if ! command -v "$required" >/dev/null 2>&1; then
    echo "✗ Required command '$required' not found in PATH" >&2
    exit 1
  fi
done

if [ -n "$(git status --porcelain)" ]; then
  echo "✗ Working tree is dirty. Commit or stash changes and re-run." >&2
  exit 1
fi

START_BRANCH="$(git branch --show-current)"

echo "→ Fetching origin/$MAIN…"
git fetch origin "$MAIN"

for entry in "${BRANCHES[@]}"; do
  branch="${entry%%:*}"
  pr="${entry##*:}"
  echo
  echo "═══ $branch  (PR #$pr) ═══"

  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "   → tracking $branch from origin"
    git branch "$branch" "origin/$branch"
  fi

  git checkout "$branch"
  git fetch origin "$branch"
  git reset --hard "origin/$branch"

  echo "   → rebasing onto origin/$MAIN"
  if GIT_MERGE_AUTOEDIT=no git rebase "origin/$MAIN"; then
    echo "   ✓ rebase clean"
  else
    echo "   ✗ rebase conflict on $branch – aborting rebase and stopping" >&2
    git rebase --abort || true
    git checkout "$START_BRANCH" || true
    echo "   → resolve conflicts manually, push $branch, then re-run this script" >&2
    exit 1
  fi

  echo "   → pushing with --force-with-lease"
  git push --force-with-lease origin "$branch"

  echo "   → marking PR #$pr Ready for review"
  gh pr ready "$pr"
done

git checkout "$START_BRANCH"
echo
echo "✓ All 5 feature PRs rebased onto $MAIN and marked Ready."
echo "  Merge order (recommended): #236 → #239 → #240 → #241 → #238"
echo "  (lightest first, home/timetable last since it touches the most-visible shared flows)"
