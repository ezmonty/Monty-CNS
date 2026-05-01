---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [valor, planning, superplan, sessions, productivity]
date: 2026-05-01
---

# Audit current state before assuming a stored plan is fresh work

Phase 8 + Phase 9 of the Valor 2.0 superplan looked like ~2 days of work on paper: B2 AbortController, B3 apiError state, smoke_workstation_action.py (7 tests), DecisionWorkspace.test.tsx (39 tests), Defer + RequestChanges E2E, UI_STATE_CONTRACT.md, 15 slug-refresh labels, 12 Select aria-labels, jest-axe install, axe scans. **Every single item had already been completed in earlier sessions** — but never formally signed off in the worklog. The session's actual work shrank to: verifying state, fixing 6 review findings, fixing 4 E2E selector bugs, writing the audit + sign-off entry.

**The waste mode:** start the day re-implementing checklist items because the plan says "next: do X" and no one checked whether X is already done. Failing fast on this is cheap (`grep -r` for the symbol, run the test file, check the import); failing slow is expensive (rebuild a feature that's been working for a week).

**Audit-first protocol when picking up a stored plan:**
1. For each checklist item, locate the named artifact (test file, function, prop, env var). If it exists, verify with one command (`pytest path/to/test`, `npm run test -- name`, `grep -n 'aria-label' file`).
2. Mark items DONE-VERIFIED, DONE-NEEDS-CHECK, or NOT-STARTED.
3. Only the NOT-STARTED set is real work. The DONE-NEEDS-CHECK set is the actual session.
4. Write the audit *before* writing any code. The audit is the plan revision.

**Heuristic:** if a stored plan was authored more than 24 hours ago, the first commit of the new session is "audit + state-of-plan revision," not "begin Phase X." This single pivot turned a 2-day re-implementation into a 2-hour verification + sign-off.
