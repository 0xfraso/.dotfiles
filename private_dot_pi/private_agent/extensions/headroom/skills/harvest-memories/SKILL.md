---
name: harvest-memories
description: Mine durable memories from past Pi session transcripts (JSONL) into per-project candidate files, then curate and store the winners in Headroom persistent memory. Use when the user wants to harvest memories from sessions, backfill memory from chat history, extract notable facts/decisions/conventions from past sessions, or says "harvest memories".
---

# Harvest Memories

Two-pass workflow over Pi session transcripts (`~/.pi/agent/sessions/<project>/*.jsonl`):

1. **Harvest (pass 1):** read each project's sessions, extract notable memories, write them to a per-project candidate JSONL.
2. **Curate (pass 2):** review each candidate file, store the keepers via `headroom_memory_save`.

The helper script does all mechanical work (enumeration, JSONL parsing, transcript reconstruction, dedup). **You** do all judgment.

## Helper script

`SCRIPT = ~/.pi/agent/extensions/headroom/skills/harvest-memories/scripts/harvest.mjs` (run with `node`).

```
node $SCRIPT projects [N]       # pass-1 source list: slug, #sessions, #candidates, cwd
node $SCRIPT gather <slug>      # reconstruct clean transcripts -> ~/.pi/agent/headroom/harvest/work/<slug>.jsonl
node $SCRIPT append <slug>      # append NDJSON candidates from stdin (auto id + dedup) -> ~/.pi/agent/headroom/harvest/<slug>.jsonl
node $SCRIPT show <slug>        # pretty-print one project's candidates (pass-1 self-check)
node $SCRIPT review             # pass-2 overview: per-project total + undecided counts
node $SCRIPT next [N=20]        # pass-2 batch: next N undecided candidates across all projects
node $SCRIPT mark <id>...       # mark ids decided (presented/stored/skipped) so they don't resurface
node $SCRIPT decided            # count/list decided ids
node $SCRIPT reset              # clear the decided ledger
```

## Pass 1 — Harvest

1. `node $SCRIPT projects` → pick a project with `sessions > 0` and `candidates: 0` (or re-do any). Process one project at a time to stay focused.
2. `node $SCRIPT gather <slug>` → builds `work/<slug>.jsonl`. Each line: `{sessionId, startedAt, cwd, lines:[...]}` where lines are clean turns (`[user]`, `[assistant]`, `[tool]`), thinking stripped, tool results snipped. Large sessions are truncated — if a candidate needs verifying, `read` the source `.jsonl` directly.
3. `read` the work file. Identify **significant** memories (see criteria). For each, emit one NDJSON line to stdin of `append`:
   ```
   printf '%s\n' \
     '{"content":"<self-contained fact>","category":"decision","scope":"project","source":"<sessionId>"}' \
     | node $SCRIPT append <slug>
   ```
   - `content`: concise, self-contained, no "we" without a subject (write "hojo uses X" not "we decided X").
   - `category`: `decision` | `convention` | `fact` | `context` | `insight` | `preference`.
   - `scope`: `project` (tied to this project) or `user` (cross-project personal fact).
   - `source`: the sessionId it came from (for traceability).
   Dedup is automatic on content hash.

### What is "significant" (store-worthy)

- **Decisions:** tech/library/architecture choices and the reason ("hojo chose Zustand over Redux for bundle size").
- **Conventions/patterns:** how the project does things ("commits use Conventional Commits; branch from `dev`").
- **Durable facts:** project structure, key constraints, external service quirks.
- **Insights/gotchas:** non-obvious failure modes, performance cliffs, security notes.
- **Preferences:** durable user likes/dislikes (usually `scope:user`).

### What is NOT significant (skip)

- Transient task state, to-do chatter, one-off commands, debugging back-and-forth.
- Anything already obvious from the repo/files (README, obvious structure).
- **Never store secrets, tokens, passwords, paths under private dirs, or PII.** When in doubt, skip.

Aim for the few durable facts that would help a *future* session — quality over quantity. A handful per project is normal.

## Pass 2 — Curate, confirm, then store

**Never store without explicit user confirmation.** You present a batch, the user picks what to keep, you store only the approved ones. A `decided.txt` ledger tracks every id you've shown so it doesn't resurface.

1. `node $SCRIPT review` → see undecided counts per project.
2. Pull a batch of **at least 20** if available: `node $SCRIPT next 20`. This returns `{presented, remaining, batch:[{n, id, slug, scope, category, content, source, cwd}, ...]}` drawn across all projects, undecided only. If `presented < 20`, that's all that's left — present what there is.
3. **Present the batch to the user** as a numbered list (use `n` and a short label), grouped or flat — your call, but every item needs its `n`, scope/category, and content visible. Do **not** call `headroom_memory_save` yet.
4. Ask the user which to store. Accept their answer as numbers/ranges/"all"/"skip X". For anything ambiguous, ask.
5. **Store only the approved items** with `headroom_memory_save` (`content` = candidate content, tighten wording if needed; `category` and `scope` from the candidate). Before storing, `headroom_memory_search` to avoid dupes already in memory.
6. **Mark the whole batch decided** — both stored and rejected — so it won't resurface: `node $SCRIPT mark <id1> <id2> ...` (pass every id from the batch, or at least every id you presented). Deferred items (user wants to revisit) → don't mark those; they'll reappear next `next`.
7. Loop: `node $SCRIPT next 20` again until `presented: 0`.

Ledger commands: `node $SCRIPT decided` (count/list), `node $SCRIPT reset` (clear — re-review everything). Work one project at a time is *not* required; `next` interleaves across projects.

### Scoping caveat

`headroom_memory_save` stores **project**-scoped memories under the *current* session's cwd, not the harvested project's cwd. The batch item's `cwd` shows the real project. If you're curating project X from elsewhere, either set those items to `scope:user`, or tell the user to re-run pass 2 from X's directory. Prefer `scope:user` for genuinely cross-project insights regardless.

## Self-check

Before finishing pass 1 for a project, confirm: `node $SCRIPT show <slug>` lists only durable, non-secret, self-contained facts — not session narration. Run `node $SCRIPT review` to see running totals across projects.
