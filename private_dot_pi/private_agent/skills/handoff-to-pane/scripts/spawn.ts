/**
 * handoff-to-pane spawn script
 *
 * Opens a new pane running `pi` primed with a handoff document, in whichever
 * terminal multiplexer is active: **herdr** (HERDR_ENV=1) or **zellij**.
 * Uses `pi @<file>` to pass the handoff as an initial message, avoiding shell
 * quoting issues with long content.
 *
 * Saves a tracking JSON file so the parent session can check status,
 * reconnect, or clean up spawned panes.
 *
 * Usage:
 *   bun run spawn.ts -- \
 *     --name auth-refactor \
 *     --cwd /home/user/project \
 *     --handoff /tmp/pi-handoff/auth-1234.md \
 *     [--model provider/model] [--thinking high]
 *
 * The active multiplexer is auto-detected. To force one (rarely needed), set
 * the env var explicitly: HERDR_ENV=1 for herdr, or run inside zellij.
 */

import { parseArgs } from "node:util";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, writeFileSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { resolve, join } from "node:path";

const STATE_DIR = "/tmp/pi-handoff/.panes";

type Mux = "zellij" | "herdr";

const HANDOFF_PROMPT =
  "Continue the work described in the referenced file. Start by reading it, then follow the instructions.";

// --- CLI ---

function parseCli() {
  const { values } = parseArgs({
    options: {
      name: { type: "string" },
      cwd: { type: "string" },
      handoff: { type: "string" },
      model: { type: "string" },
      thinking: { type: "string" },
      // Management commands
      list: { type: "boolean" },
      clean: { type: "boolean" },
    },
    strict: true,
  });

  // Management mode: list tracked panes
  if (values.list) {
    listPanes();
    process.exit(0);
  }

  // Management mode: clean up stale tracking files
  if (values.clean) {
    cleanPanes();
    process.exit(0);
  }

  if (!values.name) {
    console.error("Error: --name is required");
    process.exit(1);
  }
  if (!values.handoff) {
    console.error("Error: --handoff is required");
    process.exit(1);
  }

  const handoffPath = resolve(values.handoff);
  if (!existsSync(handoffPath)) {
    console.error(`Error: handoff file not found: ${handoffPath}`);
    process.exit(1);
  }

  return {
    name: values.name,
    cwd: values.cwd ? resolve(values.cwd) : process.cwd(),
    handoff: handoffPath,
    model: values.model,
    thinking: values.thinking,
  };
}

// --- Multiplexer detection ---

function detectMux(): Mux | null {
  // herdr sets HERDR_ENV=1 inside its managed panes.
  if (process.env.HERDR_ENV === "1") return "herdr";
  // zellij sets ZELLIJ* env vars inside its sessions.
  if (process.env.ZELLIJ || process.env.ZELLIJ_SESSION_NAME) return "zellij";
  return null;
}

// --- pi argument building (shared by both muxes) ---

/** Returns the args to pass to `pi` (after the `pi` binary itself). */
function buildPiArgs(config: ReturnType<typeof parseCli>): string[] {
  const piArgs: string[] = [];
  if (config.model) {
    if (config.thinking) {
      piArgs.push("--model", `${config.model}:${config.thinking}`);
    } else {
      piArgs.push("--model", config.model);
    }
  } else if (config.thinking) {
    piArgs.push("--thinking", config.thinking);
  }
  piArgs.push(`@${config.handoff}`);
  piArgs.push(HANDOFF_PROMPT);
  return piArgs;
}

/** Single-quote a string for safe shell interpolation. */
function shellQuote(s: string): string {
  return `'${s.replace(/'/g, `'"'"'`)}'`;
}

// --- State management ---

interface PaneRecord {
  paneId: string;
  name: string;
  mux: Mux;
  cwd: string;
  handoff: string;
  model?: string;
  thinking?: string;
  spawnedAt: string;
  pid: number;
}

function savePaneRecord(record: PaneRecord) {
  mkdirSync(STATE_DIR, { recursive: true });
  const filePath = join(STATE_DIR, `${record.name}.json`);
  writeFileSync(filePath, JSON.stringify(record, null, 2));
}

function listPanes() {
  if (!existsSync(STATE_DIR)) {
    console.log("No tracked panes.");
    return;
  }

  const files = readdirSync(STATE_DIR).filter(f => f.endsWith(".json"));
  if (files.length === 0) {
    console.log("No tracked panes.");
    return;
  }

  console.log("Tracked handoff panes:\n");
  for (const f of files) {
    try {
      const record: PaneRecord = JSON.parse(readFileSync(join(STATE_DIR, f), "utf-8"));
      const age = formatAge(record.spawnedAt);
      const alive = isPaneAlive(record);
      console.log(`  ${record.name}`);
      console.log(`    Mux:     ${record.mux ?? "zellij"}`);
      console.log(`    Pane:    ${record.paneId} (${alive ? "alive" : "gone"})`);
      console.log(`    Handoff: ${record.handoff}`);
      if (record.model) console.log(`    Model:   ${record.model}`);
      console.log(`    Spawned: ${age}`);
      console.log("");
    } catch {
      console.log(`  (corrupted: ${f})\n`);
    }
  }
}

function cleanPanes() {
  if (!existsSync(STATE_DIR)) {
    console.log("Nothing to clean.");
    return;
  }

  const files = readdirSync(STATE_DIR).filter(f => f.endsWith(".json"));
  let removed = 0;

  for (const f of files) {
    try {
      const record: PaneRecord = JSON.parse(readFileSync(join(STATE_DIR, f), "utf-8"));
      if (!isPaneAlive(record)) {
        rmSync(join(STATE_DIR, f));
        removed++;
      }
    } catch {
      rmSync(join(STATE_DIR, f));
      removed++;
    }
  }

  console.log(`Cleaned ${removed} stale tracking file(s).`);
}

