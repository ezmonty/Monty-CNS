---
title: "Transcript schemas are wider than user messages — scrub every string field"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "review"]
---

**Project:** valor2.0
**Tags:** operations, review
**Confidence:** verified
**Context:** Built `scripts/backscrub_claude_transcripts.py` to retrofit Claude Code transcripts. First cut walked only `type=user` records with `message.content` as a string. Detected 12 secrets across 5 files. After extending the walker to handle `assistant.message.content[].input.command` (Bash tool_use blocks), `last-prompt.lastPrompt`, `tool_result.content`, and content-block lists: 208 detections across 22 files. Same files. The OpenAI key the user pasted lived in 8 distinct record shapes within a single transcript — only 1 was the user message.

When scrubbing/redacting any structured transcript (Claude Code, OpenAI Assistants, agent traces, log JSONL), assume any string-bearing field can carry a secret. Walk recursively over dicts and lists; scrub every string value, not just the obvious "user-input" field. The assistant's tool_use commands echo back arguments verbatim; tool_result content captures stdout that may include the secret in command output; cached prompt-history fields (`last-prompt`, `lastPrompt`, `summary`, `title`) all need coverage. A per-record-type allowlist will miss things; a recursive string-walker is the right shape.
