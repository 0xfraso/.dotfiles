#!/usr/bin/env node
// Memory harvest helper for the headroom extension's harvest-memories skill.
// Mechanical work only: enumerate projects, reconstruct clean session
// transcripts, and manage per-project candidate JSONLs. All significance
// judgment is the agent's job — this script never decides what's memorable.
//
// Usage:
//   node harvest.mjs projects [N]            list session-project dirs (pass-1 source list)
//   node harvest.mjs gather <slug>           reconstruct reviewable transcripts -> work/<slug>.jsonl
//   node harvest.mjs append <slug>           append NDJSON candidates from stdin (id + dedup)
//   node harvest.mjs show <slug>             pretty-print a project's candidates
//   node harvest.mjs review                  list projects that have candidates (pass-2 work list)
//   node harvest.mjs next [N=20]             next N undecided candidates across ALL projects (pass-2 batch)
//   node harvest.mjs mark <id> [<id>...]     mark ids decided (stored or skipped) so they don't resurface
//   node harvest.mjs decided                 count/list decided ids
//   node harvest.mjs reset                   clear the decided ledger
//
// Candidate JSONL line: {id, content, category, scope, source, ts, slug, cwd}
// Decided ledger (append-only): HARVEST/decided.txt, one candidate id per line.
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import * as crypto from "node:crypto";
import * as readline from "node:readline";

const SESSIONS = path.join(os.homedir(), ".pi", "agent", "sessions");
const HARVEST = path.join(os.homedir(), ".pi", "agent", "headroom", "harvest");
const WORK = path.join(HARVEST, "work");
const DECIDED = path.join(HARVEST, "decided.txt");

const [cmd, ...rest] = process.argv.slice(2);

const main = async () => {
  switch (cmd) {
    case "projects": return projects(parseInt(rest[0] || "0", 10));
    case "gather": return gather(rest[0]);
    case "append": return append(rest[0]);
    case "show": return show(rest[0]);
    case "review": return review();
    case "next": return next(parseInt(rest[0] || "20", 10));
    case "mark": return mark(rest);
    case "decided": return decided();
    case "reset": return reset();
    default:
      console.error("commands: projects | gather <slug> | append <slug> | show <slug> | review | next [N] | mark <id...> | decided | reset");
      process.exit(1);
  }
};

// ── helpers ──────────────────────────────────────────────────────────
const ensure = (d) => fs.mkdirSync(d, { recursive: true });
const candFile = (slug) => path.join(HARVEST, `${slug}.jsonl`);
const workFile = (slug) => path.join(WORK, `${slug}.jsonl`);
const listSessions = (slug) => {
  const dir = path.join(SESSIONS, slug);
  return fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith(".jsonl")).sort() : [];
};
const firstLineCwd = (file) => new Promise((res) => {
  let done = false;
  let rl;
  try {
    rl = readline.createInterface({ input: fs.createReadStream(file, { encoding: "utf8" }), crlfDelay: Infinity });
  } catch { res(null); return; }
  const finish = (v) => { if (done) return; done = true; try { rl.close(); } catch {} res(v); };
  rl.once("line", (l) => { try { finish((JSON.parse(l) || {}).cwd || null); } catch { finish(null); } });
  rl.once("close", () => finish(null));
});
const cap = (s, n) => (s && s.length > n ? s.slice(0, n) + ` …[+${s.length - n}b]` : s || "");

// Pull readable text out of a message.content (string | parts[]).
function textOf(content, { toolSnippet = false, role = "" } = {}) {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  const out = [];
  for (const p of content) {
    if (!p || typeof p !== "object") continue;
    if (p.type === "text") out.push(p.text);
    else if (p.type === "thinking") { /* skip: noise for memory harvesting */ }
    else if (p.type === "toolCall") out.push(`→ ${p.name}(${briefArgs(p.input ?? p.arguments)})`);
    else if (p.type === "toolResult" && toolSnippet) out.push(`tool:${cap(textOf(p.content), 200)}`);
  }
  return out.filter(Boolean).join("\n");
}
const briefArgs = (a) => {
  if (!a) return "";
  try {
    const o = typeof a === "string" ? JSON.parse(a) : a;
    const keys = Object.keys(o);
    if (!keys.length) return "";
    return cap(keys.map((k) => `${k}=${JSON.stringify(o[k]).slice(0, 40)}`).join(", "), 120);
  } catch { return cap(String(a), 120); }
};

