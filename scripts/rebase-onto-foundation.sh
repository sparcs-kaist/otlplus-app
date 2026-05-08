#!/usr/bin/env bash
#
# rebase-onto-foundation.sh
#
# After Foundation PR #237 merges to main, run this script from the otl-app repo
# root (not a worktree) to rebase all 5 feature branches onto main, push with
# --force-with-lease, and mark each PR Ready-for-review.
#
# Prerequisites:
#   - git and gh CLI on PATH; gh authenticated
#   - HEAD is on a real branch, not detached (the script aborts otherwise)
#   - Working tree clean (the script aborts if `git status` is dirty)
#   - Network access to origin
#
# Safety: each feature branch is hard-reset to origin before rebasing, so any
# unpushed local commits on those branches will be discarded. Keep your work
# only on branches outside the five listed here.
#
# On a rebase conflict the script aborts the in-progress rebase, returns to
# your starting branch, and exits non-zero — you can resolve manually, push,
# and re-run.

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

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo "✗ Not inside a git working tree." >&2
  exit 1
fi

if [ -f "$(git rev-parse --git-dir)/gitdir" ]; then
  echo "✗ This script must run in the main repo checkout, not a linked worktree." >&2
  echo "  cd to the repo root (not .../tree/<branch>) and re-run." >&2
  exit 1
fi

START_BRANCH="$(git branch --show-current || true)"
if [ -z "$START_BRANCH" ]; then
  echo "✗ HEAD is detached. Check out a branch before running this script." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "✗ Working tree is dirty. Commit or stash changes and re-run." >&2
  exit 1
fi

echo "→ Fetching origin/$MAIN…"
git fetch origin "$MAIN"

return_to_start() {
  if ! git checkout "$START_BRANCH" 2>/dev/null; then
    echo "   ⚠ could not return to '$START_BRANCH' (branch may have been deleted)" >&2
    echo "     you are currently on: $(git branch --show-current || echo 'DETACHED HEAD')" >&2
  fi
}

for entry in "${BRANCHES[@]}"; do
  branch="${entry%%:*}"
  pr="${entry##*:}"
  echo
  echo "═══ $branch  (PR #$pr) ═══"

  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "   → creating local '$branch' from origin"
    git branch "$branch" "origin/$branch"
  fi

  git checkout "$branch"
  git fetch origin "$branch"
  git reset --hard "origin/$branch"

  echo "   → rebasing onto origin/$MAIN"
  if GIT_MERGE_AUTOEDIT=no git rebase "origin/$MAIN"; then
    echo "   ✓ rebase clean"
  else
    echo "   ✗ rebase conflict on $branch – aborting and stopping" >&2
    git rebase --abort || true
    return_to_start
    echo "   → resolve '$branch' vs origin/$MAIN manually, push, then re-run" >&2
    exit 1
  fi

  echo "   → pushing with --force-with-lease"
  git push --force-with-lease origin "$branch"

  echo "   → marking PR #$pr Ready for review"
  if ! gh pr ready "$pr"; then
    echo "   ⚠ 'gh pr ready $pr' failed (rebase and push already succeeded)." >&2
    echo "     Flip PR #$pr to Ready manually on GitHub, then re-run to continue." >&2
    return_to_start
    exit 1
  fi
done

return_to_start
echo
echo "✓ All 5 feature PRs rebased onto $MAIN and marked Ready."
echo "  Merge order (recommended): #236 → #239 → #240 → #241 → #238"
echo "  (lightest first, home/timetable last since it touches the most-visible shared flows)"
