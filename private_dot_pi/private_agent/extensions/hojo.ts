import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const API_BASE = `http://localhost:${process.env.PORT ?? "6000"}`;

async function apiGet(path: string): Promise<unknown> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) throw new Error(`API GET ${path} → ${res.status}`);
  return res.json();
}

async function apiPost(path: string, body?: unknown): Promise<unknown> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`API POST ${path} → ${res.status}`);
  return res.json();
}

async function apiPut(path: string, body?: unknown): Promise<unknown> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`API PUT ${path} → ${res.status}`);
  return res.json();
}

function ok(data: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }], details: {} };
}

function fail(message: string) {
  return { content: [{ type: "text" as const, text: `Error: ${message}` }], details: {}, isError: true as const };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "list_sources",
    label: "List Source Pages",
    description: "List all wiki source pages. Each corresponds to a processed YouTube video with summary and key takeaways.",
    parameters: Type.Object({}),
    async execute() {
      try { return ok(await apiGet("/wiki/sources")); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "read_source",
    label: "Read Source Page",
    description: "Read the full wiki source page for a video. Returns summary, key takeaways, and related concepts.",
    parameters: Type.Object({ videoId: Type.String({ description: "YouTube video ID" }) }),
    async execute(_, p) {
      try { return ok(await apiGet(`/wiki/sources/${p.videoId}`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "list_concepts",
    label: "List Concept Pages",
    description: "List all concept pages. Concept pages synthesize knowledge across multiple videos.",
    parameters: Type.Object({}),
    async execute() {
      try { return ok(await apiGet("/wiki/concepts")); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "read_concept",
    label: "Read Concept Page",
    description: "Read a concept page with summary, key takeaways, sources, and related concepts.",
    parameters: Type.Object({ slug: Type.String({ description: "Concept slug" }) }),
    async execute(_, p) {
      try { return ok(await apiGet(`/wiki/concepts/${p.slug}`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "list_topics",
    label: "List Topics",
    description: "List all topics. Returns approved and pending topics with item counts.",
    parameters: Type.Object({}),
    async execute() {
      try { return ok(await apiGet("/topics")); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "approve_topic",
    label: "Approve Topic",
    description: "Approve a proposed topic so it becomes active for organizing items and generating concept pages.",
    parameters: Type.Object({ topicId: Type.String({ description: "Topic ID to approve" }) }),
    async execute(_, p) {
      try { return ok(await apiPost(`/topics/${p.topicId}/approve`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "list_items",
    label: "List Items",
    description: "List ingested YouTube video items with title, channel, transcript status, and topic assignments.",
    parameters: Type.Object({
      limit: Type.Optional(Type.Number({ description: "Max items (default 50)", default: 50 })),
    }),
    async execute(_, p) {
      try { return ok(await apiGet(`/items?limit=${p.limit ?? 50}`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "fetch_sources",
    label: "Fetch Linked Sources",
    description: "Fetch content for pending linked sources (URLs from video descriptions).",
    parameters: Type.Object({
      limit: Type.Optional(Type.Number({ description: "Max sources (default 20)", default: 20 })),
    }),
    async execute(_, p) {
      try { return ok(await apiPost(`/linked-sources/fetch?limit=${p.limit ?? 20}`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "wiki_digest",
    label: "Run Digest",
    description: "Run a knowledge base digest. Synthesizes concept pages from source pages grouped by topic.",
    parameters: Type.Object({
      history: Type.Optional(Type.Boolean({ description: "Return past runs instead of triggering new one", default: false })),
    }),
    async execute(_, p) {
      try {
        if (p.history) return ok(await apiGet("/wiki/digest"));
        return ok(await apiPost("/wiki/digest"));
      } catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "read_transcript",
    label: "Read Transcript",
    description: "Read raw transcript for a YouTube video. Use internal item ID (UUID).",
    parameters: Type.Object({ itemId: Type.String({ description: "Internal item UUID" }) }),
    async execute(_, p) {
      try { return ok(await apiGet(`/items/${p.itemId}/transcript`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "write_source_page",
    label: "Create Source Page",
    description: "Generate a wiki source page skeleton for a video.",
    parameters: Type.Object({ videoId: Type.String({ description: "YouTube video ID" }) }),
    async execute(_, p) {
      try { return ok(await apiPost(`/wiki/sources/${p.videoId}/generate`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "update_source_page",
    label: "Update Source Page",
    description: "Fill content sections of an existing source page with summary, takeaways, and related concepts.",
    parameters: Type.Object({
      videoId: Type.String({ description: "YouTube video ID" }),
      summary: Type.String({ description: "2-3 paragraph summary" }),
      keyTakeaways: Type.Array(Type.String(), { description: "3-5 concrete takeaways" }),
      relatedConcepts: Type.Array(Type.String(), { description: "2-3 concept names" }),
    }),
    async execute(_, p) {
      try {
        return ok(await apiPut(`/wiki/sources/${p.videoId}`, {
          summary: p.summary,
          keyTakeaways: p.keyTakeaways,
          relatedConcepts: p.relatedConcepts,
        }));
      } catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });

  pi.registerTool({
    name: "propose_topics",
    label: "Propose Topics",
    description: "Propose topic labels for a video based on its content. Topics need approval.",
    parameters: Type.Object({ itemId: Type.String({ description: "Internal item UUID" }) }),
    async execute(_, p) {
      try { return ok(await apiPost(`/items/${p.itemId}/topics/propose`)); }
      catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
    },
  });
}