// ── commands ─────────────────────────────────────────────────────────
async function projects(limit = 0) {
  const dirs = fs.existsSync(SESSIONS) ? fs.readdirSync(SESSIONS).filter((d) => fs.statSync(path.join(SESSIONS, d)).isDirectory()).sort() : [];
  const rows = [];
  for (const slug of dirs) {
    const files = listSessions(slug);
    if (!files.length) continue;
    const cwd = await firstLineCwd(path.join(SESSIONS, slug, files[files.length - 1]));
    const cf = candFile(slug);
    const cands = fs.existsSync(cf) ? fs.readFileSync(cf, "utf8").split("\n").filter(Boolean).length : 0;
    rows.push({ slug, sessions: files.length, candidates: cands, cwd });
    if (limit && rows.length >= limit) break;
  }
  console.log(JSON.stringify({ projects: rows }, null, 2));
}

async function gather(slug) {
  if (!slug) { console.error("gather <slug>"); process.exit(1); }
  ensure(WORK);
  const files = listSessions(slug);
  if (!files.length) { console.error(`no sessions in ${slug}`); process.exit(1); }
  const out = workFile(slug);
  const ws = fs.createWriteStream(out, { encoding: "utf8" });
  let chars = 0;
  for (const f of files) {
    const file = path.join(SESSIONS, slug, f);
    const rec = { sessionId: null, startedAt: null, cwd: null, file: f, lines: [] };
    const rl = readline.createInterface({ input: fs.createReadStream(file, { encoding: "utf8" }), crlfDelay: Infinity });
    for await (const line of rl) {
      const t = line.trim();
      if (!t) continue;
      let d; try { d = JSON.parse(t); } catch { continue; }
      if (d.type === "session") { rec.sessionId = d.id; rec.startedAt = d.timestamp; rec.cwd = d.cwd; continue; }
      if (d.type !== "message") continue;
      const m = d.message || {};
      const role = m.role;
      if (!role) continue;
      const text = textOf(m.content, { role, toolSnippet: true });
      if (!text || !text.trim()) continue;
      const label = role === "toolResult" ? "tool" : role;
      const entry = `[${label}] ${cap(text, role === "user" ? 2000 : 1200)}`;
      rec.lines.push(entry);
      chars += entry.length;
      if (chars > 200000) { rec.lines.push("[…truncated: see source file]"); break; }
    }
    try { rl.close(); } catch {}
    if (rec.lines.length) ws.write(JSON.stringify(rec) + "\n");
  }
  ws.end();
  await new Promise((r) => ws.on("finish", r));
  console.log(JSON.stringify({ ok: true, slug, workFile: out, sessions: files.length, chars }, null, 2));
}

async function append(slug) {
  if (!slug) { console.error("append <slug>"); process.exit(1); }
  ensure(HARVEST);
  const cf = candFile(slug);
  // load existing ids+norms for dedup
  const seenId = new Set();
  const seenNorm = new Set();
  if (fs.existsSync(cf)) for (const l of fs.readFileSync(cf, "utf8").split("\n")) {
    if (!l.trim()) continue;
    try { const o = JSON.parse(l); seenId.add(o.id); seenNorm.add(norm(o.content)); } catch {}
  }
  let added = 0, dup = 0, bad = 0;
  const cwd = await resolveCwd(slug);
  const stdin = process.stdin.isTTY ? "" : fs.readFileSync(0, "utf8");
  const ws = fs.createWriteStream(cf, { encoding: "utf8", flags: "a" });
  for (const line of stdin.split("\n")) {
    const t = line.trim();
    if (!t) continue;
    let c; try { c = JSON.parse(t); } catch { bad++; continue; }
    const content = String(c.content || "").trim();
    if (!content) { bad++; continue; }
    const n = norm(content);
    if (seenNorm.has(n)) { dup++; continue; }
    const id = crypto.createHash("sha1").update(n).digest("hex").slice(0, 10);
    if (seenId.has(id)) { dup++; continue; }
    seenId.add(id); seenNorm.add(n);
    const rec = { id, content, category: c.category || "fact", scope: c.scope || "project", source: c.source || null, ts: new Date().toISOString(), slug, cwd };
    ws.write(JSON.stringify(rec) + "\n");
    added++;
  }
  await new Promise((r) => ws.end(r));
  console.log(JSON.stringify({ ok: true, slug, added, dup, bad, candidateFile: cf }));
}

