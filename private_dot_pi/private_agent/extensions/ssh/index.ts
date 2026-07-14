import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, posix, relative, resolve } from "node:path";
import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import {
	type BashOperations,
	createBashTool,
	createEditTool,
	createFindTool,
	createGrepTool,
	createLsTool,
	createReadTool,
	createWriteTool,
	type EditOperations,
	type FindOperations,
	type GrepOperations,
	type LsOperations,
	type ReadOperations,
	type WriteOperations,
} from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth, type Focusable } from "@mariozechner/pi-tui";

interface SshHostEntry {
	alias: string;
	host: string | undefined;
	line: number;
	comment?: string;
}

interface ActiveSshTarget {
	remote: string;
	remoteCwd: string;
	explicitPath?: boolean;
}

interface PickerState {
	cursor: number;
	scrollOffset: number;
	filterQuery: string;
}

type PickerAction = { type: "select"; alias: string } | { type: "close" };

const VIEWPORT_HEIGHT = 10;
const SSH_CONFIG_PATH = join(homedir(), ".ssh", "config");

function isDirectHostAlias(token: string): boolean {
	if (!token) return false;
	if (token === "*" || token.includes("*") || token.includes("?") || token.startsWith("!")) return false;
	return true;
}

function parseSshConfig(configPath = SSH_CONFIG_PATH): SshHostEntry[] {
	if (!existsSync(configPath)) return [];
	const content = readFileSync(configPath, "utf8");
	const lines = content.split(/\r?\n/);
	const entries: SshHostEntry[] = [];
	const seen = new Set<string>();
	let pendingComment: string | undefined;
	let hostLine = -1;

	for (let i = 0; i < lines.length; i++) {
		const raw = lines[i] ?? "";
		const trimmed = raw.trim();
		if (!trimmed) {
			pendingComment = undefined;
			hostLine = -1;
			continue;
		}
		if (trimmed.startsWith("#")) {
			const comment = trimmed.replace(/^#+\s*/, "").trim();
			pendingComment = comment || pendingComment;
			continue;
		}

		const hostMatch = raw.match(/^\s*Host\s+(.+)$/i);
		if (hostMatch) {
			hostLine = i + 1;
			for (const alias of hostMatch[1]!.split(/\s+/).filter(Boolean)) {
				if (!isDirectHostAlias(alias)) continue;
				if (seen.has(alias)) continue;
				seen.add(alias);
				entries.push({ alias, host: undefined, line: i + 1, comment: pendingComment });
			}
			pendingComment = undefined;
			continue;
		}

		const hostnameMatch = raw.match(/^\s*HostName\s+(\S+)/i);
		if (hostnameMatch && hostLine > 0) {
			const host = hostnameMatch[1]!;
			for (const entry of entries) {
				if (entry.line === hostLine && !entry.host) {
					entry.host = host;
				}
			}
		}
	}

	return entries.sort((a, b) => a.alias.localeCompare(b.alias));
}

function fuzzyScore(value: string, query: string): number {
	if (!query) return 0;
	const hay = value.toLowerCase();
	const needle = query.toLowerCase();
	const idx = hay.indexOf(needle);
	if (idx >= 0) return idx;

	let pos = 0;
	for (const char of needle) {
		pos = hay.indexOf(char, pos);
		if (pos === -1) return Number.POSITIVE_INFINITY;
		pos += 1;
	}
	return 1000 + hay.length - needle.length;
}

function filterHosts(entries: SshHostEntry[], query: string): SshHostEntry[] {
	if (!query) return entries;
	return entries
		.map((entry) => ({ entry, score: fuzzyScore(`${entry.alias} ${entry.comment ?? ""}`, query) }))
		.filter((item) => Number.isFinite(item.score))
		.sort((a, b) => a.score - b.score || a.entry.alias.localeCompare(b.entry.alias))
		.map((item) => item.entry);
}

function clampCursor(state: PickerState, filtered: SshHostEntry[]): void {
	if (filtered.length === 0) {
		state.cursor = 0;
		state.scrollOffset = 0;
		return;
	}
	state.cursor = Math.max(0, Math.min(state.cursor, filtered.length - 1));
	const maxOffset = Math.max(0, filtered.length - VIEWPORT_HEIGHT);
	state.scrollOffset = Math.max(0, Math.min(state.scrollOffset, maxOffset));
	if (state.cursor < state.scrollOffset) state.scrollOffset = state.cursor;
	if (state.cursor >= state.scrollOffset + VIEWPORT_HEIGHT) state.scrollOffset = state.cursor - VIEWPORT_HEIGHT + 1;
}

function handlePickerInput(state: PickerState, entries: SshHostEntry[], data: string): PickerAction | undefined {
	const filtered = filterHosts(entries, state.filterQuery);

	if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
		if (state.filterQuery.length > 0) {
			state.filterQuery = "";
			state.cursor = 0;
			state.scrollOffset = 0;
			return;
		}
		return { type: "close" };
	}

	if (matchesKey(data, "return")) {
		const entry = filtered[state.cursor];
		if (entry) return { type: "select", alias: entry.alias };
		return;
	}

	if (matchesKey(data, "up") || matchesKey(data, "ctrl+k")) {
		state.cursor -= 1;
		clampCursor(state, filtered);
		return;
	}
	if (matchesKey(data, "down") || matchesKey(data, "ctrl+j")) {
		state.cursor += 1;
		clampCursor(state, filtered);
		return;
	}
	if (matchesKey(data, "pageup")) {
		state.cursor -= VIEWPORT_HEIGHT;
		clampCursor(state, filtered);
		return;
	}
	if (matchesKey(data, "pagedown")) {
		state.cursor += VIEWPORT_HEIGHT;
		clampCursor(state, filtered);
		return;
	}
	if (matchesKey(data, "backspace")) {
		if (state.filterQuery.length > 0) {
			state.filterQuery = state.filterQuery.slice(0, -1);
			state.cursor = 0;
			state.scrollOffset = 0;
		}
		return;
	}
	if (data.length === 1 && data.charCodeAt(0) >= 32) {
		state.filterQuery += data;
		state.cursor = 0;
		state.scrollOffset = 0;
		return;
	}
	return;
}

