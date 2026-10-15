import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { execSync, spawn, spawnSync, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const DIR = path.join(os.homedir(), ".pi", "agent", "headroom");
const SETTINGS = path.join(DIR, "settings.json");
const WORKER_FILE = path.join(DIR, "mem_worker.py");
const STATUS = "headroom";
const DUMP = path.join(DIR, "memories-dump.txt");

type Msg = any;
type Settings = {
  enabled?: boolean;
  baseUrl?: string;
  autoStart?: boolean;
  command?: string;
  proxyArgs?: string[];
  minContextTokens?: number;
  minMessageChars?: number;
  timeoutMs?: number;
  memory?: boolean;
  memoryInject?: boolean;
  memoryTopK?: number;
  python?: string;
  memoryDbPath?: string;
  userId?: string;
  /** Price of a prompt-cache-read token relative to fresh input (0..1).
   *  Compressed-away tokens are mostly stable history that would otherwise be
   *  cache reads, so raw savings overstate real value by ~1/ratio.
   *  Measured 0.186 on zai GLM ($0.26/M cacheRead vs $1.40/M input); 0.2 default. */
  cacheReadPriceRatio?: number;
};

type Config = Required<Settings>;
type Stats = { attempts: number; applied: number; tokensSaved: number; lastSaved: number; lastError?: string; last?: { tokensBefore: number; tokensAfter: number; tokensSaved: number; compressionRatio: number; transformsApplied: string[] } };
type MemHit = { id: string; content: string; scope: string; category?: string; similarity?: number };

const WORKER_PY = String.raw`
import sys, os, json, asyncio, warnings
warnings.filterwarnings("ignore")
os.environ.setdefault("TRANSFORMERS_VERBOSITY", "error")
os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")
db_path = sys.argv[1] if len(sys.argv) > 1 else "memory.db"
user_id = sys.argv[2] if len(sys.argv) > 2 else "pi"

async def main():
    from headroom.memory import HierarchicalMemory, MemoryConfig, EmbedderBackend, MemoryFilter, ScopeLevel
    cfg = MemoryConfig(db_path=db_path, embedder_backend=EmbedderBackend.ONNX)
    mem = await HierarchicalMemory.create(cfg)
    print(json.dumps({"ready": True}), flush=True)
    loop = asyncio.get_event_loop()
    while True:
        line = await loop.run_in_executor(None, sys.stdin.readline)
        if not line:
            break
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            op = req.get("op")
            cwd = req.get("cwd", "")
            if op == "save":
                scope = req.get("scope", "project")
                m = await mem.add(req["content"], user_id=user_id,
                                  agent_id=(None if scope == "user" else cwd),
                                  importance=float(req.get("importance", 0.5)),
                                  metadata={"scope": scope, "category": req.get("category", "fact"), "cwd": cwd})
                print(json.dumps({"ok": True, "id": getattr(m, "id", ""), "content": m.content, "scope": scope}), flush=True)
            elif op == "search":
                topk = int(req.get("topK", 5))
                hits = await mem.search(req["query"], user_id=user_id, top_k=max(topk * 3, 10),
                                        scope_levels=[ScopeLevel.USER, ScopeLevel.AGENT])
                out = []
                for h in hits:
                    aid = getattr(h.memory, "agent_id", None)
                    if aid not in (None, cwd):
                        continue
                    out.append({"id": getattr(h.memory, "id", ""), "content": h.memory.content,
                                "scope": "user" if aid is None else "project",
                                "similarity": round(float(h.similarity), 3)})
                    if len(out) >= topk:
                        break
                print(json.dumps({"ok": True, "hits": out}), flush=True)
            elif op == "list":
                want_all = bool(req.get("all"))
                ms = await mem.query(MemoryFilter(user_id=user_id, limit=1000))
                out = []
                for x in ms:
                    aid = getattr(x, "agent_id", None)
                    if not want_all and aid not in (None, cwd):
                        continue
                    md = getattr(x, "metadata", {}) or {}
                    out.append({"id": getattr(x, "id", ""), "content": x.content,
                                "scope": "user" if aid is None else "project",
                                "project": aid,
                                "category": md.get("category", "fact")})
                print(json.dumps({"ok": True, "hits": out if want_all else out[-100:]}), flush=True)
            elif op == "delete":
                ids = []
                if isinstance(req.get("id"), list):
                    ids.extend(str(x) for x in req["id"] if x)
                elif req.get("id"):
                    ids.append(str(req["id"]))
                if req.get("ids"):
                    ids.extend(str(x) for x in req["ids"] if x)
                project = req.get("project")
                had_project = project is not None and str(project).strip() != ""
                if had_project:
                    project = str(project).strip()
                    if project == "user":
                        with mem._store._get_conn() as conn:
                            rows = conn.execute("SELECT id FROM memories WHERE agent_id IS NULL").fetchall()
                    else:
                        with mem._store._get_conn() as conn:
                            rows = conn.execute("SELECT id FROM memories WHERE agent_id = ?", (os.path.expanduser(project),)).fetchall()
                    ids.extend(r[0] for r in rows)
                ids = list(dict.fromkeys(ids))
                if not ids and not had_project:
                    print(json.dumps({"ok": False, "error": "nothing to delete: provide id, ids, or project"}), flush=True)
                else:
                    deleted, missing = 0, []
                    for i in ids:
                        if await mem.delete(i):
                            deleted += 1
                        else:
                            missing.append(i)
                    out = {"ok": True, "deleted": deleted, "requested": len(ids)}
                    if missing:
                        out["not_found"] = missing
                    print(json.dumps(out), flush=True)
            elif op == "repath" and req.get("id"):
                # single-memory rescope: {"op":"repath","id":<uuid>,"new":"user"|"/abs/path"}
                mid = str(req["id"])
                raw_new = str(req.get("new", "user")).strip()
                to_user = raw_new == "user"
                new = None if to_user else os.path.expanduser(raw_new)
                if to_user or (new and os.path.isabs(new)):
                    with mem._store._get_conn() as conn:
                        if to_user:
                            cur = conn.execute(
                                "UPDATE memories SET agent_id = NULL, "
                                "metadata = json_set(json_set(metadata, '$.scope', 'user'), '$.cwd', '') WHERE id = ?",
                                (mid,))
                        else:
                            cur = conn.execute(
                                "UPDATE memories SET agent_id = ?, "
                                "metadata = json_set(json_set(metadata, '$.scope', 'project'), '$.cwd', ?) WHERE id = ?",
                                (new, new, mid))
                        conn.commit()
                        n = cur.rowcount
                    cache = getattr(mem, "_cache", None)
                    if cache is not None:
                        await cache.clear()
                    print(json.dumps({"ok": True, "moved": n, "single": True, "id": mid,
                                      "label": "%s -> %s" % (mid, raw_new)}), flush=True)
                else:
                    print(json.dumps({"ok": False, "error": "new must be 'user' or an absolute path"}), flush=True)
            elif op == "repath":
                # ponytail: reuses the store's own sqlite conn + reaches into _store/_cache privates;
                # headroom has no public repath/agent_id update. vector/text indexes key on memory_id,
                # not agent_id, so a single UPDATE on the memories table is sufficient.
                # new == "user" moves to USER scope (agent_id NULL) instead of repathing.
                old = os.path.expanduser(req["old"])
                to_user = str(req.get("new", "")).strip() == "user"
                new = None if to_user else os.path.expanduser(req.get("new", ""))
                if not old or (not to_user and (not new or old == new)):
                    print(json.dumps({"ok": False, "error": "old required; new must be a path or 'user'"}), flush=True)
                else:
                    with mem._store._get_conn() as conn:
                        if to_user:
                            cur = conn.execute(
                                "UPDATE memories SET agent_id = NULL, "
                                "metadata = json_set(json_set(metadata, '$.scope', 'user'), '$.cwd', '') WHERE agent_id = ?",
                                (old,))
                            label = "%s -> user" % old
                        else:
                            cur = conn.execute(
                                "UPDATE memories SET agent_id = ?, metadata = json_set(metadata, '$.cwd', ?) WHERE agent_id = ?",
                                (new, new, old))
                            label = "%s -> %s" % (old, new)
                        conn.commit()
                        n = cur.rowcount
                    cache = getattr(mem, "_cache", None)
                    if cache is not None:
                        await cache.clear()
                    print(json.dumps({"ok": True, "moved": n, "to_user": to_user, "label": label}), flush=True)
            else:
                print(json.dumps({"ok": False, "error": "unknown op: %s" % op}), flush=True)
        except Exception as e:
            print(json.dumps({"ok": False, "error": "%s: %s" % (type(e).__name__, e)}), flush=True)

try:
    asyncio.run(main())
except Exception as e:
    try:
        print(json.dumps({"ready": False, "error": "%s: %s" % (type(e).__name__, e)}), flush=True)
    except Exception:
        pass
`;

export default function headroom(pi: ExtensionAPI) {
  const config = loadConfig();
  const stats: Stats = { attempts: 0, applied: 0, tokensSaved: 0, lastSaved: 0 };
  let enabled = config.enabled;
  let proxyOnline: boolean | null = null;
  let starting = false;

  // Memory worker state (session-scoped)
  let proc: ChildProcess | null = null;
  let workerPromise: Promise<boolean> | null = null;
  let workerAlive = false;
  let workerErr: string | undefined;
  let outBuf = "";
  let pending: ((v: any) => void) | null = null;
  let readyDone: ((v: { ready: boolean; error?: string }) => void) | null = null;
  let memBusy: Promise<any> = Promise.resolve();

  const refresh = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;
    const theme = (ctx.ui as any).theme;
    const paint = (c: "dim" | "warning" | "success", t: string) =>
      theme && typeof theme.fg === "function" ? theme.fg(c, t) : t;
    const mem = config.memory ? paint("dim", " mem") : "";
    let line: string;
    if (!enabled) line = paint("dim", "○ Headroom off");
    else if (starting) line = paint("dim", "⏳ Headroom starting");
    else if (proxyOnline === false) line = paint("dim", "○ Headroom offline");
    else if (!proxyOnline) line = paint("dim", `○ Headroom idle`) + mem;
    else if (stats.last) {
      const pct = Math.round((1 - stats.last.compressionRatio) * 100);
      line = paint("success", "✓") + paint("dim", ` Headroom -${pct}%`) + mem;
    } else line = paint("success", "✓") + paint("dim", ` Headroom`) + mem;
    ctx.ui.setStatus(STATUS, line);
  };

  pi.on("session_start", async (_e, ctx) => {
    fs.mkdirSync(DIR, { recursive: true });
    refresh(ctx);
    if (enabled) void ensureProxy(ctx);
    if (config.memory) void startWorker(); // warm the ONNX model in the background
  });

  pi.on("session_shutdown", () => {
    try { proc?.kill(); } catch {}
    proc = null;
    workerPromise = null;
    workerAlive = false;
    pending = null;
    readyDone = null;
    outBuf = "";
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (!config.memory || !config.memoryInject) return;
    let hits: MemHit[] = [];
    try {
      const res = await mem({ op: "search", query: event.prompt, topK: config.memoryTopK, cwd: ctx.cwd });
      hits = res?.hits ?? [];
    } catch {
      return; // worker unavailable — skip injection silently
    }
    if (!hits.length) return;
    return { systemPrompt: `${event.systemPrompt}\n\n## Persistent memory\n${hits.map((h) => `- ${h.content}`).join("\n")}` };
  });

  pi.on("context", async (event, ctx) => {
    if (!enabled) return;
    const usage = ctx.getContextUsage();
    if (usage?.tokens != null && usage.tokens < config.minContextTokens) return;

    const payload = buildPayload(event.messages, config.minMessageChars);
    if (!payload.candidates) return;
    if (!(await ensureProxy(ctx))) return;

    stats.attempts++;
    try {
      const result = await compress(config, payload.messages, ctx.model?.id, ctx.signal);
      const compressed = result.messages ?? result.data?.messages;
      if (!Array.isArray(compressed)) return;
      const applied = applyCompression(event.messages, payload.mappings, compressed);
      if (!applied.ok) {
        stats.lastError = applied.reason;
        refresh(ctx);
        return;
      }
      const saved = Number(result.tokens_saved ?? result.tokensSaved ?? result.data?.tokens_saved ?? 0);
      const ratio = Number(result.compression_ratio ?? result.compressionRatio ?? result.data?.compression_ratio ?? 0);
      const tb = Number(result.tokens_before ?? result.tokensBefore ?? result.data?.tokens_before ?? 0);
      const ta = Number(result.tokens_after ?? result.tokensAfter ?? result.data?.tokens_after ?? 0);
      const transforms = (result.transforms_applied ?? result.transformsApplied ?? result.data?.transforms_applied ?? []) as string[];
      stats.applied++;
      stats.lastSaved = saved;
      stats.tokensSaved += saved;
      stats.lastError = undefined;
      stats.last = { tokensBefore: tb, tokensAfter: ta, tokensSaved: saved, compressionRatio: ratio, transformsApplied: transforms };
      refresh(ctx);
      return { messages: applied.messages };
    } catch (err) {
      stats.lastError = err instanceof Error ? err.message : String(err);
      if (!isAbortOrTimeoutError(err)) proxyOnline = false; // timeout ≠ proxy dead
      refresh(ctx);
    }
  });

  pi.registerCommand("headroom", {
    description: "Headroom status/control: /headroom [on|off|health|stats|memory|dump|repath <old> <new|user>|remember <text>|forget <id>]",
    getArgumentCompletions: (prefix: string) => {
      const subs = ["on", "off", "health", "stats", "status", "memory", "remember", "forget", "dump", "repath"];
      const p = prefix.trim().toLowerCase();
      const items = subs.filter((s) => s.startsWith(p)).map((s) => ({ value: s, label: s }));
      return items.length ? items : null;
    },
    handler: async (args, ctx) => {
      const [cmd, ...rest] = args.trim().split(/\s+/);
      if (cmd === "on") { enabled = true; await ensureProxy(ctx); refresh(ctx); ctx.ui.notify("Headroom enabled", "info"); return; }
      if (cmd === "off") { enabled = false; refresh(ctx); ctx.ui.notify("Headroom disabled", "info"); return; }
      if (cmd === "health") { await ensureProxy(ctx, true); ctx.ui.notify(proxyOnline ? `Headroom online: ${config.baseUrl}` : `Headroom offline: ${config.baseUrl}`, proxyOnline ? "info" : "warning"); return; }
      if (cmd === "stats") { ctx.ui.notify(await proxyStats(config), "info"); return; }
      if (cmd === "memory") {
        try { const res = await mem({ op: "list", cwd: ctx.cwd }); const hits: MemHit[] = res?.hits ?? []; ctx.ui.notify(hits.length ? hits.map((h) => `${h.id} [${h.scope}/${h.category}] ${h.content}`).join("\n") : "No memories.", "info"); }
        catch (e) { ctx.ui.notify(`Memory unavailable: ${e instanceof Error ? e.message : String(e)}`, "warning"); }
        return;
      }
      if (cmd === "remember") {
        const text = rest.join(" ").trim();
        if (!text) { ctx.ui.notify("Usage: /headroom remember <text>", "warning"); return; }
        try { const m = await mem({ op: "save", content: text, scope: "user", category: "fact", cwd: ctx.cwd }); ctx.ui.notify(m?.ok ? `Remembered: ${text}` : `Failed: ${m?.error}`, m?.ok ? "info" : "warning"); }
        catch (e) { ctx.ui.notify(`Memory unavailable: ${e instanceof Error ? e.message : String(e)}`, "warning"); }
        return;
      }
      if (cmd === "dump") {
        try {
          const res = await mem({ op: "list", all: true, cwd: ctx.cwd });
          const hits: any[] = res?.hits ?? [];
          if (!hits.length) { ctx.ui.notify("No memories.", "info"); return; }
          const body = hits.map((h) => `${h.id}  [${h.scope}${h.project ? `|${h.project}` : ""}]  ${h.category}  ${h.content}`).join("\n");
          fs.writeFileSync(DUMP, `Headroom memories dump (${hits.length})\n\n${body}\n`);
          ctx.ui.notify(`Dumped ${hits.length} memories → ${DUMP}`, "info");
        } catch (e) { ctx.ui.notify(`Memory unavailable: ${e instanceof Error ? e.message : String(e)}`, "warning"); }
        return;
      }
      if (cmd === "forget") {
        const parts = rest.filter(Boolean);
        const isUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
        const usage = "Usage: /headroom forget <id> [id...] | --project <path|user>";
        try {
          if (parts[0] === "--project" && parts[1]) {
            const r = await mem({ op: "delete", project: parts[1], cwd: ctx.cwd });
            ctx.ui.notify(r?.ok ? `Deleted ${r.deleted} memories (project ${parts[1]})` : `Delete failed: ${r?.error}`, r?.ok ? "info" : "warning");
          } else if (parts.length && parts.every(isUuid)) {
            const r = await mem({ op: "delete", id: parts, cwd: ctx.cwd });
            const nf = Array.isArray(r?.not_found) && r.not_found.length ? ` (not found: ${r.not_found.join(", ")})` : "";
            ctx.ui.notify(r?.ok ? `Deleted ${r.deleted}/${r.requested}.${nf}` : `Delete failed: ${r?.error}`, r?.ok ? "info" : "warning");
          } else if (parts.length === 1 && (parts[0] === "user" || parts[0].startsWith("/") || parts[0].startsWith("~"))) {
            const r = await mem({ op: "delete", project: parts[0], cwd: ctx.cwd });
            ctx.ui.notify(r?.ok ? `Deleted ${r.deleted} memories (project ${parts[0]})` : `Delete failed: ${r?.error}`, r?.ok ? "info" : "warning");
          } else {
            ctx.ui.notify(usage, "warning");
          }
        } catch (e) {
          ctx.ui.notify(`Memory unavailable: ${e instanceof Error ? e.message : String(e)}`, "warning");
        }
        return;
      }
      if (cmd === "repath") {
        const [oldP, newP] = rest;
        if (!oldP || !newP) { ctx.ui.notify("Usage: /headroom repath <old-path|memory-id> <new-path|user>", "warning"); return; }
        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(oldP);
        try { const r = await mem({ op: "repath", ...(isUuid ? { id: oldP } : { old: oldP }), new: newP, cwd: ctx.cwd }); if (!r?.ok) { ctx.ui.notify(`Repath failed: ${r?.error}`, "warning"); return; } ctx.ui.notify(`Repathed ${r.moved} memor${r.moved === 1 ? "y" : "ies"}: ${r.label}`, "info"); }
        catch (e) { ctx.ui.notify(`Memory unavailable: ${e instanceof Error ? e.message : String(e)}`, "warning"); }
        return;
      }
      ctx.ui.notify(renderStatus(config, enabled, proxyOnline, stats), "info");
    },
  });

  pi.registerTool({
    name: "headroom_memory_save",
    label: "Save Memory",
    description: "Persist a durable fact for future Pi sessions via Headroom's HierarchicalMemory. HIGH BAR: store ONLY facts that exist nowhere in the repo — never status, progress, or decisions already documented in docs/ADRs/issues/code.",
    promptSnippet: "Save ONLY durable facts that exist nowhere else in the repo — never status/progress or duplicated decisions",
    promptGuidelines: [
      "HIGH BAR — before saving, ask: 'Can this be re-derived from git log, the issue tracker, docs/adr, or the code itself in under a minute?' If yes, do NOT save; that is where it belongs.",
      "NEVER store status or progress: commit SHAs, cherry-pick order, 'X shipped/closed', test counts, 'main pushed/local', roadmap position, or what is on the frontier. git log + the issue tracker already hold all of this.",
      "NEVER store a decision that already has a canonical home — an ADR, docs/*.md, CONTEXT.md, AGENTS.md, code comments, or a GitHub issue body. A memory is not a second copy of documentation.",
      "KEEP what qualifies: cross-cutting principles and conventions, hard-won API quirks or gotchas, operational learnings, and explicit user preferences — knowledge that lives in someone's head and would be lost otherwise.",
      "COMPACT and SELF-CONTAINED: one fact per save, a few sentences max, no implementation transcripts or commit dumps. If a verbose event has one durable nugget, extract just the nugget.",
      "SEARCH FIRST: run headroom_memory_search before saving; if a similar or superseding fact exists, delete it then save the replacement — never append a near-duplicate.",
      "WORKTREES/CLONES: project scope keys on cwd. Linked git worktrees are auto-resolved to their main repo. If cwd is a SEPARATE CLONE of a repo you keep elsewhere (e.g. task clones like ~/proj.some-task), durable project facts belong under the canonical checkout: save, then run `/headroom repath <cwd> <canonical-path>` — or use scope=user for genuinely cross-project facts.",
    ],
    parameters: {
      type: "object",
      properties: {
        content: { type: "string", description: "The fact to remember, concise and self-contained" },
        scope: { type: "string", description: "user or project", default: "project" },
        category: { type: "string", description: "preference, fact, context, decision, insight", default: "fact" },
      },
      required: ["content"],
    },
    async execute(_id, p, _signal, _update, ctx) {
      try {
        const m = await mem({ op: "save", content: p.content, scope: p.scope ?? "project", category: p.category ?? "fact", cwd: ctx.cwd });
        if (!m?.ok) return { content: [{ type: "text", text: `Save failed: ${m?.error}` }], details: { ok: false } };
        return { content: [{ type: "text", text: `Remembered (${m.scope}): ${m.content}` }], details: { ok: true, id: m.id, scope: m.scope } };
      } catch (e) {
        return { content: [{ type: "text", text: `Memory unavailable: ${e instanceof Error ? e.message : String(e)}` }], details: { ok: false } };
      }
    },
  });

  pi.registerTool({
    name: "headroom_memory_search",
    label: "Search Memory",
    description: "Semantic search over persistent Headroom memory (user + current project scopes).",
    promptSnippet: "Search persistent memory before re-discovering known project/user facts, and before saving to avoid duplicates",
    promptGuidelines: ["Use headroom_memory_search before expensive rediscovery when prior project/user knowledge may answer the question, and before every save to avoid storing a duplicate of an existing or superseding fact."],
    parameters: {
      type: "object",
      properties: { query: { type: "string" }, topK: { type: "number", default: 5 } },
      required: ["query"],
    },
    async execute(_id, p, _signal, _update, ctx) {
      try {
        const res = await mem({ op: "search", query: p.query, topK: Math.max(1, Math.min(20, p.topK ?? 5)), cwd: ctx.cwd });
        const hits: MemHit[] = res?.hits ?? [];
        return { content: [{ type: "text", text: hits.length ? hits.map((h) => `[${h.scope}] ${h.id}: ${h.content}`).join("\n") : "No memories found." }], details: { hits } };
      } catch (e) {
        return { content: [{ type: "text", text: `Memory unavailable: ${e instanceof Error ? e.message : String(e)}` }], details: { ok: false } };
      }
    },
  });

  pi.registerTool({
    name: "headroom_memory_delete",
    label: "Delete Memory",
    description: "Delete persistent Headroom memories. Accepts a single ID, an ARRAY of IDs, or a project path/'user' to delete ALL memories in that scope (e.g. wiping a POC or disposable project) without searching for IDs first. To rescope instead of deleting, use /headroom repath <id|path> user|<path>.",
    promptSnippet: "Delete obsolete/wrong persistent memories by ID(s) or by project scope when asked",
    promptGuidelines: ["Use headroom_memory_delete only when the user explicitly asks to forget/remove memories, or a memory is confirmed stale/contradictory and the new authoritative one is already saved. Confirm IDs/scopes first via headroom_memory_search/list; never delete speculatively.", "BATCH: id accepts an array of IDs. PROJECT WIPE: project accepts a project path (all its memories) or 'user' (all user-scope memories) — use when retiring/deleting a POC or disposable project. To move memories instead of deleting (e.g. project graduating to user scope), use /headroom repath <project-path> user, or /headroom repath <memory-id> user for a single memory."],
    parameters: {
      type: "object",
      properties: {
        id: { description: "Memory ID or array of memory IDs (from search/list)", anyOf: [{ type: "string" }, { type: "array", items: { type: "string" } }] },
        project: { type: "string", description: "Project path to delete ALL its memories, or 'user' for all user-scope memories. Alternative to id." },
      },
    },
    async execute(_id, p, _signal, _update, ctx) {
      try {
        let req: any;
        if (p.project && String(p.project).trim()) req = { op: "delete", project: String(p.project).trim() };
        else if (typeof p.id === "string" && p.id.trim()) req = { op: "delete", id: p.id.trim() };
        else if (Array.isArray(p.id) && p.id.length) req = { op: "delete", id: p.id };
        else return { content: [{ type: "text", text: "Provide id (string or array) or project (path or 'user')." }], details: { ok: false } };
        const r = await mem({ ...req, cwd: ctx.cwd });
        if (!r?.ok) return { content: [{ type: "text", text: `Delete failed: ${r?.error}` }], details: { ok: false } };
        const nf = Array.isArray(r.not_found) && r.not_found.length ? ` (not found: ${r.not_found.join(", ")})` : "";
        const scope = req.project ? `project '${req.project}'` : `${r.requested} id(s)`;
        return { content: [{ type: "text", text: `Deleted ${r.deleted} of ${scope}.${nf}` }], details: { ok: true, deleted: r.deleted, requested: r.requested, not_found: r.not_found ?? [] } };
      } catch (e) {
        return { content: [{ type: "text", text: `Memory unavailable: ${e instanceof Error ? e.message : String(e)}` }], details: { ok: false } };
      }
    },
  });

  // ── Proxy lifecycle ──────────────────────────────────────────────
  async function ensureProxy(ctx: ExtensionContext, force = false): Promise<boolean> {
    if (!force && proxyOnline) return true;
    proxyOnline = await health(config);
    if (proxyOnline || !config.autoStart || starting) { refresh(ctx); return !!proxyOnline; }
    starting = true; refresh(ctx);
    try {
      const child = spawn(config.command, config.proxyArgs, { detached: true, stdio: "ignore", env: { ...process.env, HEADROOM_TELEMETRY: "off" } });
      child.on("error", (err) => { stats.lastError = err instanceof Error ? err.message : String(err); }); // missing binary emits async error → crash without this
      child.unref();
      for (const ms of [300, 500, 800, 1200, 2000]) {
        await sleep(ms);
        if (await health(config)) { proxyOnline = true; break; }
      }
    } catch (err) {
      stats.lastError = err instanceof Error ? err.message : String(err);
    }
    starting = false; refresh(ctx);
    return !!proxyOnline;
  }

  // ── Memory worker (persistent ONNX, JSON-lines) ──────────────────
  function startWorker(): Promise<boolean> {
    if (workerPromise) return workerPromise;
    workerPromise = (async () => {
      fs.mkdirSync(DIR, { recursive: true });
      fs.writeFileSync(WORKER_FILE, WORKER_PY);
      const py = config.python || resolvePython(config.command);
      proc = spawn(py, [WORKER_FILE, config.memoryDbPath, config.userId], {
        stdio: ["pipe", "pipe", "ignore"],
        env: { ...process.env },
      });
      const onDead = (reason: string) => {
        workerAlive = false; workerErr = reason;
        workerPromise = null;
        if (readyDone) { const d = readyDone; readyDone = null; d({ ready: false, error: reason }); }
        else if (pending) { const r = pending; pending = null; r({ ok: false, error: reason }); }
      };
      proc.stdout?.setEncoding("utf8");
      proc.stdout?.on("data", (chunk: string) => {
        outBuf += chunk;
        let idx: number;
        while ((idx = outBuf.indexOf("\n")) >= 0) {
          const line = outBuf.slice(0, idx); outBuf = outBuf.slice(idx + 1);
          if (!line.trim()) continue;
          let parsed: any;
          try { parsed = JSON.parse(line); } catch { continue; }
          if ("ready" in parsed && readyDone) { const d = readyDone; readyDone = null; d(parsed); }
          else if (pending) { const r = pending; pending = null; r(parsed); }
        }
      });
      proc.on("exit", () => onDead("worker exited"));
      proc.on("error", (e) => onDead(String(e)));
      const ready = await new Promise<{ ready: boolean; error?: string }>((res) => { readyDone = res; });
      workerAlive = ready.ready;
      workerErr = ready.error;
      return ready.ready;
    })();
    return workerPromise;
  }

  function mem(req: any): Promise<any> {
    const run = async () => {
      if (!(await startWorker())) throw new Error(workerErr || "headroom memory worker unavailable");
      if (typeof req.cwd === "string" && req.cwd) req = { ...req, cwd: canonicalProjectDir(req.cwd) };
      return new Promise<any>((resolve) => {
        pending = resolve;
        proc?.stdin?.write(JSON.stringify(req) + "\n");
      });
    };
    memBusy = memBusy.then(run, run); // serialize: one outstanding request at a time
    return memBusy;
  }
}

