#!/bin/bash
# Usage: apply-patches.sh <patch-dir> <slice-ids>
# Example: apply-patches.sh /tmp/patches "1,2,3,4,5"
# Cherry-picks patches in order with Conventional Commits.
# Exits 1 on unresolvable conflicts.

set -e

PATCH_DIR="$1"
SLICES="$2"

if [ -z "$PATCH_DIR" ] || [ -z "$SLICES" ]; then
  echo "Usage: apply-patches.sh <patch-dir> <slice-ids>"
  echo "Example: apply-patches.sh /tmp/patches \"1,2,3,4,5\""
  exit 1
fi

IFS=',' read -ra SLICE_ARRAY <<< "$SLICES"

for SLICE in "${SLICE_ARRAY[@]}"; do
  PATCH_FILE="$PATCH_DIR/patch-$SLICE.diff"

  if [ ! -f "$PATCH_FILE" ]; then
    echo "Warning: Patch not found for slice $SLICE"
    continue
  fi

  # Skip empty patches (no changes in that slice)
  if [ ! -s "$PATCH_FILE" ]; then
    echo "Skipping empty patch for slice $SLICE"
    continue
  fi

  # Derive commit message from slice title in the patch (if present) or use slice ID
  TITLE=$(grep -m1 "^diff --git" "$PATCH_FILE" | sed 's|diff --git a/||' | sed 's| b/.*||' | head -1)
  if [ -z "$TITLE" ]; then
    TITLE="slice $SLICE"
  fi
  echo ""
  echo "=== Applying slice $SLICE ==="

  # Apply patch
  if git apply "$PATCH_FILE" 2>/dev/null; then
    echo "Patch applied successfully"
  else
    echo "Normal apply failed, trying 3-way merge..."
    if git apply --3way "$PATCH_FILE" 2>/dev/null; then
      echo "3-way merge applied"
    else
      echo "ERROR: Conflict in patch $SLICE"
      echo "Conflicting files:"
      git diff --name-only --diff-filter=U 2>/dev/null || echo "  (unable to determine)"
      echo ""
      echo "Options:"
      echo "  1. Resolve conflicts manually, then 'git add -A && git commit'"
      echo "  2. Run 'git apply --3way $PATCH_FILE' with manual conflict resolution"
      echo "  3. Run 'git reset --hard' to cancel"
      exit 1
    fi
  fi

  # Stage all changes
  git add -A

  # Check if there's anything to commit
  if git diff --cached --quiet; then
    echo "No changes to commit for slice $SLICE"
    # Unstage if nothing to commit
    git reset HEAD --quiet 2>/dev/null || true
  else
    # Ensure Conventional Commits format: prefix with "feat:" if no type prefix
    if echo "$TITLE" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert): '; then
      COMMIT_MSG="$TITLE"
    else
      COMMIT_MSG="feat: $TITLE"
    fi
    git commit -m "$COMMIT_MSG"
    echo "Committed: $COMMIT_MSG"
  fi
done

echo ""
echo "=== Patch application complete ==="
echo ""
git log --oneline -n "${#SLICE_ARRAY[@]}"
