---
title: "axios baseURL is silently discarded for absolute paths"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# axios baseURL is silently discarded for absolute paths

When an axios instance has `baseURL: '/api/console'`, any path argument starting with `/` (e.g., `'/health'`) is treated as origin-absolute — axios discards baseURL entirely. The request goes to `/health`, not `/api/console/health`. All paths must be relative (no leading slash) to correctly append to baseURL.

**Context:** Found during /pulse audit of valorApi.ts — 10 calls had leading slashes routing to wrong agent ports, breaking the full financial HTTP chain. Fixed by removing leading slash on all 10 lines.

**Why it's subtle:** The code looks correct at a glance. The leading slash is easy to type and IDEs don't warn on it. The bug only surfaces as a wrong-port 404 or unexpected response, not a JS error.
