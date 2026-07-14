Utility scripts for slice-to-graph. Worktree creation, diff capture, and cleanup
are handled by pi-subagents automatically when `worktree: true` is set.

### apply-patches.sh

Applies collected patches to the current branch in dependency order.
Patches are found in `{chain_dir}/worktree-diffs/step-{n}/task-{i}-{agent}.patch`.

```bash
./apply-patches.sh <patch-dir> <slice-ids>
```

Example:
```bash
./apply-patches.sh /tmp/patches "1,2,3,4,5"
```

Auto-prefixes with `feat:` if the title doesn't already have a Conventional Commits type.

### cleanup-worktrees.sh

Removes manual worktree pools in `.slice-worktrees` (rarely needed — pi-subagents
handles cleanup automatically).