/**
 * Fork to Pane — Pi Extension
 *
 * Registers `/fork-to-pane` [name] command that clones the current session
 * into a new pane in the active terminal multiplexer (auto-detected:
 * herdr when HERDR_ENV=1, otherwise zellij). Uses `pi --fork <session-file>`
 * to give the new pane the full conversation history.
 *
 * Place in ~/.pi/agent/extensions/fork-to-pane.ts
 *
 * Commands:
 *   /fork-to-pane [name]       Fork current session into a new pane
 *   /fork-panes                List tracked fork panes
 *   /fork-panes-clean          Remove tracking files for dead panes
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, writeFileSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";

const STATE_DIR = "/tmp/pi-fork-to-pane/.panes";

type Mux = "zellij" | "herdr";

interface PaneRecord {
	paneId: string;
	name: string;
	mux: Mux;
	sessionFile: string;
	cwd: string;
	spawnedAt: string;
}

function savePaneRecord(record: PaneRecord) {
	mkdirSync(STATE_DIR, { recursive: true });
	writeFileSync(join(STATE_DIR, `${record.name}.json`), JSON.stringify(record, null, 2));
}

/** Detect the active terminal multiplexer from env vars. */
function detectMux(): Mux | null {
	if (process.env.HERDR_ENV === "1") return "herdr";
	if (process.env.ZELLIJ || process.env.ZELLIJ_SESSION_NAME) return "zellij";
	return null;
}

/** Single-quote a string for safe shell interpolation. */
function shellQuote(s: string): string {
	return `'${s.replace(/'/g, `'\"'\"'`)}'`;
}

/** Spawn a zellij pane running `pi --fork <sessionFile>`. */
function spawnZellij(cwd: string, sessionFile: string, sanitizedName: string): string {
	try {
		const output = execFileSync(
			"zellij",
			[
				"run",
				"--name", sanitizedName,
				"--cwd", cwd,
				"--close-on-exit",
				"--direction", "right",
				"--",
				"pi",
				"--fork", sessionFile,
			],
			{ encoding: "utf-8" },
		);
		return output.trim();
	} catch (err: unknown) {
		// zellij run detaches immediately and may throw despite success.
		const e = err as { stdout?: string; stderr?: string };
		const output = (e.stdout ?? "") + (e.stderr ?? "");
		const match = output.match(/terminal_\d+/);
		return match?.[0] ?? `unknown_${Date.now()}`;
	}
}

/** Parse `herdr pane list` and return the focused pane id, or null. */
function herdrFocusedPane(): string | null {
	try {
		const raw = execFileSync("herdr", ["pane", "list"], { encoding: "utf-8" });
		const panes: { pane_id?: string; focused?: boolean }[] =
			JSON.parse(raw)?.result?.panes ?? [];
		const focused = panes.find((p) => p.focused) ?? panes[0];
		return focused?.pane_id ?? null;
	} catch {
		return null;
	}
}

/** Split the focused herdr pane to the right and run `pi --fork <sessionFile>` in it. */
function spawnHerdr(cwd: string, sessionFile: string): string {
	const focused = herdrFocusedPane();
	if (!focused) {
		throw new Error("no focused herdr pane found via `herdr pane list`");
	}

	let newPane: string;
	try {
		const raw = execFileSync(
			"herdr",
			["pane", "split", focused, "--direction", "right", "--no-focus"],
			{ encoding: "utf-8" },
		);
		newPane = JSON.parse(raw)?.result?.pane?.pane_id;
	} catch (err: unknown) {
		throw new Error(`herdr pane split failed: ${(err as Error).message}`);
	}
	if (!newPane) {
		throw new Error("herdr pane split returned no pane id");
	}

	const cmd = `cd ${shellQuote(cwd)} && pi --fork ${shellQuote(sessionFile)}`;
	try {
		execFileSync("herdr", ["pane", "run", newPane, cmd], { encoding: "utf-8" });
	} catch (err: unknown) {
		throw new Error(`herdr pane run failed: ${(err as Error).message}`);
	}
	return newPane;
}