function formatScrollInfo(offset: number, remaining: number): string {
	if (offset === 0 && remaining <= 0) return "";
	if (remaining <= 0) return `${offset} above`;
	if (offset <= 0) return `${remaining} below`;
	return `${offset} above · ${remaining} below`;
}

function padToWidth(text: string, width: number): string {
	const w = visibleWidth(text);
	return text + " ".repeat(Math.max(0, width - w));
}

function renderPicker(
	state: PickerState,
	entries: SshHostEntry[],
	width: number,
	theme: Theme,
	current?: ActiveSshTarget | null,
): string[] {
	const filtered = filterHosts(entries, state.filterQuery);
	clampCursor(state, filtered);
	const lines: string[] = [];
	const innerWidth = Math.max(1, width - 2);
	const border = (c: string) => theme.fg("text", c);

	// Header border
	const title = ` SSH hosts [${entries.length}] `;
	const titleWidth = visibleWidth(title);
	const padLeft = Math.floor((innerWidth - titleWidth) / 2);
	const padRight = Math.max(0, innerWidth - titleWidth - padLeft);
	lines.push(border("╭") + "─".repeat(padLeft) + theme.fg("accent", title) + "─".repeat(padRight) + border("╮"));

	// Search row
	const searchIcon = theme.fg("dim", "◎");
	const placeholder = theme.fg("dim", "type to filter...");
	const queryDisplay = state.filterQuery ? state.filterQuery : placeholder;
	const searchContent = ` ${searchIcon}  ${queryDisplay}`;
	lines.push(border("│") + padToWidth(searchContent, innerWidth) + border("│"));

	// Divider
	lines.push(border("├") + "─".repeat(innerWidth) + border("┤"));

	// List entries
	const visible = filtered.slice(state.scrollOffset, state.scrollOffset + VIEWPORT_HEIGHT);
	if (filtered.length === 0) {
		const msg = theme.fg("warning", "No matching hosts");
		lines.push(border("│") + padToWidth(` ${msg}`, innerWidth) + border("│"));
		for (let i = 1; i < VIEWPORT_HEIGHT; i++) lines.push(border("│") + " ".repeat(innerWidth) + border("│"));
	} else {
		const aliasWidth = Math.min(24, Math.max(14, Math.floor(innerWidth * 0.4)));
		for (let i = 0; i < visible.length; i++) {
			const entry = visible[i]!;
			const index = state.scrollOffset + i;
			const selected = index === state.cursor;
			const prefix = selected ? theme.fg("accent", "▸ ") : "  ";
			const alias = selected ? theme.fg("accent", truncateToWidth(entry.alias, aliasWidth)) : truncateToWidth(entry.alias, aliasWidth);
			const meta = theme.fg("dim", entry.host ? entry.host : truncateToWidth(entry.comment ?? "", innerWidth - aliasWidth - 6));
			const rowContent = `${prefix}${alias}  ${meta}`;
			lines.push(border("│") + padToWidth(rowContent, innerWidth) + border("│"));
		}
		for (let i = visible.length; i < VIEWPORT_HEIGHT; i++) lines.push(border("│") + " ".repeat(innerWidth) + border("│"));
	}

	// Status/footer divider
	lines.push(border("├") + "─".repeat(innerWidth) + border("┤"));


	// Status line
	const currentLine = current ? `active: ${current.remote}:${current.remoteCwd}` : formatScrollInfo(state.scrollOffset, Math.max(0, filtered.length - (state.scrollOffset + VIEWPORT_HEIGHT)));
	const statusContent = currentLine ? ` ${theme.fg("dim", truncateToWidth(currentLine, innerWidth - 2))}` : " ";
	lines.push(border("│") + padToWidth(statusContent, innerWidth) + border("│"));


	// Footer
	const footerText = "[enter] connect  [esc] clear/close";
	const footerWidth = visibleWidth(footerText);
	const footerPadLeft = Math.floor((innerWidth - footerWidth) / 2);
	const footerPadRight = Math.max(0, innerWidth - footerWidth - footerPadLeft);
	lines.push(border("╰") + "─".repeat(footerPadLeft) + theme.fg("dim", footerText) + "─".repeat(footerPadRight) + border("╯"));

	return lines;
}

