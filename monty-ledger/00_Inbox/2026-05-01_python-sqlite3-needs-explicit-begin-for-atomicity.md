---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
demoted_from: 4
demoted_at: 2026-05-02
demoted_reason: "AI self-set without human Type-2 verification — demoted per VAULT_RULES confidence scale"
access: private
truth_layer: working
tags: [python, sqlite3, transactions, atomicity, backend]
date: 2026-05-01
---

# Python sqlite3 atomic transactions need explicit BEGIN despite isolation_level

Python's stdlib `sqlite3` module's automatic transaction management is too permissive for security-critical writes. DDL statements (`ALTER TABLE`, `CREATE INDEX`) **auto-commit** mid-transaction, breaking implicit boundaries. Setting `isolation_level=None` makes it worse, not better. The fix: wrap multi-statement writes in an explicit `conn.execute("BEGIN")` -> writes -> `conn.commit()` block with an outer `except` that calls `conn.rollback()`.

**Concrete failure mode caught here (Phase 2 hardening, valor2.0):** the audit-trail write was non-atomic — entity UPDATE + cos_approval_trail INSERT were both wrapped in a try, but an `OperationalError` on the INSERT was caught silently and the UPDATE auto-committed anyway. Status flipped, no audit record. **No functional test exercised the path where the trail table was missing.** The adversarial-reviewer caught it via reasoning about exception flow.

**Concrete pattern that's actually safe:**
```python
# 1) Run any column-existence probe FIRST, outside the explicit transaction
#    (DDL inside SQLite transactions implicitly commits)
cur.execute("PRAGMA table_info(cos_approval_trail)")
has_columns = {row[1] for row in cur.fetchall()}

# 2) Now open the explicit transaction
try:
    conn.execute("BEGIN")
    cur.execute("UPDATE entity SET status=? WHERE id=?", ...)
    if cur.rowcount == 0:
        conn.rollback()
        raise HTTPException(404, "not found")
    cur.execute("INSERT INTO cos_approval_trail (...) VALUES (...)", ...)
    conn.commit()
except Exception:
    conn.rollback()
    raise
```

**Rule of thumb:** if the operation needs to be atomic for security or audit reasons, write it as if `isolation_level` doesn't exist. Use BEGIN/COMMIT/rollback explicitly.
