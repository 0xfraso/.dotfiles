---
name: commit
description: Reviews git diff, checks if docs need updates, suggests atomic splits, follows Conventional Commits, asks if in doubt before committing.
license: MIT
compatibility: opencode
metadata:
  types: feat,fix,docs,chore,refactor,test,style,ci,perf
  docs_patterns: README.md,docs/**,CHANGELOG.md,*.md
---

# Git Commit Convention Helper

## Prerequisites
Run this when you have unstaged changes: `git status` shows modified files.

## Step-by-Step Workflow

1. **Review Full Diff**
   Run `git diff` and analyze changes.
   - Identify types: new code (feat), bugs (fix), docs, etc.
   - Note if multiple logical units (e.g., feature + test + refactor).

2. **Check Documentation**
   Docs files: `README.md`, `docs/`, `CHANGELOG.md`, `*.md`.
   - `git diff --name-only`: List changed files.
   - If code changes (e.g., new API) but no doc changes: "Docs need update? E.g., add to README.md"
   - Examples: New feature → update README; DB schema change → docs/schema.md.

3. **Ensure Atomic Commits**
   - Single responsibility: One feat/fix per commit.
   - If mixed: Suggest `git add -p` to stage hunks selectively.
     - y: stage hunk; n: skip; s: split.
   - Multiple files/unrelated: "Split into atomic commits? E.g., tests separate. Run `git add -p` then commit"

4. **Conventional Commit Message**
   Format: `<type>[scope]: <description>` (50 chars), body if needed, footer (Closes #123).
   - Propose based on diff: e.g., "feat(auth): add JWT login\n\n- Implement token validation\n\nCloses #42"
   - Validate: lowercase type, no ! unless BREAKING CHANGE.

5. **Final Confirmation** - only in *PLAN* mode
   - Show proposed: staged files, message.
   - "Commit now? (y/n/edit)"

## Commands Template

git status
git diff
git diff --name-only | grep -E "(README|docs|CHANGELOG|.*.md)"
git add -p # if splitting
git commit -m "<proposed message>"

## Examples
- Diff shows new endpoint + test: "feat(api): add /users endpoint\n\nAdd handler and unit tests."
- Docs outdated: "fix: update README for new CLI flags\n\nReflect --dry-run addition."
- Mixed: Suggest split feat + test.