class SshPickerComponent implements Focusable {
	focused = false;
	constructor(
		private readonly state: PickerState,
		private readonly entries: SshHostEntry[],
		private readonly theme: Theme,
		private readonly current: ActiveSshTarget | null | undefined,
		private readonly onDone: (action: PickerAction) => void,
		private readonly requestRender: () => void,
	) {}

	render(width: number): string[] {
		return renderPicker(this.state, this.entries, width, this.theme, this.current);
	}

	handleInput(data: string): void {
		const action = handlePickerInput(this.state, this.entries, data);
		if (action) this.onDone(action);
		this.requestRender();
	}

	invalidate(): void {}
}

function sshExec(remote: string, command: string, options?: { input?: string | Buffer }): Promise<Buffer> {
	return new Promise((resolve, reject) => {
		const child = spawn("ssh", [remote, command], { stdio: ["pipe", "pipe", "pipe"] });
		const stdout: Buffer[] = [];
		const stderr: Buffer[] = [];
		child.stdout.on("data", (data) => stdout.push(data));
		child.stderr.on("data", (data) => stderr.push(data));
		child.on("error", reject);
		if (options?.input !== undefined) child.stdin.end(options.input);
		else child.stdin.end();
		child.on("close", (code) => {
			if (code !== 0) reject(new Error(`SSH failed (${code}): ${Buffer.concat(stderr).toString().trim()}`));
			else resolve(Buffer.concat(stdout));
		});
	});
}

function createPathMapper(remoteCwd: string, localCwd: string): (p: string) => string {
	const localRoot = resolve(localCwd);
	return (p: string) => {
		if (!p) return remoteCwd;
		if (!isAbsolute(p)) return posix.normalize(posix.join(remoteCwd, p.replace(/\\/g, "/")));
		const absolute = resolve(p);
		if (absolute === localRoot) return remoteCwd;
		const rel = relative(localRoot, absolute);
		if (!rel || (!rel.startsWith("..") && rel !== ".")) {
			return posix.normalize(posix.join(remoteCwd, rel.replace(/\\/g, "/")));
		}
		throw new Error(`Path is outside the mapped workspace: ${p}`);
	};
}

