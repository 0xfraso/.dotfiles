---
name: slice-to-graph
description: Break context or PRD into vertical slices, infer dependencies to build an execution graph, and run parallel worktrees with patch collection via cherry-picks. Use when user wants to decompose a plan, run parallel worktrees, compose patches into a branch, or turn a PRD into independently-executable slices.
---

# Slice to Graph

Decompose requirements into vertical slices, infer dependencies to build a DAG, run parallel worktrees via pi-subagents, and collect patches via cherry-picks.

## Quick Start

```text
/slice-to-graph from the current PRD in our conversation
```

Flow: parse → draft slices → infer deps → present graph → execute worktrees → collect patches

## Workflow

### 1. Parse Input

Conversation context, bead numbers (`bd view <n>`), requirement files (`.md`, `.txt`), or git context (diff, branch).

### 2. Draft Vertical Slices

Each slice is a thin vertical cut through ALL layers. A completed slice is demoable on its own. Prefer many thin slices.

Slice body: Context (project patterns), What to build (end-to-end), Files to touch (`src/...`, `tests/...`), Acceptance criteria, Verify (tests/commands).

### 3. Infer Dependencies

A creates types.ts B imports → B blocked by A. A defines hook/service B uses → B blocked by A. A creates migration B alters → B blocked by A. Shared fixtures → B blocked by A. Honor explicit `Blocked by #<number>`. Build a DAG, compute topological layers.

### 4. Present Graph for Approval

```
═══════════════════════════════════════
Layer 1 (parallel):
  • Slice 1: "Auth middleware" — no blockers
  • Slice 2: "DB models" — no blockers
Layer 2 (after Layer 1):
  • Slice 3: "API routes" — blocked by [1, 2]
═══════════════════════════════════════
```

Ask: inference correct? Merges/splits? Manual blockers?

### 4.1 Verify Clean Working Tree

```bash
git status --porcelain && exit 1  # fail if dirty
```
If dirty: commit, stash, or abort. Do not proceed until clean.

### 5. Execute with Worktrees

The orchestrator (this session) runs each layer as a **separate subagent call**, not a pi-subagents chain. This gives full control between layers: inspect results, adapt context, decide to continue or abort.

- **Single slice**: `subagent { agent, task, async: false, clarify: false }`
- **Parallel slices**: `subagent { tasks: [...], worktree: true, concurrency: 4, async: false, clarify: false }`

Always set `async: false`, `clarify: false`, and `worktree: true` on parallel calls.

**Context flow**: Between layers, the orchestrator passes prior output as text context in the next layer's task. Dependent slices get descriptions of what was built (file paths, interfaces) — not the files on disk. Write tasks that reference exact paths from prior layers.

**Agent inference** (unless overridden): scout/researcher for exploration, planner for architecture, worker for implementation (default), reviewer for validation, oracle for decisions.

**Model inference**: Always use Pi default. Do NOT pin models unless user explicitly requests one.

### 6. Collect Patches

Patches are auto-captured to `{chain_dir}/worktree-diffs/step-{n}/task-{i}-{agent}.patch`. Apply in dependency order with Conventional Commits (`feat:`, `fix:`, `refactor:`). Handle conflicts with `git apply --3way`.

**Commit message discipline:** Never mention slices, layer numbers, or execution plumbing in commit messages. The reader sees a linear git log — they don't know or care that work was parallelized. Write messages as if each commit landed sequentially: describe *what changed* and *why*, not *how it was orchestrated*.

Bad: `feat(hud): Layer 2 — Slice 4: mobile tab dock overflow fix`
Bad: `feat(hud): responsive, motion, and visual consistency across 7 slices`
Good: `fix(hud): mobile tab dock overflow and safe-area handling`
Good: `feat(hud): dialog entrance animation and panel fade transitions`

### 7. Cleanup

`git worktree prune` (worktrees already cleaned up by pi-subagents).

## Output

```
feat: add auth middleware
feat: add database models
feat: add API routes
feat: add frontend components
```

## Manual Override

```text
Run [1, 2, 5] in parallel with scout, then [3, 4] with worker using claude-sonnet-4.
```

## Reference

[REFERENCE.md](REFERENCE.md): chain params, agent/model tables, rollback, dependency algorithms, scripts.