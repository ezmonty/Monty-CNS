---
title: "ConstructionOSAgent /run requires actor_role or defaults to guest"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# ConstructionOSAgent /run requires actor_role in payload or defaults to 'guest'

When calling `POST /run` on ConstructionOSAgent (port 8100), commands like `create_change_order` and `create_lien_waiver` require `actor_role` in the payload. Without it, the agent defaults to `role='guest'` which lacks write permissions — returns `"Role 'guest' lacks permission for command 'create_change_order'"`.

**Exception:** Pay app commands (`create_payapp`, `submit_payapp`) use `submitted_by` as the actor indicator and are more permissive — they pass without `actor_role`.

**Context:** Discovered when 5 of 10 smoke tests failed on first run. Tests targeting CO and lien waiver commands all returned permission errors until `actor_role="pm"` was added to each payload.

**Rule for smoke tests:** Always include `actor_role` matching a role with the required permission in any POST /run payload.
