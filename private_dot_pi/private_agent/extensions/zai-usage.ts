/**
 * ZAI Usage Query — Pi Extension
 *
 * Queries Z.ai or ZHIPU usage API based on ANTHROPIC_BASE_URL / ZAI_API_KEY.
 * Exposes a `zai_usage` tool (callable by the LLM) and a `/zai-usage` command.
 *
 * Place in ~/.pi/agent/extensions/zai-usage.ts
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

// ── helpers ──────────────────────────────────────────────────────────────

interface PlatformConfig {
	platform: "ZAI" | "ZHIPU";
	baseDomain: string;
	modelUsageUrl: string;
	toolUsageUrl: string;
	quotaLimitUrl: string;
}

function resolvePlatform(): PlatformConfig {
	const baseUrl =
		process.env.ANTHROPIC_BASE_URL || "https://api.z.ai/api/coding/paas/v4";

	const parsed = new URL(baseUrl);
	const baseDomain = `${parsed.protocol}//${parsed.host}`;

	if (baseUrl.includes("api.z.ai")) {
		return {
			platform: "ZAI",
			baseDomain,
			modelUsageUrl: `${baseDomain}/api/monitor/usage/model-usage`,
			toolUsageUrl: `${baseDomain}/api/monitor/usage/tool-usage`,
			quotaLimitUrl: `${baseDomain}/api/monitor/usage/quota/limit`,
		};
	}

	if (
		baseUrl.includes("open.bigmodel.cn") ||
		baseUrl.includes("dev.bigmodel.cn")
	) {
		return {
			platform: "ZHIPU",
			baseDomain,
			modelUsageUrl: `${baseDomain}/api/monitor/usage/model-usage`,
			toolUsageUrl: `${baseDomain}/api/monitor/usage/tool-usage`,
			quotaLimitUrl: `${baseDomain}/api/monitor/usage/quota/limit`,
		};
	}

	throw new Error(
		`Unrecognized ANTHROPIC_BASE_URL: ${baseUrl}\n` +
			"Supported: https://api.z.ai/api/anthropic, https://open.bigmodel.cn/api/anthropic",
	);
}

function formatDateTime(date: Date): string {
	const pad = (n: number) => String(n).padStart(2, "0");
	return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

interface TimeWindow {
	startTime: string;
	endTime: string;
}

function getDefaultTimeWindow(): TimeWindow {
	const now = new Date();
	const startDate = new Date(
		now.getFullYear(),
		now.getMonth(),
		now.getDate() - 1,
		now.getHours(),
		0,
		0,
		0,
	);
	const endDate = new Date(
		now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		now.getHours(),
		59,
		59,
		999,
	);
	return {
		startTime: formatDateTime(startDate),
		endTime: formatDateTime(endDate),
	};
}

async function queryUsage(
	url: string,
	authToken: string,
	queryParams: string,
): Promise<unknown> {
	const response = await fetch(`${url}${queryParams}`, {
		headers: {
			Authorization: authToken,
			"Accept-Language": "en-US,en",
			"Content-Type": "application/json",
		},
	});

	if (!response.ok) {
		const body = await response.text().catch(() => "");
		throw new Error(`HTTP ${response.status} from ${url}: ${body}`);
	}

	return response.json();
}

function processQuotaLimit(data: unknown): unknown {
	if (!data || typeof data !== "object" || !("limits" in data)) return data;
	const d = data as { limits: Array<Record<string, unknown>> };

	// Filter and classify by unit to handle multiple TOKENS_LIMIT entries
	// unit 3 = 5-hour rolling, unit 4 = daily (skip), unit 6 = weekly
	d.limits = d.limits
		.filter((item) => {
			// Skip daily TOKENS_LIMIT (unit 4)
			if (item.type === "TOKENS_LIMIT" && item.unit === 4) return false;
			return true;
		})
		.map((item) => {
			if (item.type === "TOKENS_LIMIT") {
				const unit = item.unit as number;
				const label = unit === 3 ? "Token usage (5 Hour)" : unit === 6 ? "Token usage (7 Day)" : "Token usage";
				return {
					type: label,
					unit,
					percentage: item.percentage,
					currentUsage: item.currentValue,
					total: item.usage,
					remaining: item.remaining,
					nextResetTime: item.nextResetTime,
				};
			}
			if (item.type === "TIME_LIMIT") {
				return {
					type: "MCP usage (1 Month)",
					percentage: item.percentage,
					currentUsage: item.currentValue,
					total: item.usage,
					usageDetails: item.usageDetails,
				};
			}
			return item;
		});

	return d;
}

// ── main query ───────────────────────────────────────────────────────────

export interface UsageResult {
	platform: string;
	timeWindow: TimeWindow;
	modelUsage: unknown;
	toolUsage: unknown;
	quotaLimit: unknown;
}

async function queryZaiUsage(): Promise<UsageResult> {
	const apiKey = process.env.ZAI_API_KEY || "";
	if (!apiKey) {
		throw new Error(
			"ZAI_API_KEY is not set.\n" +
				"Set the environment variable and retry.",
		);
	}

	const config = resolvePlatform();
	const window = getDefaultTimeWindow();
	const params = `?startTime=${encodeURIComponent(window.startTime)}&endTime=${encodeURIComponent(window.endTime)}`;

	const [modelUsageRaw, toolUsageRaw, quotaRaw] = await Promise.all([
		queryUsage(config.modelUsageUrl, apiKey, params),
		queryUsage(config.toolUsageUrl, apiKey, params),
		queryUsage(config.quotaLimitUrl, apiKey, ""),
	]);

	const modelUsage = (modelUsageRaw as { data?: unknown })?.data ?? modelUsageRaw;
	const toolUsage = (toolUsageRaw as { data?: unknown })?.data ?? toolUsageRaw;
	const quotaLimit = processQuotaLimit(
		(quotaRaw as { data?: unknown })?.data ?? quotaRaw,
	);

	return {
		platform: config.platform,
		timeWindow: window,
		modelUsage,
		toolUsage,
		quotaLimit,
	};
}

// ── formatting ───────────────────────────────────────────────────────────

function formatTokens(n: number): string {
	if (n >= 1_000_000_000) return `${(n / 1_000_000_000).toFixed(1)}B`;
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
	return String(n);
}

function formatNumber(n: number): string {
	return n.toLocaleString("en-US");
}

function progressBar(pct: number, width = 30): string {
	const filled = Math.round((pct / 100) * width);
	const empty = width - filled;
	return `[${"█".repeat(filled)}${"░".repeat(empty)}]`;
}

function formatTimeUntilReset(nextResetTimeMs: number | undefined): string {
	if (!nextResetTimeMs || !Number.isFinite(nextResetTimeMs)) {
		return "unknown";
	}
	const ms = nextResetTimeMs > 1_000_000_000_000 ? nextResetTimeMs : nextResetTimeMs * 1000;
	const diff = ms - Date.now();
	if (diff <= 0) return "soon";
	const hours = Math.floor(diff / 3_600_000);
	const mins = Math.floor((diff % 3_600_000) / 60_000);
	if (hours > 0) return `~${hours}h ${mins}m`;
	if (mins > 0) return `~${mins}m`;
	const secs = Math.floor(diff / 1000);
	return `~${secs}s`;
}

function daysUntilEndOfMonth(): string {
	const now = new Date();
	const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
	const days = endOfMonth.getDate() - now.getDate();
	if (days === 0) return "today";
	return `${days}d`;
}

function formatUsageResult(result: UsageResult): string {
	const quota = result.quotaLimit as {
		limits?: Array<Record<string, unknown>>;
		level?: string;
	};
	const modelData = result.modelUsage as {
		totalUsage?: {
			totalModelCallCount?: number;
			totalTokensUsage?: number;
			modelSummaryList?: Array<{ modelName: string; totalTokens: number }>;
		};
	};

	const lines: string[] = [];

	// Header
	const level = quota?.level ? ` (${quota.level})` : "";
	lines.push(`ZAI Usage — ${result.platform}${level}`);
	lines.push("─".repeat(52));

	// Quota bars
	lines.push("");
	lines.push("Quotas:");

	if (quota?.limits) {
		for (const limit of quota.limits) {
			const type = String(limit.type ?? "");
			if (type === "Token usage (5 Hour)") {
				const pct = Number(limit.percentage ?? 0);
				const reset = formatTimeUntilReset(limit.nextResetTime as number | undefined);
				lines.push(
					`  Tokens (5h rolling)  ${progressBar(pct)} ${String(pct).padStart(3)}%  resets in ${reset}`,
				);
			} else if (type === "Token usage (7 Day)") {
				const pct = Number(limit.percentage ?? 0);
				const reset = formatTimeUntilReset(limit.nextResetTime as number | undefined);
				lines.push(
					`  Tokens (7d rolling)  ${progressBar(pct)} ${String(pct).padStart(3)}%  resets in ${reset}`,
				);
			} else if (type === "MCP usage (1 Month)") {
				const pct = Number(limit.percentage ?? 0);
				const used = Number(limit.currentUsage ?? 0);
				const total = Number(limit.total ?? 0);
				const reset = daysUntilEndOfMonth();
				lines.push(
					`  MCP calls (monthly)  ${progressBar(pct)} ${String(used)}/${total}  resets in ${reset}`,
				);
			}
		}
	}

	// Model summary
	lines.push("");
	lines.push("Models (last 25h):");

	const summaries = modelData?.totalUsage?.modelSummaryList ?? [];
	let totalTokens = 0;
	for (const m of summaries) {
		totalTokens += m.totalTokens;
		lines.push(
			`  ${m.modelName.padEnd(14)} ${formatTokens(m.totalTokens).padStart(8)} tokens`,
		);
	}

	const totalCalls = modelData?.totalUsage?.totalModelCallCount ?? 0;
	lines.push(
		`  ${"Total".padEnd(14)} ${formatTokens(totalTokens).padStart(8)} tokens │ ${formatNumber(totalCalls)} calls`,
	);

	return lines.join("\n");
}

// ── widget helpers ───────────────────────────────────────────────────────

interface QuotaBar {
	label: string;
	pct: number;
	reset: string;
	usedLabel?: string;
}

function extractQuotaBars(quotaLimit: unknown): QuotaBar[] {
	const q = quotaLimit as { limits?: Array<Record<string, unknown>> };
	if (!q?.limits) return [];
	const bars: QuotaBar[] = [];
	for (const limit of q.limits) {
		const type = String(limit.type ?? "");
		if (type === "Token usage (5 Hour)") {
			bars.push({
				label: "5h",
				pct: Number(limit.percentage ?? 0),
				reset: formatTimeUntilReset(limit.nextResetTime as number | undefined),
			});
		} else if (type === "Token usage (7 Day)") {
			bars.push({
				label: "7d",
				pct: Number(limit.percentage ?? 0),
				reset: formatTimeUntilReset(limit.nextResetTime as number | undefined),
			});

		}
	}
	return bars;
}

/** Fetch quota only (lightweight, no model-usage query). */
async function fetchQuotaOnly(): Promise<unknown> {
	const apiKey = process.env.ZAI_API_KEY || "";
	if (!apiKey) return null;
	const config = resolvePlatform();
	const raw = await queryUsage(config.quotaLimitUrl, apiKey, "");
	return processQuotaLimit((raw as { data?: unknown })?.data ?? raw);
}