function createRemoteReadOps(remote: string, remoteCwd: string, localCwd: string): ReadOperations {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		readFile: (p) => sshExec(remote, `cat ${shellQuote(toRemote(p))}`),
		access: (p) => sshExec(remote, `test -r ${shellQuote(toRemote(p))}`).then(() => {}),
		detectImageMimeType: async (p) => {
			try {
				const result = await sshExec(
					remote,
					`if command -v file >/dev/null 2>&1; then file --mime-type -b ${shellQuote(toRemote(p))}; fi`,
				);
				const mime = result.toString().trim();
				return ["image/jpeg", "image/png", "image/gif", "image/webp"].includes(mime) ? mime : null;
			} catch {
				return null;
			}
		},
	};
}

function createRemoteWriteOps(remote: string, remoteCwd: string, localCwd: string): WriteOperations {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		writeFile: async (p, content) => {
			await sshExec(remote, `cat > ${shellQuote(toRemote(p))}`, { input: content });
		},
		mkdir: (dir) => sshExec(remote, `mkdir -p ${shellQuote(toRemote(dir))}`).then(() => {}),
	};
}

function createRemoteEditOps(remote: string, remoteCwd: string, localCwd: string): EditOperations {
	const readOps = createRemoteReadOps(remote, remoteCwd, localCwd);
	const writeOps = createRemoteWriteOps(remote, remoteCwd, localCwd);
	return { readFile: readOps.readFile, access: readOps.access, writeFile: writeOps.writeFile };
}

function createRemoteFindOps(remote: string, remoteCwd: string, localCwd: string): FindOperations {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		exists: (p) => sshExec(remote, `test -e ${shellQuote(toRemote(p))}`).then(() => true, () => false),
		glob: (pattern, cwd, opts) =>
			sshExec(
				remote,
				buildRemoteFdCommand(pattern, toRemote(cwd), opts),
			).then((b) =>
				b
					.toString()
					.trim()
					.split("\n")
					.filter(Boolean),
			),
	};
}

function buildRemoteFdCommand(
	pattern: string,
	remoteDir: string,
	opts: { ignore: string[]; limit: number },
): string {
	const limitArg = opts.limit ? `--max-results ${opts.limit}` : "";
	const ignoreArgs = opts.ignore.map((i) => `--exclude ${shellQuote(i)}`).join(" ");
	const headLimit = opts.limit ? ` | head -n ${opts.limit}` : "";
	return `if command -v fd >/dev/null 2>&1; then fd --type f --glob --follow --hidden ${limitArg} ${ignoreArgs} ${shellQuote(pattern)} ${shellQuote(remoteDir)} 2>/dev/null; else find ${shellQuote(remoteDir)} -type f -name ${shellQuote(pattern)}${headLimit}; fi`;
}

function createRemoteLsOps(remote: string, remoteCwd: string, localCwd: string): LsOperations {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		exists: (p) => sshExec(remote, `test -e ${shellQuote(toRemote(p))}`).then(() => true, () => false),
		stat: async (p) => {
			const isDir = await sshExec(remote, `test -d ${shellQuote(toRemote(p))}`).then(
				() => true,
				() => false,
			);
			return { isDirectory: () => isDir };
		},
		readdir: (p) =>
			sshExec(remote, `ls -1A ${shellQuote(toRemote(p))}`).then((b) =>
				b.toString().trim().split("\n").filter(Boolean),
			),
	};
}

function createRemoteGrepOps(remote: string, remoteCwd: string, localCwd: string): GrepOperations {
	const readOps = createRemoteReadOps(remote, remoteCwd, localCwd);
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		isDirectory: (p) => sshExec(remote, `test -d ${shellQuote(toRemote(p))}`).then(() => true, () => false),
		readFile: (p) => readOps.readFile(p).then((b) => b.toString()),
	};
}

