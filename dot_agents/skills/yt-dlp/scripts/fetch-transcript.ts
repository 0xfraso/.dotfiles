#!/usr/bin/env bun
/**
 * Fetch YouTube video metadata + English transcript via yt-dlp.
 *
 * Usage:  bun run fetch-transcript.ts <youtube-url>
 *
 * Outputs JSON to stdout:
 *   { id, title, description, channel, duration, upload_date, categories, transcript }
 *
 * Exit codes:
 *   0  success
 *   1  usage error
 *   2  yt-dlp not found
 *   3  no english subtitles available
 */

import { spawnSync, mkdirSync, rmSync, readdirSync, readFileSync } from "fs";
const { existsSync } = await import("fs").then(m => m);
import { join } from "path";
import { tmpdir } from "os";

// --- Args ---
const url = process.argv[2];
if (!url) {
  console.error("Usage: bun run fetch-transcript.ts <youtube-url>");
  process.exit(1);
}

// --- Check yt-dlp ---
const ytDlpPath = Bun.spawnSync(["which", "yt-dlp"]).stdout?.toString().trim();
if (!ytDlpPath) {
  console.error("yt-dlp not found on PATH");
  process.exit(2);
}

// --- Prepare temp dir ---
const tmpDir = join(tmpdir(), "yt-dlp");
mkdirSync(tmpDir, { recursive: true });

// --- Step 1: Fetch metadata as JSON ---
const metaProc = Bun.spawnSync([ytDlpPath, "--skip-download", "-j", url], {
  stdout: "pipe",
  stderr: "pipe",
});

if (metaProc.exitCode !== 0) {
  console.error("yt-dlp metadata fetch failed:", metaProc.stderr.toString());
  process.exit(1);
}

const meta = JSON.parse(metaProc.stdout.toString());

// --- Step 2: Download subtitle file ---
const videoId = meta.id as string;
const subProc = Bun.spawnSync([
  ytDlpPath,
  "--skip-download",
  "--write-subs",
  "--write-auto-subs",
  "--sub-langs", "en,en-US,en-GB",
  "--sub-format", "vtt/best",
  "-o", join(tmpDir, videoId),
  url,
], {
  stdout: "pipe",
  stderr: "pipe",
  cwd: tmpDir,
});

// --- Step 3: Find and parse the VTT file ---
let transcript = "";
const vttFiles = readdirSync(tmpDir).filter(f => f.startsWith(videoId) && f.endsWith(".vtt"));

if (vttFiles.length === 0) {
  console.error("No English subtitles available for this video.");
  process.exit(3);
}

// Prefer manual subs over auto-generated
const manualSub = vttFiles.find(f => !f.includes(".auto."));
const chosenFile = manualSub ?? vttFiles[0];
const vttRaw = readFileSync(join(tmpDir, chosenFile), "utf-8");
transcript = cleanVtt(vttRaw);

// --- Step 4: Clean up downloaded files ---
for (const f of vttFiles) {
  try { rmSync(join(tmpDir, f)); } catch {}
}

// --- Step 5: Output JSON ---
const result = {
  id: meta.id,
  title: meta.title,
  description: meta.description,
  channel: meta.channel,
  duration: meta.duration,
  upload_date: meta.upload_date,
  categories: meta.categories,
  transcript,
};

console.log(JSON.stringify(result, null, 2));

// --- Helpers ---

function cleanVtt(raw: string): string {
  const lines = raw.split("\n");
  const textLines: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();
    // Skip empty lines
    if (!trimmed) continue;
    // Skip VTT header
    if (trimmed === "WEBVTT") continue;
    if (trimmed.startsWith("Kind:")) continue;
    if (trimmed.startsWith("Language:")) continue;
    if (trimmed.startsWith("NOTE")) continue;
    if (trimmed.startsWith("Style:")) continue;
    // Skip timestamp lines (e.g. 00:01:23.456 --> 00:01:25.789)
    if (/^\d{2}:\d{2}/.test(trimmed) && trimmed.includes("-->")) continue;
    // Skip cue identifiers (just a number on its own line)
    if (/^\d+$/.test(trimmed)) continue;
    // Strip HTML-like tags: <c>, </c>, <b>, </b>, etc.
    const cleaned = trimmed.replace(/<[^>]+>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&nbsp;/g, " ");
    if (cleaned.trim()) {
      textLines.push(cleaned.trim());
    }
  }

  // Deduplicate consecutive identical lines (VTT repeats cue text)
  const deduped: string[] = [];
  for (const line of textLines) {
    if (deduped[deduped.length - 1] !== line) {
      deduped.push(line);
    }
  }

  return deduped.join(" ");
}