function isZaiProvider(ctx: { model?: { provider?: string } | null }): boolean {
	const p = ctx.model?.provider?.toLowerCase() ?? "";
	return p === "zai" || p === "zai-coding-plan" || p === "zhipu";
}

// ── extension ────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {

	// ── TUI widget & status ──
	const CACHE_TTL_MS = 30_000;
	let cachedQuota: unknown = null;
	let cachedAt = 0;

	function isCacheFresh(): boolean {
		return cachedQuota !== null && Date.now() - cachedAt < CACHE_TTL_MS;
	}

	async function refreshQuota(): Promise<void> {
		try {
			cachedQuota = await fetchQuotaOnly();
			cachedAt = Date.now();
		} catch {
			// silent — widget just won't update
		}
	}

	function updateWidget(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;

		const bars = extractQuotaBars(cachedQuota);

		if (bars.length === 0) {
			ctx.ui.setWidget("zai-usage", undefined);
			return;
		}

		// Compact one-liner per quota
		const theme = ctx.ui.theme;
		const lines = bars.map((bar) => {
			const pct = Math.min(bar.pct, 100);
			const color = pct >= 90 ? "error" : pct >= 70 ? "warning" : "success";
			const fill = "█".repeat(Math.round(pct / 5));
			const empty = "░".repeat(20 - Math.round(pct / 5));
			const barStr = theme.fg(color, fill) + theme.fg("dim", empty);
			const extra = bar.usedLabel ? ` ${bar.usedLabel}` : "";
			return `${theme.fg("dim", `${bar.label}`)} ${barStr} ${theme.fg(color, `${String(pct).padStart(3)}%`)}${extra} ${theme.fg("dim", bar.reset)}`;
		});

		ctx.ui.setWidget("zai-usage", lines);
	}

	function clearWidget(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		ctx.ui.setWidget("zai-usage", undefined);
	}

	async function refreshAndUpdate(ctx: ExtensionContext): Promise<void> {
		if (!isZaiProvider(ctx)) {
			clearWidget(ctx);
			return;
		}
		if (!isCacheFresh()) {
			await refreshQuota();
		}
		updateWidget(ctx);
	}

	pi.on("session_start", async (_event, ctx) => {
		await refreshAndUpdate(ctx);
	});

	pi.on("model_select", async (_event, ctx) => {
		if (isZaiProvider(ctx)) {
			cachedQuota = null; // force refresh on provider switch
			await refreshAndUpdate(ctx);
		} else {
			clearWidget(ctx);
		}
	});

	pi.on("turn_end", async (_event, ctx) => {
		if (isZaiProvider(ctx)) {
			cachedQuota = null; // force refresh after each turn for accuracy
			await refreshAndUpdate(ctx);
		}
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		clearWidget(ctx);
	});

	pi.registerTool({
		name: "zai_usage",
		label: "ZAI Usage",
		description:
			"Query current Z.ai or ZHIPU usage statistics including model usage, tool usage, and quota limits. " +
			"Requires ZAI_API_KEY to be set. Defaults to ZAI coding plan API (https://api.z.ai/api/coding/paas/v4) " +
			"unless ANTHROPIC_BASE_URL is set to a different value.",
		promptSnippet: "Query Z.ai / ZHIPU usage, quota, and limits",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, signal) {
			try {
				const result = await queryZaiUsage();
				return {
					content: [{ type: "text", text: formatUsageResult(result) }],
					details: result,
				};
			} catch (err) {
				throw new Error(
					`ZAI usage query failed: ${err instanceof Error ? err.message : String(err)}`,
				);
			}
		},
	});

	pi.registerCommand("zai-usage", {
		description: "Query Z.ai / ZHIPU usage, quota, and limits",
		handler: async (_args, ctx) => {
			try {
				const result = await queryZaiUsage();
				ctx.ui.notify(
					`ZAI Usage (${result.platform}) — fetched successfully`,
					"info",
				);
				// Show in a user-friendly way via the console
				pi.sendMessage({
					customType: "zai-usage",
					content: formatUsageResult(result),
					display: true,
					details: result,
				});
			} catch (err) {
				ctx.ui.notify(
					`ZAI usage query failed: ${err instanceof Error ? err.message : String(err)}`,
					"error",
				);
			}
		},
	});
}