function loadConfig(): Config {
  const s = readJson<Settings>(SETTINGS, {});
  return {
    enabled: s.enabled ?? true,
    baseUrl: (s.baseUrl ?? "http://127.0.0.1:8787").replace(/\/+$/, ""),
    autoStart: s.autoStart ?? true,
    command: s.command ?? "headroom",
    proxyArgs: s.proxyArgs ?? ["proxy", "--host", "127.0.0.1", "--port", "8787", "--mode", "token", "--no-cache"],
    minContextTokens: s.minContextTokens ?? 20_000,
    minMessageChars: s.minMessageChars ?? 2_000,
    timeoutMs: s.timeoutMs ?? 30_000,
    memory: s.memory ?? true,
    memoryInject: s.memoryInject ?? true,
    memoryTopK: s.memoryTopK ?? 5,
    python: s.python ?? "",
    memoryDbPath: s.memoryDbPath ?? path.join(DIR, "memory.db"),
    userId: s.userId ?? "pi",
    cacheReadPriceRatio: Math.min(1, Math.max(0, s.cacheReadPriceRatio ?? 0.2)),
  };
}

function resolvePython(command: string): string {
  try {
    const resolved = execSync(`command -v ${command}`, { encoding: "utf8", shell: true }).trim();
    const first = (fs.readFileSync(resolved, "utf8").split("\n")[0] || "").trim();
    if (first.startsWith("#!")) {
      const interp = first.slice(2).trim().split(/\s+/)[0];
      if (interp && !interp.endsWith("/env")) return interp;
    }
  } catch {}
  return "python3";
}

