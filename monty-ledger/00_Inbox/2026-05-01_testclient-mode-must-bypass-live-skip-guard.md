---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [testing, pytest, smoke-tests, fastapi, testclient]
date: 2026-05-01
---

# "No live server required" tests must scope their live-check to the live mode

`smoke_cfo_bank_statements` claimed it could run in TestClient mode without a live server, but the module-level `_check_live()` skip-guard ran unconditionally and gated everything on port 8350 being reachable. Result: test file marketed itself as standalone but skipped wholesale on any developer who didn't have the live agent running. The fix is one line:

```python
# WRONG — module-level, unconditional
if not _check_live():
    pytest.skip("CFOConsoleAgent not reachable", allow_module_level=True)

# RIGHT — conditional on whether we actually need the live server
USE_TESTCLIENT = os.getenv("USE_TESTCLIENT", "1") == "1"
if not USE_TESTCLIENT and not _check_live():
    pytest.skip("CFOConsoleAgent not reachable", allow_module_level=True)
```

**The structural anti-pattern:** module-level skip guards run at import time, before any test or fixture has a chance to inspect what mode the user wants. They cannot "see" the per-test or per-class mode parameter. Either move the skip to a fixture (which runs per-test and can read env), or short-circuit the live-check with the mode toggle as shown above.

**Convention worth standardizing across a codebase:** every smoke test file has a module-level `USE_TESTCLIENT = os.getenv("USE_TESTCLIENT", "1") == "1"` flag, and **all live-only setup** is gated on `not USE_TESTCLIENT`. Then a single env flip switches the entire suite between TestClient mode (CI, no servers) and live mode (deploy verification).

**Bonus inconsistency caught in the same audit:** `smoke_cfo_approval_gateway` already did this cleanly with no live check. `smoke_cfo_bank_statements` had module-level live check + `pytestmark = pytest.mark.live`. **Two files, two patterns, same project** — convergence on the cleaner pattern is itself technical debt repayment.
