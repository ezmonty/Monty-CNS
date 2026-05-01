---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [valor, vite, dev-proxy, e2e, environment-divergence, frontend]
date: 2026-05-01
---

# Vite dev proxy without path rewrite is invisible until E2E fires

The Vite dev config maps `/api/console/workstation` -> `http://127.0.0.1:8101` but does **not** rewrite the path. The agent serves `/workstation`, not `/api/console/workstation`. Production nginx rewrites the prefix, so prod works while dev silently 404s. The frontend's silent fallback to cockpit fixture data (with IDs like `pm-1`) made the bug invisible to humans browsing the dev UI — it only surfaced when 12 Playwright tests failed in a wave looking for items the fixture didn't have.

**Generalizable rule:** when an E2E suite produces a wave of "element not found" failures right after a dev-mode change, check the **environment delta first** (proxy rewrite, env vars, build state) before hunting code defects. The first 10 minutes of debugging a wave of E2E failures should be reserved for "is this even running against the right backend?"

**Concrete checks for any Vite project:**
1. Does `vite.config.ts` `server.proxy` use `rewrite: (path) => path.replace(/^\/api\//, '/')` ?
2. Does the prod nginx config strip the same prefix?
3. If the answers differ, the dev environment is lying.

**Action:** add a smoke test that hits a real backend route through the dev proxy and asserts on the response shape — not just status 200. A 200 from the fixture fallback looks identical to a 200 from the backend until you read the body.