// Memories are scoped by cwd (agent_id = project dir). Linked git worktrees
// (.git is a file pointing at <main>/.git/worktrees/<name>) are resolved to
// their MAIN worktree so facts saved in a worktree are visible in the canonical
// repo and vice versa. Full clones of the same repo (separate .git dirs) are
// NOT merged automatically — use `/headroom repath <clone> <canonical>` for those.
const canonCache = new Map<string, string>();
function canonicalProjectDir(cwd: string): string {
  if (!cwd) return cwd;
  const cached = canonCache.get(cwd);
  if (cached) return cached;
  let out = cwd;
  try {
    const rp = (flag: string) => spawnSync("git", ["-C", cwd, "rev-parse", "--path-format=absolute", flag], { encoding: "utf8" });
    const gitDir = rp("--git-dir");
    const commonDir = rp("--git-common-dir");
    if (gitDir.status === 0 && commonDir.status === 0) {
      const g = path.resolve(gitDir.stdout.trim());
      const c = path.resolve(commonDir.stdout.trim());
      if (g !== c && fs.existsSync(c)) {
        const main = path.dirname(c);
        if (main && main !== cwd && fs.existsSync(main)) out = main;
      }
    }
  } catch {}
  canonCache.set(cwd, out);
  return out;
}

async function health(c: Config): Promise<boolean> {
  try { const r = await fetch(`${c.baseUrl}/health`, { signal: AbortSignal.timeout(1500) }); return r.ok; } catch { return false; }
}

