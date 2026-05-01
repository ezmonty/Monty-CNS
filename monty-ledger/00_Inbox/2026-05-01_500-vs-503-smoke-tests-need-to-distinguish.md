---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [http, status-codes, smoke-tests, observability, backend]
date: 2026-05-01
---

# 500 vs 503: smoke tests need to know the difference

Smoke tests asserting "no 5xx" or "status < 500" treat every 5xx as a crash. **500 means "we broke" — your code threw and you didn't catch it. 503 means "the world isn't ready" — DB unreachable, dependency missing, queue full.** Conflating them masks real crashes during partial-stack runs and produces flaky CI when one upstream service is slow to boot.

**The 21 instances flagged in CFOConsoleAgent.py during the Phase 2 audit had a common smell:** `except Exception: raise HTTPException(500, ...)` for paths whose actual cause was infrastructure unavailability (sqlite locked, connector unreachable, store missing). All of them should have been 503.

**Decision rule for backend exception handling:**
- Code crashed because of *its own logic* (KeyError, TypeError, division-by-zero, contract violation) -> **500**
- Code couldn't reach a dependency it needs (DB, cache, sibling agent, third-party API) -> **503**
- Caller asked for something that doesn't exist or isn't allowed -> **4xx** (404/403/422)

**Smoke-test rule:** assert on the *category*, not "no 5xx". Either:
- accept `{200, 201, 4xx, 503}` as non-crash outcomes during boot/partial-stack runs
- separately track 500s as alerting-grade and 503s as informational

**Bonus:** 503 is retry-able by clients (browsers, fetch retry libraries) where 500 is not. Returning 503 for transient infra failures gives you free retries; returning 500 means the user has to refresh.