/** Execute remote search over SSH, preferring rg and falling back to grep. */
async function executeRemoteGrep(
	remote: string,
	remoteCwd: string,
	localCwd: string,
	_id: string,
	params: { pattern: string; path?: string; glob?: string; ignoreCase?: boolean; literal?: boolean; context?: number; limit?: number },
	signal: AbortSignal | undefined,
	_onUpdate: unknown,
): Promise<{ content: { type: "text"; text: string }[]; details: Record<string, unknown> | undefined }> {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	const searchPath = toRemote(params.path || localCwd);
	const effectiveLimit = Math.max(1, params.limit ?? 100);
	const args = ["rg", "-n", "-H", "--color=never", "--hidden", "--max-count", String(effectiveLimit)];
	if (params.ignoreCase) args.push("--ignore-case");
	if (params.literal) args.push("--fixed-strings");
	if (typeof params.context === "number" && params.context > 0) args.push("--context", String(params.context));
	if (params.glob) args.push("--glob", shellQuote(params.glob));
	args.push(shellQuote(params.pattern), shellQuote(searchPath));
	const grepArgs = ["grep", "-RIn", "--binary-files=without-match"];
	if (params.ignoreCase) grepArgs.push("-i");
	if (typeof params.context === "number" && params.context > 0) grepArgs.push(`-C ${params.context}`);
	grepArgs.push(params.literal ? "-F" : "-E", "--", shellQuote(params.pattern), shellQuote(searchPath));
	const remoteCmd = `if command -v rg >/dev/null 2>&1; then ${args.join(" ")}; else ${grepArgs.join(" ")} | head -n ${effectiveLimit}; fi`;

	return new Promise((resolve, reject) => {
		if (signal?.aborted) {
			reject(new Error("Operation aborted"));
			return;
		}
		const child = spawn("ssh", [remote, remoteCmd], { stdio: ["ignore", "pipe", "pipe"] });
		const chunks: Buffer[] = [];
		let stderr = "";
		let aborted = false;
		const onAbort = () => {
			aborted = true;
			child.kill();
		};
		signal?.addEventListener("abort", onAbort, { once: true });
		child.stdout.on("data", (data: Buffer) => chunks.push(data));
		child.stderr.on("data", (chunk: Buffer) => {
			stderr += chunk.toString();
		});
		child.on("error", (error) => reject(error));
		child.on("close", (code) => {
			signal?.removeEventListener("abort", onAbort);
			if (aborted) return reject(new Error("Operation aborted"));
			if (code !== 0 && code !== 1) return reject(new Error(stderr.trim() || `search exited with code ${code}`));
			let text = Buffer.concat(chunks).toString().replaceAll(`${remoteCwd}/`, "");
			if (!text.trim()) text = "No matches found";
			const lines = text.split("\n");
			const details: Record<string, unknown> = {};
			if (lines.filter((line) => line && line !== "--").length >= effectiveLimit) details.matchLimitReached = effectiveLimit;
			resolve({ content: [{ type: "text", text: text.trimEnd() }], details: Object.keys(details).length ? details : undefined });
		});
	});
}

/** Minimal shell quoting for args passed to ssh. */
function shellQuote(s: string): string {
	return `'${s.replace(/'/g, "'\\''")}'`;
}

function createRemoteBashOps(remote: string, remoteCwd: string, localCwd: string): BashOperations {
	const toRemote = createPathMapper(remoteCwd, localCwd);
	return {
		exec: (command, cwd, { onData, signal, timeout }) =>
			new Promise((resolve, reject) => {
				const remoteCommand = `cd ${shellQuote(toRemote(cwd))} && ${command}`;
				const child = spawn("ssh", [remote, remoteCommand], { stdio: ["ignore", "pipe", "pipe"] });
				let timedOut = false;
				const timer = timeout
					? setTimeout(() => {
							timedOut = true;
							child.kill();
						}, timeout * 1000)
					: undefined;
				child.stdout.on("data", onData);
				child.stderr.on("data", onData);
				child.on("error", (error) => {
					if (timer) clearTimeout(timer);
					reject(error);
				});
				const onAbort = () => child.kill();
				signal?.addEventListener("abort", onAbort, { once: true });
				child.on("close", (code) => {
					if (timer) clearTimeout(timer);
					signal?.removeEventListener("abort", onAbort);
					if (signal?.aborted) reject(new Error("aborted"));
					else if (timedOut) reject(new Error(`timeout:${timeout}`));
					else resolve({ exitCode: code });
				});
			}),
	};
}

