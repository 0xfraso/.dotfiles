---
name: git-untrack
description: Remove a file from git tracking by rewriting history so it was never committed. Use when the user wants to untrack a file, remove a file from git history, or says "I committed a file I shouldn't have".
---

# Git Untrack

## Quick start

```bash
# 1. Find the commit where the file was first added
git log --follow --diff-filter=A --oneline -- path/to/file

# 2. Interactive rebase from that commit's parent
git rebase -i <sha>^

# 3. In the editor, mark the add-commit as "edit", save and close

# 4. Remove the file from the index, amend, continue
git rm --cached path/to/file
git commit --amend --no-edit
git rebase --continue
```

## Workflow

1. **Find the add commit**
   - Run `git log --follow --diff-filter=A --oneline -- <path>`
   - If multiple commits appear (file was deleted and re-added), pick the one you want to rewrite.
   - To see full history first: `git log --follow --oneline -- <path>`

2. **Verify** the commit actually added the file:
   ```bash
   git show --name-status <sha> -- path/to/file
   ```

3. **Rebase interactively** from the parent of that commit:
   ```bash
   git rebase -i <sha>^
   ```
   Mark the target commit as `edit` (change `pick` to `edit`).

4. **Untrack and amend:**
   ```bash
   git rm --cached path/to/file
   git commit --amend --no-edit
   git rebase --continue
   ```

5. **If you want to squash** subsequent commits that touched the same file, mark them as `squash` during the rebase instead of `pick`.

## Warnings

- Rewriting history changes SHAs of all subsequent commits.
- If the branch is shared, coordinate with collaborators or force-push with care.
- Only add to `.gitignore` if the user explicitly asks for it.
