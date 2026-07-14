/**
 * Pura Read Extension
 * https://github.com/0xfraso/pura
 * 
 * Intercepts read tool results and proxies content through a local Pura server
 * to automatically redact PII (names, emails, phones, addresses, dates, secrets).
 * 
 * The raw content is never exposed to the agent - only the redacted version is returned.
 * 
 * Requires: Pura server running locally (default: http://localhost:8010)
 * 
 * Usage:
 *   pi -e ~/.pi/agent/extensions/pura-read.ts
 * 
 * Or install permanently by placing in ~/.pi/agent/extensions/ (auto-discovered)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

const PURA_URL = process.env.PURA_URL ?? "http://localhost:8010";
const SCAN_ENDPOINT = `${PURA_URL}/scan`;
const HEALTH_ENDPOINT = `${PURA_URL}`;

interface PuraScanResponse {
  original: string;
  redacted: string;
  spans: Array<{
    entity: string;
    text: string;
    start: number;
    end: number;
    score: number;
  }>;
}

let redactionEnabled = false;

async function checkPuraHealth(): Promise<{ healthy: boolean; modelLoaded: boolean }> {
  try {
    const response = await fetch(HEALTH_ENDPOINT, {
      method: "GET",
      signal: AbortSignal.timeout(3000),
    });
    if (!response.ok) return { healthy: false, modelLoaded: false };
    const data = (await response.json()) as { status?: string; model_loaded?: boolean };
    return {
      healthy: data?.status === "ok",
      modelLoaded: data?.model_loaded === true,
    };
  } catch {
    return { healthy: false, modelLoaded: false };
  }
}

async function redactWithPura(text: string, signal?: AbortSignal): Promise<string> {
  const response = await fetch(SCAN_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
    signal,
  });

  if (!response.ok) {
    throw new Error(`Pura server error: ${response.status} ${response.statusText}`);
  }

  const data = (await response.json()) as PuraScanResponse;
  return data.redacted;
}

function updateStatus(ctx: any) {
  if (redactionEnabled) {
    ctx.ui.setStatus("pura", ctx.ui.theme.fg("success", "● Pura"));
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pura", {
    description: "Toggle Pura PII redaction on/off (usage: /pura, /pura on, /pura off)",
    handler: async (args, ctx) => {
      if (args === "off") {
        redactionEnabled = false;
        ctx.ui.notify("Pura PII redaction disabled", "info");
      } else if (args === "on") {
        redactionEnabled = true;
        ctx.ui.notify("Pura PII redaction enabled", "info");
      } else {
        redactionEnabled = !redactionEnabled;
        ctx.ui.notify(`Pura PII redaction ${redactionEnabled ? "enabled" : "disabled"}`, "info");
      }
      updateStatus(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    const { healthy, modelLoaded } = await checkPuraHealth();

    if ((!healthy || !modelLoaded) && redactionEnabled) {
      ctx.ui.setStatus("pura", ctx.ui.theme.fg("error", "● Pura: offline"));
      return;
    }

    updateStatus(ctx);
  });

  pi.on("tool_result", async (event, ctx) => {
    if (!redactionEnabled) return;
    if (!isToolCallEventType("read", event)) return;
    if (event.details?.redacted) return;

    const textParts = event.content.filter(
      (c): c is { type: "text"; text: string } => c.type === "text"
    );

    if (textParts.length === 0) return;

    try {
      const redactedParts = await Promise.all(
        textParts.map((part) => redactWithPura(part.text, ctx.signal))
      );

      const newContent = event.content.map((c, i) =>
        c.type === "text" ? { type: "text", text: redactedParts[i] } : c
      );

      return {
        content: newContent,
        details: { ...event.details, redacted: true },
      };
    } catch (error: any) {
      console.error("[pura-read] Error:", error.message);
    }
  });
}
