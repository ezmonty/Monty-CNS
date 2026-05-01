---
name: pulse
description: >
  System-wide coherence audit. Launches parallel Explore agents across every
  subsystem (agents, core stores, UI pages, API surface, tests, configs) and
  returns a prioritized punch list of the highest-value gaps — broken wires,
  H1/H2 stubs masquerading as features, untested paths, fixture fallbacks that
  should be live. Use when closing a loop and need to know what's actually
  real vs what's planned.
---

# /pulse — System Coherence Swarm Audit

**What this does:** Spawns parallel read-only agents across every layer of
the stack, each applying the H-Scale vocabulary to its slice. Returns a
ranked punch list of gaps sorted by (value × severity) / estimated effort.

No writes, no commits. Pure reconnaissance.

---

## Phase 0 — Scope

Determine scope from `$ARGUMENTS`:
- **No args / "all":** full audit (all subsystems below)
- **"backend":** agents + core only
- **"frontend":** ui + e2e only
- **"wiring":** API surface cross-check only
- **"tests":** test coverage only
- A specific path: audit just that file or directory

---

## Phase 1 — Parallel Swarm (launch all agents simultaneously)

Spawn these Explore agents in a SINGLE parallel message. Each reads files
and reports findings. Do NOT run them sequentially.

### Agent 1 — Backend H-Scale Collector
**Scans:** `agents/*.py`, `core/*.py`

For each file collect:
1. `@honesty` rating (H1–H5, or "MISSING" if absent)
2. `@limitations` — copy the text verbatim
3. `@upgrade_path` — copy H3→H4, H4→H5 targets
4. Count of `# TODO`, `# FIXME`, `# STUB`, `# PLACEHOLDER` comments
5. Any `pass` or `raise NotImplementedError` in non-test code

Report as: `{ file, honesty, limitations_count, upgrade_targets[], stub_count }`

### Agent 2 — API Surface Cross-Check
**Scans:** `agents/*.py` for `@app.get/@app.post` routes, then
`ui/construction-console/src/api/valorApi.ts` for client calls, then
`tests/smoke_*.py` for smoke coverage.

Build three sets:
- **Backend routes:** `METHOD /path`
- **Frontend calls:** method names → inferred endpoints
- **Smoke-tested:** routes explicitly called in tests

Report:
- Routes with no frontend call (dead backend)
- Frontend calls with no matching route (broken wire)
- Routes with no smoke test (untested path)

### Agent 3 — Frontend Reality Check
**Scans:** `ui/construction-console/src/pages/*.tsx`,
`ui/construction-console/src/components/workstation/*.tsx`

For each page/component look for:
1. Fixture/hardcoded data: `const.*=.*\[` with literal objects, `fixture`,
   `demo`, `seed`, `mock` strings outside test files
2. `console.log` / `console.warn` left in (debug leakage)
3. `// TODO`, `// FIXME`, `// coming soon`, `disabled` buttons with no handler
4. `onClick={() => {}}` or `onClick={() => { /* placeholder */ }}` (no-op actions)
5. `data-testid` missing on interactive controls (per UI_STATE_CONTRACT.md)

Report: `{ file, fixture_count, noop_actions[], todos[] }`

### Agent 4 — Test Coverage Gap Finder
**Scans:** `tests/`, `ui/construction-console/src/__tests__/`,
`e2e/*.spec.ts`

For each backend agent, check if a smoke test file exists:
`tests/smoke_{agent_snake_case}.py`

For each UI page (`pages/*.tsx`), check if an axe test exists in
`src/__tests__/a11y.test.tsx` and a unit test in `__tests__/`.

For each E2E spec, list which workflows are covered vs the full
`END_TO_END_JOURNEYS.md` list (if that file exists).

Report:
- Agents with no smoke test
- Pages with no unit test
- E2E journeys defined but not specced

### Agent 5 — Config / Wiring Completeness
**Scans:** `configs/roles.json`, `configs/agents.json` (or equivalent),
`core/monty_api.py` (routing table), `agents/` (registered endpoints)

