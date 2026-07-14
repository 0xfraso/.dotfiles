---
name: yt-dlp
description: Fetch YouTube video transcripts and metadata using yt-dlp, then summarize or answer questions about the content. Use when the user shares a YouTube URL and wants a summary, key points, or specific information from the video without watching it.
---

# yt-dlp Video Transcript Skill

## Quick start

When the user shares a YouTube URL and asks about its content:

```bash
# Fetch metadata + transcript in one pass
yt-dlp --skip-download --write-auto-subs --sub-langs "en,en-US,en-GB" --sub-format "vtt/best" --print-to-file "%(id)s" /dev/null -o "/tmp/yt-dlp/%(id)s" "VIDEO_URL" 2>/dev/null
```

Then parse the resulting `.vtt` file and answer the user's question.

## Workflows

### 1. Fetch transcript and metadata

Use the helper script for reliability:

```bash
bun run /home/fraso/.agents/skills/yt-dlp/scripts/fetch-transcript.ts "VIDEO_URL"
```

This outputs a JSON object with:
- `id` — video ID
- `title` — video title
- `description` — full description
- `channel` — channel name
- `duration` — duration in seconds
- `upload_date` — YYYYMMDD format
- `categories` — YouTube categories
- `transcript` — cleaned plain-text transcript (no timestamps, no VTT markup)

If the helper script fails, fall back to manual steps below.

### 2. Manual fallback

```bash
# Step A: Get metadata as JSON
yt-dlp --skip-download -j "VIDEO_URL" > /tmp/yt-dlp/meta.json

# Step B: Download subtitle file
yt-dlp --skip-download --write-auto-subs --sub-langs "en,en-US,en-GB" --sub-format "vtt/best" -o "/tmp/yt-dlp/%(id)s" "VIDEO_URL"

# Step C: Read and clean the VTT file
# Strip VTT headers, timestamps, and cue tags to get plain text
```

### 3. Clean VTT to plain text

VTT files contain markup like `WEBVTT`, timestamp lines (`00:01:23.456 --> 00:01:25.789`), and HTML tags (`<c>`, `<b>`). Strip all of these and deduplicate lines (VTT often repeats cue text).

### 4. Answer the user's question

With the transcript and metadata available:
- **Summarize**: Provide a concise summary of the video's main points.
- **Extract info**: Answer the specific question the user asked about the content.
- **Key takeaways**: List the most important points as bullet items.

Always cite the video title and channel in your response.

## Important notes

- Auto-generated English subtitles are the primary source; manual subtitles are preferred when available.
- If no English subtitles exist, report that to the user — do not attempt translation.
- Long videos produce long transcripts. For videos over 60 minutes, warn the user and consider summarizing in sections.
- The `/tmp/yt-dlp/` directory is used for temporary files; it is created automatically by the script.
- Always clean up downloaded subtitle files after processing.
