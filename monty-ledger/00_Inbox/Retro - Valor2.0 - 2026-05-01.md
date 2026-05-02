---
type: retro
status: review
origin_type: ai-proposed
confidence: 3
demoted_from: 4
demoted_at: 2026-05-02
demoted_reason: "AI self-set without human Type-2 verification — demoted per VAULT_RULES confidence scale"
access: private
truth_layer: working
tags: [retro, valor2.0, superplan, phase8, phase9, security]
date: 2026-05-01
---

# Retro — Valor 2.0 — 2026-05-01

## Session Stats
- **Commits:** 9 in this session arc (`a45e2dcb` → `129d5da9`)
- **Files changed:** 23 (+1106 / -410)
- **Plans closed:** 3 (CFO H2→H3 superplan, Phase 2 hardening, Phase 8 + Phase 9 audit/sign-off)
- **Tests added:** 21 new (smoke_workstation_action 7, smoke_cfo_bank_statements 6, ArAgingPanel 8)
- **Test runs:** 149/149 unit + 25/25 backend smoke + 4 pass / 0 fail / 7 skip live E2E
- **Smoke verifications:** 3 (after each major commit batch)
- **Adversarial-review findings fixed:** 2 CRITICAL (super-role allowlist gap; non-atomic audit trail) + 6 LOW/MEDIUM (rowcount guard, double-rollback, 503 conversion, dead variable, LIVE_OAUTH_VALIDATION stub, hardcoded KPI)

---

## Accomplished

- **CFO H2→H3 superplan** — phases 1–7 closed; 23 new smoke tests; 102/102 CFO test suite green; AR aging live (`source: qbo_live`)
- **Phase 2 security hardening** — single-use approval tokens, atomic BEGIN/COMMIT/rollback for entity UPDATE + cos_approval_trail INSERT, `_ALLOWED_ACTOR_ROLES` server-side guard, 503-on-503-able-error pattern, admin/ceo/coo cockpit configs
- **/review fix sweep** — closed 6 review findings same-session: rowcount==0 → 404 (no ghost trail), removed double-rollback, 500→503 for store/dependency unavailability, removed dead `trail_table_missing` variable, NotImplementedError on LIVE_OAUTH_VALIDATION=true stub path, '--' placeholder for hardcoded admin KPI
- **Phase 8 H4 Gap Closure** — verified all checklist items in code (B2 AbortController, B3 apiError state, C1 smoke_workstation_action.py 7 tests, C2 DecisionWorkspace.test.tsx 39 tests, C3 Defer + RequestChanges E2E, C4 UI_STATE_CONTRACT.md)
- **Phase 9 A11y Complete** — verified: 15 slug refresh labels renamed to plain English, 12 Select aria-labels added, dynamic Burger aria-label, Voice button honestly disabled, jest-axe + @axe-core/playwright installed, 19+10+8 axe/unit tests in place
- **E2E hardening** — added `primary-action-{id}` testid; rewired 4 specs (workstation-pm/cfo/super, a11y) to target the primary action button instead of clicking #1 (Preview); filtered defer/escalate tests to approval cards because routing table only allows the action on initial-state items
- **Production deployments** — 4 valor-vm deploys (`git pull → npm install → npm run build → POST /reload`); each verified by /smoke (qbo_live data, immutable bundle, no-cache HTML, x-api-key auth)

---

## Learned

### 1. Vite dev proxy without path rewrite is a hidden production-vs-dev divergence
The Vite config maps `/api/console/workstation` → `http://127.0.0.1:8101` but doesn't rewrite the path. The agent serves `/workstation`, not `/api/console/workstation`. So in dev mode the fetch silently 404s and the WorkstationPage falls back to cockpit fixture data with IDs like `pm-1`. Production nginx rewrites the path, so it works there. This caused 12 false-fail E2E tests on the first run — entirely explained by environment, not code. **Action:** when an E2E suite produces a wave of test-not-finding-element failures, check the dev/prod environment delta first, not the code under test.