/** Whether a tracked pane still exists in its multiplexer. */
function isPaneAlive(record: PaneRecord): boolean {
  const mux: Mux = record.mux ?? "zellij";
  try {
    if (mux === "herdr") {
      const out = execFileSync("herdr", ["pane", "list"], { encoding: "utf-8" });
      return out.includes(record.paneId);
    }
    const result = execFileSync("zellij", ["action", "list-panes"], {
      encoding: "utf-8",
    });
    return result.includes(record.paneId);
  } catch {
    return false;
  }
}

function formatAge(iso: string): string {
  const ms = Date.now() - new Date(iso).getTime();
  if (ms < 60000) return `${Math.floor(ms / 1000)}s ago`;
  if (ms < 3600000) return `${Math.floor(ms / 60000)}m ago`;
  return `${Math.floor(ms / 3600000)}h ago`;
}

// --- Spawn: zellij ---

function spawnZellij(config: ReturnType<typeof parseCli>, sanitizedName: string): string {
  const piArgs = buildPiArgs(config);

  console.log(`Spawning pane "${sanitizedName}" in zellij...`);
  printPlan("zellij", config);

  try {
    const output = execFileSync("zellij", [
      "run",
      "--name", sanitizedName,
      "--cwd", config.cwd,
      "--close-on-exit",
      "--direction", "right",
      "--",
      "pi",
      ...piArgs,
    ], {
      encoding: "utf-8",
    });
    return output.trim();
  } catch (err: any) {
    // zellij run detaches immediately and may throw despite success.
    const output = (err.stdout || "") + (err.stderr || "");
    const match = output.match(/terminal_\d+/);
    return match ? match[0] : `unknown_${Date.now()}`;
  }
}

// --- Spawn: herdr ---

/**
 * Split the focused herdr pane and run `pi` in the new pane.
 * Reusable: find focused pane -> split (down, no-focus) -> run command.
 * The new pane inherits the focused pane's cwd, so the run command `cd`s first.
 */
function spawnHerdr(config: ReturnType<typeof parseCli>, sanitizedName: string): string {
  const piArgs = buildPiArgs(config);

  console.log(`Spawning pane "${sanitizedName}" in herdr...`);
  printPlan("herdr", config);

  // 1) find the focused pane (the parent agent's pane) to split from
  const focused = herdrFocusedPane();
  if (!focused) {
    console.error("Error: no focused herdr pane found via `herdr pane list`.");
    process.exit(1);
  }

  // 2) split it (down, keep focus on the parent)
  let newPane: string;
  try {
    const raw = execFileSync(
      "herdr",
      ["pane", "split", focused, "--direction", "right", "--no-focus"],
      { encoding: "utf-8" },
    );
    newPane = JSON.parse(raw)?.result?.pane?.pane_id;
  } catch (err: any) {
    console.error("Error: herdr pane split failed:", err.message);
    process.exit(1);
  }
  if (!newPane) {
    console.error("Error: herdr pane split returned no pane id.");
    process.exit(1);
  }

  // 3) run pi in the new pane (cd to the requested cwd first)
  const cmd = `cd ${shellQuote(config.cwd)} && ${["pi", ...piArgs.map(shellQuote)].join(" ")}`;
  try {
    execFileSync("herdr", ["pane", "run", newPane, cmd], { encoding: "utf-8" });
  } catch (err: any) {
    console.error("Error: herdr pane run failed:", err.message);
    process.exit(1);
  }

  return newPane;
}

/** Parse `herdr pane list` and return the focused pane id, or null. */
function herdrFocusedPane(): string | null {
  try {
    const raw = execFileSync("herdr", ["pane", "list"], { encoding: "utf-8" });
    const panes: any[] = JSON.parse(raw)?.result?.panes ?? [];
    const focused = panes.find((p) => p.focused) ?? panes[0];
    return focused?.pane_id ?? null;
  } catch {
    return null;
  }
}

// --- Shared ---

function printPlan(mux: Mux, config: ReturnType<typeof parseCli>) {
  console.log(`  CWD:      ${config.cwd}`);
  console.log(`  Handoff:  ${config.handoff}`);
  if (config.model) console.log(`  Model:    ${config.model}`);
  if (config.thinking) console.log(`  Thinking: ${config.thinking}`);
}

function spawn(config: ReturnType<typeof parseCli>) {
  const mux = detectMux();
  if (!mux) {
    console.error("Error: not inside a supported multiplexer.");
    console.error("  Set HERDR_ENV=1 (herdr) or run inside a zellij session.");
    process.exit(1);
  }

  const sanitizedName = config.name.replace(/[^a-zA-Z0-9_-]/g, "-").slice(0, 64);
  const paneId = mux === "herdr"
    ? spawnHerdr(config, sanitizedName)
    : spawnZellij(config, sanitizedName);

  const record: PaneRecord = {
    paneId,
    name: sanitizedName,
    mux,
    cwd: config.cwd,
    handoff: config.handoff,
    model: config.model,
    thinking: config.thinking,
    spawnedAt: new Date().toISOString(),
    pid: process.pid,
  };
  savePaneRecord(record);

  const focusHint = mux === "herdr"
    ? "switch panes with your herdr pane-nav keybind (or `herdr pane list`)."
    : "switch to it with Alt+↓ or Ctrl+p.";
  console.log(`\n✅ Pane "${sanitizedName}" spawned in ${mux} (${paneId}).`);
  console.log(`   ${focusHint}`);
  console.log(`   Tracking: ${join(STATE_DIR, `${sanitizedName}.json`)}`);
}

// --- Main ---

const config = parseCli();
spawn(config);
