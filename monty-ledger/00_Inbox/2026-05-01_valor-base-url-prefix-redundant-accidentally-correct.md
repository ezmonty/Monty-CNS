---
title: "VALOR_BASE_URL path pattern in valorApi.ts is redundant but accidentally correct"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# The ${VALOR_BASE_URL}/path pattern in valorApi.ts is redundant but accidentally correct

`valorApi.post(\`${VALOR_BASE_URL}/escalation/sweep\`)` produces `/api/console/escalation/sweep` — an absolute path that makes axios ignore baseURL. But because it starts with `/api/console`, the Vite proxy still matches and routes correctly. It works by coincidence.

**Why it's fragile:** If `VALOR_BASE_URL` changes, relative-path callers update automatically; these 6 lines don't. Creates two inconsistent patterns in the same file. Fixed by normalizing all 6 to relative paths: `valorApi.post('escalation/sweep', ...)`.

**Context:** Discovered in /review of the valorApi.ts path-fix commit. The Frontend Council swarm flagged these as "not bugs, left alone" — but consistency review surfaced them as a medium-priority cleanup.