### 2. `data-testid` on the wrong button is invisible until the test framework counts buttons
`InboxList` renders Preview (button #1), Acknowledge for alerts (#2), Primary Action (#3). Tests doing `.getByRole('button').first()` got Preview every time — but only the primary action opens the DecisionWorkspace. The bug had been in the codebase across multiple sessions and nobody noticed because the unit tests don't exercise this click path. **Action:** for any "Click to open X" test, target the button by `data-testid`, not by ordinal — ordinals are fragile across UI changes.

### 3. UI affordance ≠ backend allowance
The `defer-menu` icon renders on every inbox item, but the backend routing table only accepts defer/escalate on items in their initial pending state (`("rfis", "open", "defer", "*")` but no entry for `("rfis", "acknowledged", "defer", "*")`). E2E tests grabbing "first defer-menu globally" landed on alert RFIs in `acknowledged` state and 422'd. **Action:** when adding new actions to the workstation routing table, check the UI for affordances that imply support the backend doesn't grant — either add routing entries or hide the affordance.

### 4. The most dangerous bug from the security pass would never have been caught by functional tests
The pre-fix code caught `OperationalError` on the cos_approval_trail INSERT silently and then committed the entity UPDATE anyway → status flipped, no audit trail. **No functional test exercises the path where the trail table is missing.** The adversarial-reviewer agent caught it via reasoning about the exception flow, not by running anything. **Action:** for security-critical writes, manually trace the exception flow in adversarial-review even when all tests pass.

### 5. Atomic transactions in Python sqlite3 require explicit BEGIN despite isolation_level
Python's sqlite3 module's automatic transaction management is too permissive — DDL statements (ALTER TABLE) auto-commit, breaking implicit transaction boundaries. Use `conn.execute("BEGIN")` + `conn.commit()` + outer-except rollback to make multi-statement writes truly atomic. The probe-then-rollback pattern for column-existence detection must run BEFORE the explicit BEGIN block, since DDL inside a transaction implicitly commits in SQLite.

### 6. 500 vs 503 is the difference between "we crashed" and "the world isn't ready"
Smoke tests asserting "no 5xx" or "< 500" treat all 5xx as crashes. But 503 (Service Unavailable) is the correct semantic for "DB unreachable / dependency missing" — it tells the caller "retry later." Endpoints catching DB exceptions should return 503, not 500. Tests should explicitly accept 503 alongside 4xx as non-crash outcomes. **Action:** audit catch-Exception → 500 patterns and convert to 503 where the underlying cause is infrastructure unavailability.

### 7. "No live server required" tests must scope their live-check to the live mode
The smoke_cfo_bank_statements tests claimed TestClient mode required no live server — but the module-level `_check_live()` skip gated everything on port 8350 being reachable. Fix: `if not USE_TESTCLIENT and not _check_live(): pytest.skip(...)`. **Action:** when TestClient and live modes both exist, the live-check must be conditional on `USE_TESTCLIENT == 0`.

### 8. Verification beats assumption — most "remaining work" was already done
Phase 8 + Phase 9 audit revealed every checklist item had been completed in earlier sessions but never formally signed off. The session's actual work: verifying state, fixing 6 review findings, fixing 4 E2E test bugs, writing the audit/sign-off worklog. **Action:** when starting from a stored plan, audit current state first instead of assuming the plan is fresh.

---

## Next Time

### What was harder than expected
- **First E2E failure wave was misread.** Spent ~10 minutes looking for code defects before identifying it as a Vite dev proxy issue. Should have checked the env delta first.
- **The smoke test live-skip pattern is inconsistent across files.** `smoke_cfo_approval_gateway` uses TestClient cleanly with no live check; `smoke_cfo_bank_statements` originally had module-level live check + `pytestmark = pytest.mark.live`. Both should converge on the cleaner pattern.
- **Test contention with E2E approval-state.** Running workstation-pm.spec.ts approves CO-018 → next run has no approvals to test → tests skip. Smoke fixtures reset CO-018 between Python tests; E2E doesn't have an equivalent reset hook. Either add an E2E setup hook or accept that subsequent runs will skip.

### Unfinished / future work
- **21 remaining `status_code=500` in CFOConsoleAgent.py** flagged by audit. Some are genuine internal errors; some are dependency-unavailability that should be 503. Worth a separate sweep.
- **defer-menu UI affordance** should be hidden on non-deferrable items (alerts/monitors). Currently shown on every item, leading to user confusion when clicking it 422s.
- **E2E approval-state reset hook** would make workstation E2E reproducibly green instead of "first run passes, subsequent runs skip."
- **LIVE_OAUTH_VALIDATION=true** path now raises NotImplementedError. Real wiring is the actual H4 work for the connector subsystem.
- **Vite dev proxy path rewrite** for `/api/console/*` so dev environment matches production routing.

### What to do differently
- **Always check env diff first** when E2E starts failing (Vite dev URL vs production URL, environment variables, build state).
- **Reach for `data-testid` on every interactive element**, not just the obvious ones. The `primary-action-{id}` testid would have prevented this entire E2E debugging round.
- **For multi-statement DB writes, default to explicit `BEGIN`/`COMMIT`/`rollback` from day one.** The probe-then-real-write pattern is harder to read than just doing the migration check at startup or inside the explicit transaction.
- **When a stored plan exists from earlier sessions, run a quick state-verification sweep first** instead of assuming the plan is fresh work.
