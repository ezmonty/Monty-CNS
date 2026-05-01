---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [valor, frontend, backend, contracts, e2e, ux]
date: 2026-05-01
---

# UI affordance != backend allowance (defer-menu on every row, but routing table only allows initial state)

The `defer-menu` icon rendered on every inbox item, but the backend routing table only accepted defer/escalate on items in their **initial pending state** — `("rfis", "open", "defer", "*")` had an entry; `("rfis", "acknowledged", "defer", "*")` did not. E2E tests grabbing "first defer-menu globally" landed on alert RFIs in `acknowledged` state and got a 422. End users would have hit the same wall.

**The drift pattern:** the backend routing table is the *real* contract. The UI is whatever the frontend dev rendered for "looks plausible." When they diverge, you get phantom buttons that 422 — the worst possible UX, because the user thinks the action is offered but it silently isn't.

**Three workable resolutions, in priority order:**
1. **Hide the affordance** based on the same metadata the backend uses: `if (item.state in ALLOWED_DEFER_STATES) render the menu`. Requires the frontend to know the routing table — best done by exposing `available_actions: string[]` per item from the backend.
2. **Add the routing entries** if the action *should* be allowed in those states.
3. **Disabled-with-tooltip** showing why ("Cannot defer items in state: acknowledged"). Better than 422 but worse than #1.

**The forensic step that found this:** running the failing E2E test against a known-good fixture and reading the **422 response body** rather than just the status. The body said `"action 'defer' not in routing table for state 'acknowledged'"` — exactly the contract violation, plain text.

**Rule:** for any user-facing action, the source-of-truth for "is this allowed right now?" must be one place. Rendering the button without consulting that source is how you ship phantom affordances.
