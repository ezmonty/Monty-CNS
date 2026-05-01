---
title: "approve_change_order requires approval_token captured from the submit response"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# approve_change_order requires approval_token captured from the submit response

When submitting a change order via `submit_change_order`, the response includes an `approval_token`. This token must be captured and passed to `approve_change_order`. The token enforces that only the submit-triggered approval flow can approve — arbitrary approvals without it are rejected.

**Smoke test pattern:**
```python
submit_body = _run("submit_change_order", co_id=co_id, user_id="pm", actor_role="pm")
approval_token = (
    submit_body.get("data", {}).get("approval_token")
    or (submit_body.get("data", {}).get("change_order") or {}).get("approval_token")
)
approve_body = _run("approve_change_order", co_id=co_id, approval_token=approval_token, ...)
```

**Context:** Discovered when writing smoke_financial_http.py test for the approve flow. The token location in the response is nested: check `data.approval_token` first, then `data.change_order.approval_token`.
