---
name: chezmoi
description: Manage the chezmoi-managed dotfiles on this machine (~/.dotfiles is the source of truth, ~ is the target). Use when the user mentions chezmoi, dotfiles, managed config, drift between source and home, or wants to apply, re-add, reconcile, or commit managed files.
---

# Chezmoi

## Layout

- Source of truth: `~/.dotfiles` (git repo, branch `main`, committed straight to origin, no PR flow). Target: `~`.
- Never run `chezmoi init` on this machine: it regenerates the config from `.chezmoi.toml.tmpl` and silently drops the `sourceDir` override. `chezmoi apply` and `chezmoi update` are the only sync commands.
- `chezmoi doctor` always reports a hardlink error against /tmp here — an artifact of the split /tmp mount, not a problem.

## Read the state

Three looks, in order. Done when every drift entry has a known direction.

1. `git -C ~/.dotfiles status --short --branch` — uncommitted source edits, sync state with origin.
2. `chezmoi status` — the drift list: one line per entry where source and live home disagree.
3. `chezmoi diff` — per entry: `-` lines are the source side, `+` lines the live file.

## Reconcile: one direction per entry

- **Live file is authoritative** (edited in place since the last sync): `chezmoi re-add <target>` copies it back into the source.
- **Source is authoritative**: `chezmoi apply <target>` writes it to the home.
- **Both sides changed**: merge by hand — edit the source file (`chezmoi source-path <target>`), mirror the live side's changes, then `re-add`. `chezmoi merge` is unusable here: it shells out to `vimdiff`, which is not installed.

A blanket `chezmoi apply` is the failure mode: it clobbers the live side of every entry whose live file was authoritative — regularly including pi agent state under `.pi/`, herdr config, and `.zshrc`. Entry-by-entry with `chezmoi diff` checked first is the whole discipline.

Phantom drift: symlinked skill checkouts under `.pi/agent/skills/` can report drift from symlink-target churn alone. Confirm real content drift with `chezmoi diff` before reconciling those.

## Commit

`git -C ~/.dotfiles add -A && git commit && git push`. Done when `git -C ~/.dotfiles status` is clean and `chezmoi status` is empty.

## Scope questions

`chezmoi managed` / `chezmoi unmanaged` / `chezmoi source-path <target>` / `chezmoi cat <target>` answer what is managed and where its source lives.