/** Whether a tracked pane still exists in its multiplexer. */
function isPaneAlive(record: PaneRecord): boolean {
	const mux: Mux = record.mux ?? "zellij";
	try {
		if (mux === "herdr") {
			const out = execFileSync("herdr", ["pane", "list"], { encoding: "utf-8" });
			return out.includes(record.paneId);
		}
		const result = execFileSync("zellij", ["action", "list-panes"], { encoding: "utf-8" });
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

export default function (pi: ExtensionAPI) {
	pi.registerCommand("fork-to-pane", {
		description: "Clone current session into a new pane (herdr or zellij, auto-detected)",
		handler: async (args, ctx) => {
			// --- Guard: a supported multiplexer must be active ---
			const mux = detectMux();
			if (!mux) {
				ctx.ui.notify(
					"Not inside a supported multiplexer. Start herdr or zellij first.",
					"error",
				);
				return;
			}

			// --- Guard: must have a persisted session ---
			const sessionFile = ctx.sessionManager.getSessionFile();
			if (!sessionFile) {
				ctx.ui.notify("No active session file (ephemeral mode). Cannot fork.", "error");
				return;
			}

			const cwd = ctx.sessionManager.getCwd();
			const sessionName = ctx.sessionManager.getSessionName();

			// --- Parse args ---
			// Usage: /fork-to-pane [name]
			// name defaults to session name or "fork"
			const rawName = (args ?? "").trim();
			const name = rawName || sessionName || "fork";
			const sanitizedName = name.replace(/[^a-zA-Z0-9_-]/g, "-").slice(0, 64);

			// --- Spawn ---
			let paneId: string;
			try {
				paneId = mux === "herdr"
					? spawnHerdr(cwd, sessionFile)
					: spawnZellij(cwd, sessionFile, sanitizedName);
			} catch (err: unknown) {
				ctx.ui.notify(`Failed to spawn pane: ${(err as Error).message}`, "error");
				return;
			}

			// --- Track ---
			const record: PaneRecord = {
				paneId,
				name: sanitizedName,
				mux,
				sessionFile,
				cwd,
				spawnedAt: new Date().toISOString(),
			};
			savePaneRecord(record);

			const focusHint = mux === "herdr"
				? "switch panes with your herdr keybind."
				: "switch with Alt+↓ or Ctrl+p.";
			ctx.ui.notify(
				`Forked to pane "${sanitizedName}" (${paneId}) in ${mux}. ${focusHint}`,
				"info",
			);
		},
	});

	pi.registerCommand("fork-panes", {
		description: "List tracked fork-to-pane sessions",
		handler: async (_args, ctx) => {
			if (!existsSync(STATE_DIR)) {
				ctx.ui.notify("No tracked panes.", "info");
				return;
			}

			const files = readdirSync(STATE_DIR).filter((f) => f.endsWith(".json"));
			if (files.length === 0) {
				ctx.ui.notify("No tracked panes.", "info");
				return;
			}

			const lines: string[] = ["Tracked fork panes:\n"];
			for (const f of files) {
				try {
					const record: PaneRecord = JSON.parse(readFileSync(join(STATE_DIR, f), "utf-8"));
					const alive = isPaneAlive(record);
					lines.push(
						`  ${record.name}  [${record.mux ?? "zellij"}]  (${alive ? "alive" : "gone"})  ${formatAge(record.spawnedAt)}`,
					);
				} catch {
					lines.push(`  (corrupted: ${f})`);
				}
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	pi.registerCommand("fork-panes-clean", {
		description: "Remove tracking files for dead fork-to-pane sessions",
		handler: async (_args, ctx) => {
			let files: string[];
			try {
				files = readdirSync(STATE_DIR).filter((f) => f.endsWith(".json"));
			} catch {
				ctx.ui.notify("Nothing to clean.", "info");
				return;
			}

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

			ctx.ui.notify(`Cleaned ${removed} stale tracking file(s).`, "info");
		},
	});
}