async function compress(c: Config, messages: any[], model?: string, signal?: AbortSignal): Promise<any> {
  const signal2 = signal ?? AbortSignal.timeout(c.timeoutMs);
  const r = await fetch(`${c.baseUrl}/v1/compress`, { method: "POST", headers: { "content-type": "application/json", "x-headroom-stack": "pi-local-extension" }, body: JSON.stringify({ messages, model }), signal: signal2 });
  if (!r.ok) throw new Error(`Headroom ${r.status}: ${await r.text()}`);
  return r.json();
}

async function proxyStats(c: Config): Promise<string> {
  try { const r = await fetch(`${c.baseUrl}/stats`, { signal: AbortSignal.timeout(2000) }); return JSON.stringify(await r.json(), null, 2).slice(0, 4000); } catch (e) { return `Could not read stats: ${e instanceof Error ? e.message : String(e)}`; }
}

function buildPayload(messages: Msg[], minChars: number) {
  const mappings: any[] = [];
  let candidates = 0;
  messages.forEach((m, sourceIndex) => {
    const msg = convert(m);
    if (!msg) return;
    const text = textOf(msg);
    const apply = m.role === "toolResult" && text.length >= minChars;
    if (apply) candidates++;
    mappings.push({ sourceIndex, msg, text, apply });
  });
  return { messages: mappings.map((m) => m.msg), mappings, candidates };
}