async function show(slug) {
  if (!slug) { console.error("show <slug>"); process.exit(1); }
  const cf = candFile(slug);
  if (!fs.existsSync(cf)) { console.error(`no candidates for ${slug}`); process.exit(1); }
  const rows = fs.readFileSync(cf, "utf8").split("\n").filter(Boolean).map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  if (!rows.length) { console.log("No candidates."); return; }
  for (const r of rows) {
    console.log(`◆ [${r.scope}/${r.category}] ${r.id}  (src: ${r.source || "-"})`);
    console.log(`  ${r.content}`);
    console.log("");
  }
  console.log(`(${rows.length} candidates for ${slug})`);
}

async function review() {
  ensure(HARVEST);
  const decided = loadDecided();
  const files = fs.existsSync(HARVEST) ? fs.readdirSync(HARVEST).filter((f) => f.endsWith(".jsonl")) : [];
  const rows = [];
  for (const f of files) {
    const slug = f.replace(/\.jsonl$/, "");
    const all = fs.readFileSync(path.join(HARVEST, f), "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    const undecided = all.filter((r) => !decided.has(r.id)).length;
    if (all.length) rows.push({ slug, candidates: all.length, undecided });
  }
  console.log(JSON.stringify({ pending: rows.sort((a, b) => b.undecided - a.undecided) }, null, 2));
}

// ── pass-2 batch + decided ledger ────────────────────────────────────
function loadDecided() {
  const set = new Set();
  if (fs.existsSync(DECIDED)) for (const l of fs.readFileSync(DECIDED, "utf8").split("\n")) { const t = l.trim(); if (t) set.add(t); }
  return set;
}
function allCandidates() {
  if (!fs.existsSync(HARVEST)) return [];
  const out = [];
  for (const f of fs.readdirSync(HARVEST).filter((x) => x.endsWith(".jsonl")).sort()) {
    const slug = f.replace(/\.jsonl$/, "");
    for (const l of fs.readFileSync(path.join(HARVEST, f), "utf8").split("\n")) {
      if (!l.trim()) continue;
      try { const o = JSON.parse(l); if (o && o.id) out.push(o); } catch {}
    }
  }
  return out; // ordered: project-sorted, file order (oldest candidate first)
}
async function next(n) {
  ensure(HARVEST);
  n = Math.max(1, Math.min(n || 20, 200));
  const decided = loadDecided();
  const all = allCandidates();
  const undecided = all.filter((r) => !decided.has(r.id));
  const batch = undecided.slice(0, n).map((r, i) => ({ n: i + 1, id: r.id, slug: r.slug, scope: r.scope, category: r.category, content: r.content, source: r.source || null, cwd: r.cwd || null }));
  console.log(JSON.stringify({ requested: n, presented: batch.length, remaining: undecided.length - batch.length, batch }, null, 2));
}
async function mark(ids) {
  ensure(HARVEST);
  const decided = loadDecided();
  let added = 0;
  const ws = fs.createWriteStream(DECIDED, { encoding: "utf8", flags: "a" });
  for (const id of ids.map((x) => x.trim()).filter(Boolean)) {
    if (decided.has(id)) continue;
    decided.add(id); ws.write(id + "\n"); added++;
  }
  await new Promise((r) => ws.end(r));
  console.log(JSON.stringify({ ok: true, marked: added, alreadyDecided: ids.length - added, totalDecided: decided.size }));
}
async function decided() {
  const set = loadDecided();
  console.log(JSON.stringify({ totalDecided: set.size, ids: [...set] }, null, 2));
}
async function reset() {
  try { fs.rmSync(DECIDED); } catch {}
  console.log(JSON.stringify({ ok: true, cleared: DECIDED }));
}

// ── small utils ──────────────────────────────────────────────────────
const norm = (s) => String(s || "").toLowerCase().replace(/\s+/g, " ").trim();
async function resolveCwd(slug) {
  const files = listSessions(slug);
  if (!files.length) return null;
  return firstLineCwd(path.join(SESSIONS, slug, files[files.length - 1]));
}

main().catch((e) => { console.error(e?.stack || String(e)); process.exit(1); });
