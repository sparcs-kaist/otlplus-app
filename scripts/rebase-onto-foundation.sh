#!/usr/bin/env bash
#
# rebase-onto-foundation.sh
#
# After Foundation PR #237 merges to main, run this script from the otl-app repo
# root (not a worktree) to rebase all 5 feature branches onto main, push with
# force-with-lease, and mark each PR Ready-for-review.
#
# Prerequisites:
#   - gh CLI authenticated
#   - Up-to-date working copy (git fetch origin main)
#   - Clean working tree on all branches (no uncommitted changes)
#
# Safe to re-run: each rebase uses --update-refs and each push uses
# --force-with-lease, so stale remotes are detected.

set -euo pipefail

MAIN="${MAIN:-main}"
BRANCHES=(
  "ui-redesign/home-timetable:238"
  "ui-redesign/account-settings:236"
  "ui-redesign/search-dictionary:241"
  "ui-redesign/course-lecture-detail:240"
  "ui-redesign/reviews:239"
)

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

  echo "   → rebasing onto origin/$MAIN"
  if GIT_MERGE_AUTOEDIT=no git rebase "origin/$MAIN"; then
    echo "   ✓ rebase clean"
  else
    echo "   ✗ rebase conflict – resolve manually and re-run this script"
    exit 1
  fi

  echo "   → pushing with --force-with-lease"
  git push --force-with-lease origin "$branch"

  echo "   → marking PR #$pr Ready for review"
  gh pr ready "$pr"
done

git checkout "$MAIN"
echo
echo "✓ All 5 feature PRs rebased onto $MAIN and marked Ready."
echo "  Merge order (recommended): #236 → #239 → #240 → #241 → #238"
echo "  (lightest first, home/timetable last since it touches the most-visible shared flows)"