function convert(m: Msg) {
  if (m.role === "user") return { role: "user", content: contentText(m.content) };
  if (m.role === "assistant") {
    const parts = Array.isArray(m.content) ? m.content : [];
    const content = parts.filter((p) => p?.type === "text").map((p) => p.text).join("") || null;
    const calls = parts.filter((p) => p?.type === "toolCall").map((p) => ({ id: p.id, type: "function", function: { name: p.name, arguments: JSON.stringify(p.arguments ?? {}) } }));
    return content || calls.length ? { role: "assistant", content, ...(calls.length ? { tool_calls: calls } : {}) } : undefined;
  }
  if (m.role === "toolResult" && m.toolCallId) return { role: "tool", tool_call_id: m.toolCallId, content: contentText(m.content) };
}

function applyCompression(original: Msg[], mappings: any[], compressed: any[]) {
  if (compressed.length !== mappings.length) return { ok: false as const, reason: "message-count-changed" };
  const next = structuredClone(original);
  let applied = 0;
  for (let i = 0; i < mappings.length; i++) {
    const a = mappings[i], b = compressed[i];
    if (a.msg.role !== b.role) return { ok: false as const, reason: "role-changed" };
    if (a.msg.role === "tool" && a.msg.tool_call_id !== b.tool_call_id) return { ok: false as const, reason: "tool-id-changed" };
    if (a.msg.role === "assistant") {
      const ai = (a.msg.tool_calls ?? []).map((c: any) => c.id).join("\n");
      const bi = (b.tool_calls ?? []).map((c: any) => c.id).join("\n");
      if (ai !== bi) return { ok: false as const, reason: "assistant-tool-calls-changed" }; // guard double-emit
    }
    const text = textOf(b);
    if (text === a.text) continue;
    if (!a.apply) return { ok: false as const, reason: "non-tool-result-changed" };
    setContent(next[a.sourceIndex], text);
    applied++;
  }
  return applied ? { ok: true as const, messages: next } : { ok: false as const, reason: "nothing-applied" };
}