Checks:
1. Every role in `roles.json` has a cockpit config in `ui/.../cockpits/`
2. Every agent in `agents.json` is actually running in `run_agents.py`
3. Every agent file has a `/health` endpoint
4. `AGENTS_INDEX.md` is in sync with actual agent files (if it exists)

Report: `{ missing_cockpits[], unregistered_agents[], no_health_endpoint[], index_drift[] }`

---

## Phase 2 — Synthesis

After all 5 agents return, synthesize their findings:

### 2a. Deduplicate
If the same gap appears in multiple agent reports (e.g., Agent 2 finds a
broken wire AND Agent 4 finds no smoke test for the same endpoint), merge
them into one finding and increase its severity one level.

### 2b. Score Each Gap

Score = **Impact × Severity / Effort**

| Dimension | How to score |
|-----------|-------------|
| **Impact** | 3=revenue/safety critical path, 2=daily workflow, 1=edge case |
| **Severity** | 3=broken (H1/no-op/broken wire), 2=stub in prod (H2/fixture fallback), 1=quality gap (missing test/doc) |
| **Effort** | 1=one file one function, 2=multi-file, 3=architectural change |

Score = (Impact × Severity) / Effort. Range ≈ 1–9.

### 2c. Rank and Bucket

**🔴 Must Fix (score ≥ 6)** — Broken wires, H1 stubs serving users, no-op financial actions
**🟠 High Value (score 4–5)** — H2 approximations on critical paths, missing smoke tests for money flows
**🟡 Worth Doing (score 2–3)** — H3→H4 upgrades, fixture fallbacks on non-critical paths, missing a11y tests
**⚪ Backlog (score 1)** — Nice-to-have polish, H4→H5 for non-regulated features

---

## Output Format

```
╔══════════════════════════════════════════════════════════════╗
║  PULSE — System Coherence Audit                              ║
║  Scanned: [N agents] [N core files] [N pages] [N tests]      ║
╚══════════════════════════════════════════════════════════════╝

OVERALL COHERENCE: [H-Scale rating — weakest-link across all axes]

🔴 MUST FIX  ([N] findings)
────────────────────────────
[#]. [Component] — [Gap description]
     Wire:    [broken path description]
     Evidence: [file:line or pattern found]
     Fix:     [concrete 1-line action]
     Score:   [Impact×Severity/Effort]

🟠 HIGH VALUE  ([N] findings)
──────────────────────────────
[same structure]

🟡 WORTH DOING  ([N] findings)
────────────────────────────────
[same structure]

⚪ BACKLOG  ([N] findings — summary only)
──────────────────────────────────────────
[bullet list, no details]

══════════════════════════════════════════
SUBSYSTEM HEAT MAP
══════════════════════════════════════════
Layer           H-Scale  Gaps  Top Issue
──────────────────────────────────────────
Backend Agents   H?       N    [worst gap]
Core Stores      H?       N    [worst gap]
API Surface      H?       N    [worst gap]
UI Pages         H?       N    [worst gap]
Test Coverage    H?       N    [worst gap]
Config/Wiring    H?       N    [worst gap]

══════════════════════════════════════════
RECOMMENDED NEXT SPRINT
══════════════════════════════════════════
If you have 4 hours: [top 3 Must Fix items]
If you have 1 day:   [top 3 + High Value sweep]
If you have 1 week:  [full Must Fix + High Value + start H3→H4 upgrades]
```

---

## Usage Notes

- **Full run takes ~5 minutes** — 5 parallel agents reading hundreds of files.
- **No false precision:** if a gap can't be scored confidently, mark it `?` and explain why.
- **Don't fix during the audit.** The output is a briefing, not a PR. Run `/review` or write a plan after.
- **Scope args:** `/pulse backend` for just agents+core, `/pulse wiring` for just API cross-check,
  `/pulse ui/construction-console/src/pages/PayAppsPage.tsx` for one file.

---

## What Makes This Different From Linters

Linters check syntax. This checks **semantic coherence**:
- Does the UI button actually call a real endpoint that writes to a real table?
- Does the @honesty annotation match what the code actually does?
- Is the fixture fallback there because the live feed isn't wired, or because the live feed is down?
- Is the smoke test calling the real stack or a mock that diverges from prod?

The H-Scale vocabulary is the shared language. Everything gets rated against it.
