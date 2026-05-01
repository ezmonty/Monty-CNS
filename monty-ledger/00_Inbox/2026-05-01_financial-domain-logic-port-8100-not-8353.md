---
title: "Financial domain logic lives in ConstructionOSAgent port 8100 not ConsoleAgent 8353"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# Financial domain logic lives in ConstructionOSAgent:8100, not ConsoleAgent:8353

ConsoleAgent (port 8353) is the frontend-facing proxy — it receives `/api/console/*` calls from the UI via nginx. ConstructionOSAgent (port 8100) holds the actual domain logic: `create_payapp`, `submit_change_order`, `create_lien_waiver`, approve/reject flows, etc.

**Context:** DevOps Council planning agent said to target port 8353 for financial smoke tests. Backend Council read the agent code and said 8100. Confirmed by direct curl — 8353 returned an error envelope, 8100 returned the correct `status: ok` with domain data.

**Rule:** Smoke tests for financial operations must POST to `http://localhost:8100/run`. Tests for proxy/routing behavior target 8353.
