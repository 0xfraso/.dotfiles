#!/bin/bash
# Usage: cleanup-worktrees.sh
# Removes all worktrees in the .slice-worktrees directory

POOL_DIR=".slice-worktrees"

if [ ! -d "$POOL_DIR" ]; then
  echo "No worktree pool found at $POOL_DIR"
  exit 0
fi

echo "Cleaning up worktree pool..."

for wt in $(ls "$POOL_DIR" 2>/dev/null); do
  WT_PATH="$POOL_DIR/$wt"
  
  if [ ! -d "$WT_PATH/.git" ]; then
    echo "  Skipping $wt (not a worktree)"
    continue
  fi
  
  echo "  Removing: $wt"
  
  # Check for uncommitted changes
  if [ -n "$(git -C "$WT_PATH" status --porcelain)" ]; then
    echo "    Warning: $wt has uncommitted changes"
    echo "    Forcing removal..."
  fi
  
  git worktree remove "$WT_PATH" --force 2>/dev/null || {
    echo "    Warning: Could not remove cleanly"
    # Try to at least remove the directory
    rm -rf "$WT_PATH" 2>/dev/null || true
  }
done

# Remove the pool directory
rm -rf "$POOL_DIR"

echo "Worktree pool cleaned up"