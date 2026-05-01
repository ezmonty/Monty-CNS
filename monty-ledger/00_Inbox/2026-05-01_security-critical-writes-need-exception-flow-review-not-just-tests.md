---
type: pattern
status: review
origin_type: ai-proposed
confidence: 4
access: private
truth_layer: working
tags: [security, code-review, audit-trails, exception-handling, adversarial-review]
date: 2026-05-01
---

# The most dangerous bugs hide in exception flows that no test exercises

The single most dangerous finding from the Phase 2 security pass on Valor 2.0 was **not caught by any functional test**. The pre-fix code structure:

```python
try:
    cur.execute("UPDATE entity SET status=? WHERE id=?", ...)  # commits
    try:
        cur.execute("INSERT INTO cos_approval_trail (...) VALUES (...)")
    except OperationalError:
        pass  # trail table might not exist, swallow it
except Exception:
    raise HTTPException(500, ...)
```

If the `cos_approval_trail` table is missing or the column doesn't exist (e.g. partial migration on a new tenant), the inner `except OperationalError: pass` swallows the failure. The outer commit fires — entity status flips, no audit record. **Compliance silently broken.** No functional test exercised the path where the trail table was absent because in dev it was always present.

**The adversarial-reviewer caught this by *reasoning about the exception flow*, not by running anything.** The agent walked through "what happens when each line fails?" and found the path where data integrity breaks without any visible error.

**Rule for security-critical writes (audit trails, money movement, role grants, token issue/revoke):**
1. Every `except` block that doesn't re-raise gets a **comment explaining why swallowing is safe** plus a **logging call** at WARN or ERROR.
2. Manually trace exception flow during code review — do not rely on functional tests for this. Tests assert on the happy path; this class of bug is in the unhappy path nobody tests.
3. If the operation must be atomic, prefer a single explicit transaction over nested try blocks. If you can't see at a glance which writes commit on which exception, neither can a reviewer.
4. **Probe-then-rollback** for column existence belongs *outside* the security-critical transaction, before BEGIN.

**Heuristic:** if your code can answer "what happens if step 2 fails?" with "step 1 commits anyway and step 2 is silently lost," that's a CRITICAL — regardless of test status.
