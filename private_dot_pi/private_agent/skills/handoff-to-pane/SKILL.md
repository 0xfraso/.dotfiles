---
name: handoff-to-pane
description: Compress the current conversation into a handoff document, then spawn a fresh Pi agent in a new pane to pick it up. Works in both herdr and zellij (auto-detected). Use when you want to delegate work to a separate visible agent session, when you spot a side-task mid-session that deserves its own context window, or when you want to prototype something without polluting the current conversation.
argument-hint: "What the new agent should focus on"
---

# Handoff to Pane

Like `/handoff`, but automatically spawns a pane in the active terminal multiplexer (**herdr** or **zellij**) instead of leaving you to paste the document manually. The spawn script auto-detects which one you're in — no flag needed.

## Workflow

### 1. Create the handoff document

Follow the `handoff` skill instructions exactly. Load it by reading `/home/fraso/.agents/skills/handoff/SKILL.md` and apply its rules for summarising, redacting, deduplicating, and tailoring the document to the user's argument.

Save the result to `/tmp/pi-handoff/<name>-<timestamp>.md` (create the directory if it doesn't exist).

### 2. Spawn the pane

Run the helper script:

```bash
bun run /home/fraso/.pi/agent/skills/handoff-to-pane/scripts/spawn.ts -- \
  --name "<pane-name>" \
  --cwd "<working-directory>" \
  --handoff "<path-to-handoff-md>" \
  --model "<optional-model>"
```

The script detects the active multiplexer (`HERDR_ENV=1` → **herdr**; otherwise **zellij**), splits a pane, runs `pi @<file>` in it, and saves a tracking record. The new agent receives the handoff and starts working immediately. In herdr it splits the focused pane downward (keeping your focus) and `cd`s to `--cwd`; in zellij it uses `zellij run --close-on-exit`.

**Do not pass `--model` unless the user explicitly asks for a specific model.** When `--model` is omitted, the new agent inherits whatever default model and provider the user has configured — this is almost always what they want.

### 3. Confirm to the user

Report:
- The pane name and ID
- The handoff file location
- A one-line summary of what was delegated

The user can switch to the new pane with `Alt+↓` or `Ctrl+p` (zellij), or their herdr pane-nav keybind.

## Tracking spawned panes

Every spawned pane is tracked in `/tmp/pi-handoff/.panes/<name>.json`.

```bash
# List tracked panes and their alive/gone status (works for both muxes)
bun run /home/fraso/.pi/agent/skills/handoff-to-pane/scripts/spawn.ts -- --list

# Clean up tracking files for dead panes
bun run /home/fraso/.pi/agent/skills/handoff-to-pane/scripts/spawn.ts -- --clean
```

To focus a specific tracked pane by ID:
```bash
# zellij:
zellij action focus-pane-id <pane-id>
# herdr (focus is not pane-level via CLI — use your keybind, or focus its tab/workspace):
herdr tab focus <tab-id>   # e.g. 1:1
```

## When to use

- **Mid-session side-task**: You spot a refactoring opportunity or bug that's out of scope. Hand it off instead of context-switching.
- **Prototype before planning**: During a grilling session, hand off a prototype to a separate agent, then bring findings back.
- **Parallel exploration**: Investigate a tangential concern without diluting the current context window.
- **Different model**: Delegate to a model that suits the task better (e.g., fast model for linting, reasoning model for architecture).

## vs. /handoff and pi-subagents

| | `/handoff` | `/handoff-to-pane` | `pi-subagents` |
|---|---|---|---|
| Output | .md file for manual paste | .md + auto-spawned pane (herdr/zellij) | In-session child agents |
| Visibility | None | Dedicated pane you can watch | Status lines in current TUI |
| Persistence | Until you use the file | Until agent exits (zellij auto-closes; herdr stays until closed) | Until parent session ends |
| Orchestration | None | None | Chains, parallel, intercom, control |

Zellij panes close automatically when the agent exits (`--close-on-exit`). herdr panes persist after the agent exits — close them manually (`herdr pane close <pane-id>`) or `exit` in the pane. Note: pane IDs in both muxes are ephemeral and can compact when panes close; re-read them from `--list` or `herdr pane list` rather than caching.
