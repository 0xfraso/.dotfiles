---
name: tldr
description: Summarize the current conversation context into a concise TL;DR. Use when the user says "tldr", "tl;dr", "summarize", "give me the short version", or asks for a recap of what has been discussed.
---

# TL;DR

Summarize the **entire conversation so far** into a compact recap.

## Output format

Produce two sections, in this exact order:

### 1. Summary paragraph

One concise paragraph (3–5 sentences) capturing:
- The overarching topic or goal
- Key decisions made
- Current state of progress
- Any open questions or blockers

### 2. Key points

A structured bullet list of **5–10 bullets**. Each bullet should be:
- A single sentence
- Ordered from most to least important
- Focused on outcomes, decisions, and action items — not process narration

Good bullet: `Decided to use Pi RPC subprocesses instead of HTTP/SSE for agent isolation.`
Bad bullet:  `We talked about the architecture for a while and then decided something.`

## Rules

- **Only reference what is actually in context.** Never infer or hallucinate facts not discussed.
- If the conversation is very short (< 5 exchanges), scale down accordingly — fewer bullets, shorter paragraph.
- If the conversation covers multiple distinct topics, group bullets by topic with a bold label prefix (e.g., **Architecture:**, **Testing:**).
- Omit the Key points section entirely if there are fewer than 3 meaningful points.
- Do not include meta-commentary like "Here is your summary." Just output the summary.