export default function sshPickerExtension(pi: ExtensionAPI) {
	const localCwd = process.cwd();
	const localRead = createReadTool(localCwd);
	const localWrite = createWriteTool(localCwd);
	const localEdit = createEditTool(localCwd);
	const localBash = createBashTool(localCwd);
	const localFind = createFindTool(localCwd);
	const localLs = createLsTool(localCwd);
	const localGrep = createGrepTool(localCwd);
	let activeTarget: ActiveSshTarget | null = null;

	function getTarget(): ActiveSshTarget | null {
		return activeTarget;
	}

	function persistState(target: ActiveSshTarget | null): void {
		pi.appendEntry("ssh-state", target);
	}

	function updateStatus(ctx: ExtensionContext): void {
		if (!activeTarget) {
			ctx.ui.setStatus("ssh", undefined);
			return;
		}
		ctx.ui.setStatus("ssh", ctx.ui.theme.fg("accent", `ssh:${activeTarget.remote}`));
	}

	function parseTargetSpec(input: string): { remote: string; remotePath?: string } {
		const trimmed = input.trim();
		const colonIndex = trimmed.indexOf(":");
		if (colonIndex > 0) {
			const remote = trimmed.slice(0, colonIndex).trim();
			const remotePath = trimmed.slice(colonIndex + 1).trim();
			if (remotePath.startsWith("/") || remotePath.startsWith("~")) return { remote, remotePath };
		}
		return { remote: trimmed };
	}

	async function resolveRemoteCwd(remote: string, remotePath?: string): Promise<string> {
		const command = remotePath ? `cd ${shellQuote(remotePath)} && pwd` : "pwd";
		return (await sshExec(remote, command)).toString().trim() || remotePath || "~";
	}

	async function setActiveTarget(input: string, ctx: ExtensionContext): Promise<void> {
		const { remote, remotePath } = parseTargetSpec(input);
		const remoteCwd = await resolveRemoteCwd(remote, remotePath);
		activeTarget = { remote, remoteCwd, explicitPath: Boolean(remotePath) };
		persistState(activeTarget);
		updateStatus(ctx);
		ctx.ui.notify(`SSH mode enabled: ${remote}:${remoteCwd}`, "info");
	}

	async function trySetActiveTarget(remote: string, ctx: ExtensionContext): Promise<void> {
		try {
			await setActiveTarget(remote, ctx);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			ctx.ui.notify(`Failed to enable SSH mode for ${remote}: ${message}`, "error");
		}
	}

	function clearActiveTarget(ctx: ExtensionContext): void {
		activeTarget = null;
		persistState(null);
		updateStatus(ctx);
		ctx.ui.notify("SSH mode cleared", "info");
	}

	async function showPicker(ctx: ExtensionContext): Promise<void> {
		const entries = parseSshConfig();
		if (entries.length === 0) {
			ctx.ui.notify(`No direct Host entries found in ${SSH_CONFIG_PATH}`, "warning");
			return;
		}

		const state: PickerState = { cursor: 0, scrollOffset: 0, filterQuery: "" };
		const result = await ctx.ui.custom<PickerAction>(
			(tui, theme, _kb, done) => {
				return new SshPickerComponent(state, entries, theme, activeTarget, done, () => tui.requestRender());
			},
			{
				overlay: true,
				overlayOptions: {
					anchor: "center",
					width: 52,
					maxHeight: VIEWPORT_HEIGHT + 7,
				},
			},
		);

		if (result.type === "select") {
			await trySetActiveTarget(result.alias, ctx);
		}
	}

	pi.registerCommand("ssh", {
		description: "Pick or clear an SSH target for remote read/write/edit/grep/find/ls/bash. Accepts alias or alias:/remote/path",
		handler: async (args, ctx) => {
			const input = (args ?? "").trim();
			if (input === "off" || input === "clear" || input === "none") {
				clearActiveTarget(ctx);
				return;
			}
			if (input === "status") {
				if (activeTarget) ctx.ui.notify(`SSH mode: ${activeTarget.remote}:${activeTarget.remoteCwd}`, "info");
				else ctx.ui.notify("SSH mode is inactive", "info");
				return;
			}
			if (input) {
				const aliases = new Set(parseSshConfig().map((entry) => entry.alias));
				const { remote } = parseTargetSpec(input);
				if (!aliases.has(remote)) {
					ctx.ui.notify(`SSH host not found in ${SSH_CONFIG_PATH}: ${remote}`, "error");
					return;
				}
				await trySetActiveTarget(input, ctx);
				return;
			}
			await showPicker(ctx);
		},
	});

	pi.registerTool({
		...localRead,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localRead.execute(id, params, signal, onUpdate);
			const tool = createReadTool(localCwd, { operations: createRemoteReadOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localWrite,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localWrite.execute(id, params, signal, onUpdate);
			const tool = createWriteTool(localCwd, { operations: createRemoteWriteOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localEdit,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localEdit.execute(id, params, signal, onUpdate);
			const tool = createEditTool(localCwd, { operations: createRemoteEditOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localBash,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localBash.execute(id, params, signal, onUpdate);
			const tool = createBashTool(localCwd, { operations: createRemoteBashOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localFind,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localFind.execute(id, params, signal, onUpdate);
			const tool = createFindTool(localCwd, { operations: createRemoteFindOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localLs,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localLs.execute(id, params, signal, onUpdate);
			const tool = createLsTool(localCwd, { operations: createRemoteLsOps(target.remote, target.remoteCwd, localCwd) });
			return tool.execute(id, params, signal, onUpdate);
		},
	});

	pi.registerTool({
		...localGrep,
		async execute(id, params, signal, onUpdate) {
			const target = getTarget();
			if (!target) return localGrep.execute(id, params, signal, onUpdate);
			return executeRemoteGrep(target.remote, target.remoteCwd, localCwd, id, params, signal, onUpdate);
		},
	});

	pi.on("user_bash", () => {
		const target = getTarget();
		if (!target) return;
		return { operations: createRemoteBashOps(target.remote, target.remoteCwd, localCwd) };
	});

	pi.on("before_agent_start", async (event) => {
		const target = getTarget();
		if (!target) return;
		const sshPrompt = [
			`[SSH MODE ACTIVE]`,
			`- You are operating on a REMOTE machine via SSH: ${target.remote}`,
			`- Remote working directory: ${target.remoteCwd}`,
			`- All file operations (read, write, edit, grep, find, ls) and bash commands are executed on the remote host.`,
			`- Paths are automatically translated: local (${localCwd}) → remote (${target.remoteCwd}).`,
			`- Prefer using the dedicated tools (read, write, edit, grep, find, ls, bash) over raw ssh commands.`,
		].join("\n");
		return {
			systemPrompt:
				event.systemPrompt.replace(
					`Current working directory: ${localCwd}`,
					`Current working directory: ${target.remoteCwd} (via SSH: ${target.remote})`,
				) +
				"\n\n" +
				sshPrompt,
		};
	});

	pi.on("input", async (event) => {
		const target = getTarget();
		if (!target) return;
		if (event.source === "extension") return;
		return {
			action: "transform",
			text: `[SSH MODE ACTIVE — remote: ${target.remote}, cwd: ${target.remoteCwd}]\n\n${event.text}`,
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		const entry = ctx.sessionManager
			.getEntries()
			.filter((item: { type: string; customType?: string }) => item.type === "custom" && item.customType === "ssh-state")
			.pop() as { data?: ActiveSshTarget | null } | undefined;
		const restored = entry?.data ?? null;
		if (!restored) {
			activeTarget = null;
			updateStatus(ctx);
			return;
		}
		try {
			const remoteCwd = await resolveRemoteCwd(restored.remote, restored.explicitPath ? restored.remoteCwd : undefined);
			activeTarget = { ...restored, remoteCwd };
			updateStatus(ctx);
		} catch (error) {
			activeTarget = null;
			persistState(null);
			updateStatus(ctx);
			const message = error instanceof Error ? error.message : String(error);
			ctx.ui.notify(`Unable to restore SSH mode for ${restored.remote}: ${message}`, "warning");
		}
	});
}