function contentText(c: any): string {
  if (typeof c === "string") return c;
  if (!Array.isArray(c)) return "";
  return c.filter((p) => p?.type === "text").map((p) => p.text).join("\n");
}
function textOf(m: any): string { return typeof m.content === "string" ? m.content : contentText(m.content); }
function setContent(m: Msg, text: string) { m.content = Array.isArray(m.content) ? [{ type: "text", text }, ...m.content.filter((p: any) => p?.type === "image")] : text; }
function isAbortOrTimeoutError(e: unknown): boolean {
  if (!e || typeof e !== "object") return false;
  const c = e as { name?: string; message?: string; cause?: unknown };
  if (c.name === "TimeoutError" || c.name === "AbortError") return true;
  if (typeof c.message === "string" && /aborted due to timeout|operation was aborted/i.test(c.message)) return true;
  return c.cause !== undefined && c.cause !== e && isAbortOrTimeoutError(c.cause);
}
function sleep(ms: number) { return new Promise((r) => setTimeout(r, ms)); }
function fmtCompact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
  return String(n);
}
function renderStatus(c: Config, enabled: boolean, online: boolean | null, s: Stats) {
  const eff = Math.round(s.tokensSaved * c.cacheReadPriceRatio);
  const lines = [
    "Headroom",
    `  enabled: ${enabled}`,
    `  proxy: ${c.baseUrl} (${online ? "online" : online === false ? "offline" : "unknown"})`,
    `  memory: ${c.memory ? "on" : "off"}`,
    `  thresholds: context >= ${c.minContextTokens.toLocaleString()} tokens, toolResult >= ${c.minMessageChars.toLocaleString()} chars`,
    `  compression: ${s.applied}/${s.attempts} applied · raw ${fmtCompact(s.tokensSaved)} tokens not sent (local-tokenizer estimate, summed per request)`,
    `  est. effective: ~${fmtCompact(eff)} tokens at real value — compressed tokens are mostly stable history that would bill as cache reads (~${Math.round(c.cacheReadPriceRatio * 100)}% of input price; measured 19% on zai GLM. Tune via cacheReadPriceRatio in settings.json)`,
  ];
  if (s.last) {
    const pct = Math.round((1 - s.last.compressionRatio) * 100);
    lines.push(`  last: ${s.last.tokensBefore.toLocaleString()} → ${s.last.tokensAfter.toLocaleString()} tokens (-${pct}%)`, `  transforms: ${s.last.transformsApplied.join(", ") || "none"}`);
  }
  if (s.lastError) lines.push("", `  last error: ${s.lastError}`);
  return lines.join("\n");
}
function readJson<T>(file: string, fallback: T): T { try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch { return fallback; } }
