---
title: "r.json() inside Python assert messages masks JSONDecodeError on non-JSON responses"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "strategy"]
---

# r.json() inside Python assert messages masks JSONDecodeError on non-JSON responses

In Python smoke tests, never call `r.json()` inside an f-string assertion message. If the response isn't JSON (nginx 502, proxy error, HTML error page), `.json()` raises `JSONDecodeError` before pytest can render the assertion. The developer sees a cryptic parser traceback instead of "Expected 200, got 502".

**Fix:** Use `r.text[:200]` (httpx) or decode raw bytes instead.

```python
# Bad
assert r.status_code == 200, f"HTTP {r.status_code}: {r.json()}"

# Good
assert r.status_code == 200, f"HTTP {r.status_code}: {r.text[:200]}"
```

**Context:** Caught during /review of smoke_financial_http.py. Pattern applies to any HTTP test that might receive non-JSON error responses from reverse proxies.
