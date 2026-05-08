#!/usr/bin/env bash
# ---8<--- help-start
# rebase-onto-foundation.sh
#
# After Foundation PR #237 merges to main, run this script from the otl-app repo
# root (not a worktree) to rebase all 5 feature branches onto main, push with
# --force-with-lease, and mark each PR Ready-for-review.
#
# Usage:
#   bash scripts/rebase-onto-foundation.sh           # fail fast on worktree clashes
#   bash scripts/rebase-onto-foundation.sh --cleanup # auto-remove conflicting worktrees
#   bash scripts/rebase-onto-foundation.sh --help
#
# Prerequisites:
#   - git and gh CLI on PATH; gh authenticated
#   - HEAD is on a real branch, not detached
#   - Working tree clean (commit or stash first)
#   - Network access to origin
#
# Safety:
#   - Feature branches are hard-reset to origin before rebasing, so any unpushed
#     local commits on those branches are discarded.
#   - Without --cleanup the script exits with an actionable error if any feature
#     branch is checked out in a linked worktree (e.g. ./tree/<branch>).
#   - With --cleanup the script runs `git worktree remove` on each conflicting
#     worktree before checking out the branch. This deletes the worktree
#     directory; local commits on that branch that were only in the worktree
#     are lost the same way --hard-reset would discard them.
# ---8<--- help-end

set -euo pipefail

CLEANUP_WORKTREES=0
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      awk '
        /^# ---8<--- help-end/ { exit }
        inside { sub(/^# ?/, ""); print }
        /^# ---8<--- help-start/ { inside = 1 }
      ' "$0"
      exit 0
      ;;
    --cleanup|--cleanup-worktrees)
      CLEANUP_WORKTREES=1
      ;;
    *)
      echo "✗ Unknown argument: $arg" >&2
      echo "  Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

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

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "✗ Tracked files have uncommitted changes. Commit or stash and re-run." >&2
  echo "  (untracked files like .../tree/ worktrees are ignored for this check)" >&2
  exit 1
fi

MAIN_TOPLEVEL="$(git rev-parse --show-toplevel)"

worktree_holding() {
  git worktree list --porcelain | awk -v b="refs/heads/$1" '
    /^worktree / { wt = $2 }
    $0 == "branch " b { print wt; exit }
  '
}

CLASHES=()
for entry in "${BRANCHES[@]}"; do
  branch="${entry%%:*}"
  wt="$(worktree_holding "$branch")"
  if [ -n "$wt" ] && [ "$wt" != "$MAIN_TOPLEVEL" ]; then
    CLASHES+=("$branch:$wt")
  fi
done

if [ "${#CLASHES[@]}" -gt 0 ]; then
  echo "Found ${#CLASHES[@]} feature branch(es) checked out in linked worktrees:"
  for c in "${CLASHES[@]}"; do
    echo "  $c"
  done
  if [ "$CLEANUP_WORKTREES" -eq 1 ]; then
    echo
    echo "→ --cleanup specified; removing each worktree"
    for c in "${CLASHES[@]}"; do
      wt="${c#*:}"
      echo "   git worktree remove $wt"
      if ! git worktree remove "$wt"; then
        echo "   ✗ 'git worktree remove $wt' failed." >&2
        echo "     The worktree likely has uncommitted changes." >&2
        echo "     Commit/discard them there, or run:" >&2
        echo "       git worktree remove --force $wt" >&2
        exit 1
      fi
    done
  else
    echo
    echo "Re-run with --cleanup to remove them automatically, or clean up by hand:"
    for c in "${CLASHES[@]}"; do
      echo "   git worktree remove ${c#*:}"
    done
    exit 1
  fi
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
