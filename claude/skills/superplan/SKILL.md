---
name: superplan
description: >
  Full-stack execution planning for any goal. Spawns a Council of parallel
  planning agents (one per department), synthesizes into a phased plan
  with worklog tracking, cross-department gates, adversarial review, build/
  test/deploy/smoke checkpoints, and milestone todos. When given "go", 
  launches the execution swarm. Imitates a real engineering org:
  PM → Backend → Frontend → QA → Security → DevOps → Product sign-off.
---

# /superplan — Department-Orchestrated Execution Machine

**Modes:**
- `/superplan [goal]`               → Generate plan + wait for `go`
- `/superplan go`                   → Execute the current plan (must run generate first)
- `/superplan status`               → Report milestone completion from worklog
- `/superplan [goal] --execute`     → Generate + execute immediately (no confirmation)

---

## STEP 0 — Parse Goal and Read Context

From `$ARGUMENTS`, extract:
- **Goal:** what outcome to achieve
- **Scope hint:** if "backend only", "frontend only", "tests only" — narrow streams
- **Flag:** `--execute` means skip confirmation and go immediately

Before planning, gather intel in parallel (3 bash calls):
```bash
# Current state
git log --oneline -10
git diff --stat HEAD~5 HEAD
```
```bash
# Last pulse findings (if available)
cat /tmp/valor-pulse-last.md 2>/dev/null | head -60 || echo "No pulse cache"
```
```bash
# Open todos / plan context
cat docs/m2codex/WORKLOG.md 2>/dev/null | tail -40 || \
cat worklog/agent-*.md 2>/dev/null | tail -40 || echo "No worklog found"
```

---

## STEP 1 — Council of Plans (Parallel Agent Swarm)

Spawn **6 planning agents in one parallel message**. Each returns a structured
department plan in ≤ 400 words. Do NOT wait for one to return before launching
others.

---

### COUNCIL AGENT A — Project Management / PM Office
**You are the PM.** Read the goal and current codebase state. Produce:
1. **Milestone list** — 4-8 named milestones with clear done criteria (binary: pass/fail)
2. **Phase sequence** — which phases can run in parallel vs must be sequential
3. **Risk register** — top 3 risks with mitigation
4. **Definition of Done** — the exact state the system must be in for the goal to be "complete"
5. **Worklog commit points** — after each phase, what gets committed to WORKLOG.md

Format:
```
PM PLAN
───────
Milestones:
  M1. [name] — DONE WHEN: [exact binary condition]
  M2. [name] — DONE WHEN: [exact binary condition]
  ...

Phase Sequence:
  Phase 1 (parallel): [streams]
  Phase 2 (gate): [condition]
  Phase 3 (parallel): [streams]
  ...

Top Risks:
  R1. [risk] — Mitigation: [action]

Definition of Done:
  [Complete list of conditions, each binary]
```

---

### COUNCIL AGENT B — Backend Engineering
**You are the Backend Tech Lead.** Read the goal. Produce:
1. **Files to create/modify** — exact paths, what changes
2. **API contracts** — new endpoints, changed signatures, payload shapes
3. **Database changes** — new columns, new tables, migration needed?
4. **Parallelizable tasks** — which backend tasks can run simultaneously
5. **Test hooks** — what smoke tests need to be updated/created

Format:
```
BACKEND PLAN
────────────
Stream B1 (parallel with B2):
  Files: [list]
  Change: [what]
  Test hook: [smoke file to update]

Stream B2 (parallel with B1):
  Files: [list]
  Change: [what]

Sequential after B1+B2:
  Migration: [yes/no — specify]
  API surface change: [yes/no — specify]
```

---

### COUNCIL AGENT C — Frontend Engineering
**You are the Frontend Tech Lead.** Read the goal. Produce:
1. **Components/pages to create or modify** — exact paths
2. **Type system changes** — additions to api.ts or other type files
3. **State management** — appStore changes needed?
4. **Parallelizable tasks** — which frontend tasks can run simultaneously
5. **a11y requirements** — what new controls need aria-labels, data-testids

Format:
```
FRONTEND PLAN
─────────────
Stream F1 (parallel with F2):
  Files: [list]
  Change: [what]
  a11y: [new aria-labels or data-testids required]

Stream F2 (parallel with F1):
  Files: [list]
  Change: [what]

Type changes: [list additions to api.ts]
Store changes: [list additions to appStore.ts]
```

---

### COUNCIL AGENT D — QA Engineering
**You are the QA Lead.** Read the goal and identify what must be tested. Produce:
1. **Unit tests** — which Vitest/RTL test files to create or extend
2. **Smoke tests** — which pytest smoke files to create or extend (HTTP calls, not unit)
3. **E2E tests** — which Playwright spec files to create or extend
4. **Axe a11y tests** — any new pages that need axe coverage in a11y.test.tsx
5. **Test sequence** — order tests must run (some depend on previous passing)
6. **Coverage gates** — what must pass before deployment is allowed

Format:
```
QA PLAN
───────
Unit tests (run after each stream):
  New: [file → test cases]
  Extend: [file → add cases]

Smoke tests (HTTP, run after deploy):
  New: [file → endpoints to verify]

E2E tests (run against live):
  New: [file → user flows]

Gates:
  After Phase 1: [npm run test] must pass
  After Phase 3: [pytest tests/smoke_*.py] must pass
  After Deploy: [npx playwright test] must pass
```

---

### COUNCIL AGENT E — Security / Adversarial Review
**You are the Security Lead.** Read the goal and the changed surface area. Produce:
1. **Attack surface** — what new attack surface the goal creates
2. **OWASP checks** — which OWASP Top 10 apply to this change
3. **Role/RBAC review** — any new role checks needed?
4. **Input validation** — any new user inputs that need validation?
5. **Review triggers** — which files MUST go through /adversarial-reviewer
6. **Sign-off condition** — what Security requires before declaring done

Format:
```
SECURITY PLAN
─────────────
New attack surface: [list]
OWASP risks: [list applicable categories]
Mandatory adversarial review: [file list]
RBAC check required: [yes/no — which roles]
Input validation needed: [list fields]
Security sign-off condition: [exact criteria]
```

---

### COUNCIL AGENT F — DevOps / Platform
**You are the DevOps Lead.** Read the goal. Produce:
1. **Build sequence** — exact commands in order (tsc, npm run build, pytest, etc.)
2. **Deploy sequence** — git push → valor-vm pull → build → restart sequence
3. **Smoke verification** — which /smoke checks apply post-deploy
4. **Rollback plan** — if something fails post-deploy, what to do
5. **Verification marker** — what marks this as "live verified"

Format:
```
DEVOPS PLAN
───────────
Build gate (run locally first):
  1. [command]
  2. [command]

Deploy sequence:
  1. git push origin main
  2. ssh valor-vm "cd ~/valor2.0 && git pull --ff-only"
  3. ssh valor-vm "cd ui/construction-console && npm run build"
  4. [any agent restart commands]

Smoke checks (post-deploy):
  /smoke checks that apply: [list]
  Additional: [any manual checks]

Rollback:
  [git revert command or procedure]

Verified when: touch /tmp/valor-live-verified
```

---

## STEP 2 — Synthesis: The Master Plan

After all 6 council agents return, synthesize into **THE MASTER PLAN**:

### Format

```
╔═══════════════════════════════════════════════════════════════════╗
║  SUPERPLAN: [Goal]                                                ║
║  Generated: [date]  ·  Est. total: [time range]                  ║
║  H-Scale target: [current → target]                              ║
╚═══════════════════════════════════════════════════════════════════╝

DEFINITION OF DONE
──────────────────
[ ] [Condition 1 — binary]
[ ] [Condition 2 — binary]
[ ] [Condition N — binary]
(Copy from PM plan — these are the acceptance criteria)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 0 — INTEL [~15 min, sequential, do first]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: PM
Agent type: general-purpose

Tasks:
[ ] Run /pulse [scope] to baseline current state
[ ] Capture H-Scale ratings for each affected subsystem
[ ] Save pulse snapshot to /tmp/valor-pulse-last.md

Gate: Pulse complete + baseline recorded
Worklog: "Phase 0 complete — baseline: [H-Scale summary]"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 — PARALLEL IMPLEMENTATION [~Xhr, max parallelism]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: Engineering (Backend + Frontend)
Agent type: general-purpose (worktree isolation recommended for conflicts)
Parallelism: [N] simultaneous agents

Stream B1 — [Backend task name]
  Owner: Backend Engineering
  Files: [list]
  Prompt template: "Implement [task]. Files: [list]. 
    Follow patterns in [reference file]. 
    Write to worklog/agent-B1-[date].md on completion."
  Done when: [specific binary condition]
  
Stream B2 — [Backend task name]
  [same structure]

Stream F1 — [Frontend task name]
  Owner: Frontend Engineering
  Files: [list]
  [same structure]

Stream F2 — [Frontend task name]
  [same structure]

⚠ CONFLICT RISK: [list any files that 2+ streams might touch]
  Resolution: [stream owns the file, others read-only]

Gate to Phase 2:
  ALL streams complete their worklog entries
  npm run build → 0 TypeScript errors
  Worklog: Merge all worklog/agent-*.md → WORKLOG.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2 — PARALLEL REVIEW GATE [~30 min]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: Security + QA
Agent type: adversarial-reviewer (security), general-purpose (QA)
Parallelism: 2 simultaneous review agents

Review A — /adversarial-reviewer (mandatory files from Security plan)
  Personas: Saboteur, New Hire, Security Auditor
  Must exit CLEAN or CONCERNS (no BLOCK)
  Fix all CRITICAL and WARNING findings before proceeding

Review B — /h-scale [modified components]
  Rate each touched subsystem on all 4 axes
  Any axis below target H-Scale → document why or fix

Gate to Phase 3:
  /adversarial-reviewer verdict: not BLOCK
  All CRITICAL findings resolved
  H-Scale delta documented
  Worklog: "Phase 2 gate: [verdict], [N] findings, [N] fixed"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3 — PARALLEL TEST IMPLEMENTATION [~Xhr]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: QA Engineering
Agent type: general-purpose
Parallelism: 3 simultaneous test agents

Test Stream T1 — Unit / Vitest
  Files: [from QA plan]
  Run after each file: npm run test -- [file]
  Must pass before declaring T1 done

Test Stream T2 — Smoke / pytest (HTTP)
  Files: [from QA plan]
  Run after each file: pytest [file] -v
  Must pass before declaring T2 done

Test Stream T3 — Axe a11y
  Update src/__tests__/a11y.test.tsx with new pages
  Run: npm run test -- a11y
  Must pass before declaring T3 done

Gate to Phase 4:
  npm run test → ALL [N] tests pass (131 + new)
  pytest tests/smoke_*.py → ALL pass
  npm run build → still clean
  Worklog: "Phase 3 gate: [N] unit, [N] smoke, [N] axe — all pass"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 4 — BUILD + COMMIT GATE [~15 min, sequential]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: DevOps
Commands (run in order, each must pass before next):

[ ] npm run build          → 0 errors, 0 TS warnings
[ ] npm run test           → all pass
[ ] pytest tests/smoke_*.py → all pass
[ ] git add [changed files only — never git add -A]
[ ] git commit -m "[conventional commit message]
    
    Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
[ ] git push origin main

Gate to Phase 5:
  All commands exit 0
  Push confirmed
  Worklog: "Phase 4 gate: build clean, tests pass, pushed [SHA]"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 5 — DEPLOY + SMOKE [~15 min, sequential]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: DevOps
Agent type: general-purpose

Deploy sequence:
[ ] ssh valor-vm "cd ~/valor2.0 && git pull --ff-only"
[ ] ssh valor-vm "cd ui/construction-console && npm install --silent && npm run build"
[ ] [any agent restart: systemctl restart / pkill + relaunch]

Smoke verification (/smoke — report actual values, not "it worked"):
[ ] title check: curl -s https://api.remedy-reconstruction.com/ | grep title
[ ] cache-control: curl -sI https://api.remedy-reconstruction.com/ | grep -i cache
[ ] bundle content-type + immutable
[ ] [goal-specific smoke: list exact checks for new functionality]
[ ] Backend smoke: pytest tests/smoke_*.py -q (if agents changed)

Gate to Phase 6:
  All smoke checks return expected values
  touch /tmp/valor-live-verified
  Worklog: "Phase 5 gate: deployed [SHA], smoke ✓"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 6 — E2E + LIVE BEHAVIORAL VERIFICATION [~30 min]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: QA + Product
Agent type: general-purpose (runs Playwright against live)

[ ] npx playwright test e2e/[relevant-spec].spec.ts --project=chromium
[ ] Verify new E2E specs from Phase 3 pass against live
[ ] Manually verify golden path: [describe the 3-click user journey that
    proves the goal is achieved from a user perspective]
[ ] Check browser console for errors (no new console.error in prod)

Gate to Phase 7:
  All Playwright specs pass
  Golden path verified
  No new console errors in browser
  Worklog: "Phase 6 gate: E2E pass, golden path ✓, product accepted"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 7 — SIGN-OFF + DELTA PULSE [~15 min, sequential]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Department: PM + QA
Agent type: general-purpose

[ ] Run /pulse [same scope as Phase 0] — capture after-state
[ ] Compare before/after H-Scale ratings — document delta
[ ] Tick off each Definition of Done item — all must be checked
[ ] Merge all worklog/agent-*.md → WORKLOG.md via /worklog-merge
[ ] Write final WORKLOG.md entry:
    "SUPERPLAN COMPLETE: [goal]
     H-Scale: [before] → [after]
     Phases: [N completed]  Tests: [N new]  Files: [N changed]
     Definition of Done: [N/N checked]"
[ ] Close plan: rm worklog/agent-*.md (scratch files)

PLAN COMPLETE — All milestones closed.
```

---

## EXECUTION MODE — When User Says "go"

When the user approves ("go", "execute", "launch it"), spawn the execution
agents. Follow this parallelism map exactly:

### Phase 0 (run first, sequential):
Single `general-purpose` agent that runs /pulse and captures baseline.

### Phase 1 (max parallelism):
Spawn all backend + frontend streams in ONE parallel message.
Each agent:
- Gets its stream prompt (files, task, done criteria)
- Is told: "Write your completion summary to worklog/agent-[stream].md"
- Uses `isolation: "worktree"` if touching shared files

### Phase 2 (parallel, after Phase 1 complete):
Spawn 2 agents simultaneously:
- Agent R1: `/adversarial-reviewer` on changed files
- Agent R2: `/h-scale` on modified components

After both return: synthesize findings, fix any BLOCK verdicts before Phase 3.

### Phase 3 (parallel, after Phase 2 gate):
Spawn 3 test agents simultaneously:
- Agent T1: unit/vitest tests
- Agent T2: smoke/pytest tests  
- Agent T3: axe a11y tests

### Phase 4 (sequential, after Phase 3 complete):
Single `general-purpose` agent runs build + commit + push sequence.

### Phase 5 (sequential, after Phase 4):
Single `general-purpose` agent deploys + runs /smoke.

### Phase 6 (after Phase 5):
Single `general-purpose` agent runs Playwright + golden path verification.

### Phase 7 (final, sequential):
Single `general-purpose` agent runs /pulse delta + worklog merge + sign-off.

---

## GATE ENFORCEMENT

Each gate is a hard stop. If a gate fails:
1. Report EXACTLY what failed (command + output)
2. Fix the failure before proceeding (do not skip)
3. Re-run the gate
4. Only proceed when gate exits clean

**Never skip a gate.** If something can't be fixed, escalate to user before
proceeding. A failed gate is better than a broken production system.

---

## WORKLOG FORMAT

Every agent writes to its own scratch file:
```
worklog/agent-[stream]-[date].md
```

Entry format:
```markdown
## [ISO timestamp] -- agent-[stream] -- [phase name]

Status: [in_progress | complete | blocked]
Phase: [phase number]
Department: [Backend|Frontend|QA|Security|DevOps|PM]
Files changed: [list]
Tests added: [list]  
Gate result: [pass | fail | pending]
Notes: [anything non-obvious]
Blockers: [if status=blocked, what and who needs to unblock]
```

Final merge via `/worklog-merge` at Phase 7.

---

## RUBRIC — Plan Quality Check

Before handing the plan to the user for approval, self-check:

| Criterion | Check |
|-----------|-------|
| Every phase has a binary gate condition | ✓ / ✗ |
| Every stream has explicit file list | ✓ / ✗ |
| Every gate has exact command to run | ✓ / ✗ |
| /adversarial-reviewer is in Phase 2 | ✓ / ✗ |
| /smoke is in Phase 5 | ✓ / ✗ |
| /pulse is in Phase 0 and Phase 7 | ✓ / ✗ |
| Definition of Done is all binary | ✓ / ✗ |
| No stream has >4 hours of work (split if so) | ✓ / ✗ |
| Conflict files are explicitly assigned to one stream | ✓ / ✗ |
| Worklog entries defined for every phase | ✓ / ✗ |

If any row is ✗, fix the plan before presenting it.

---

## SCOPE SHORTCUTS

When goal matches these patterns, pre-wire the streams:

| Goal pattern | Suggested streams |
|--------------|-------------------|
| "add [feature]" | B1:API, B2:store, F1:page, F2:types, T1:unit, T2:smoke, T3:axe |
| "fix [bug]" | B1:fix, F1:fix (if UI), T1:regression test, skip F2/B2 |
| "H3→H4 [component]" | B1:methodology fix, T1:unit, T2:HTTP smoke, Review:adversarial |
| "add smoke tests" | T2:smoke only, skip B/F streams, heavy T2 parallelism |
| "wiring [gap]" | B1:backend route, F1:frontend call, T2:HTTP smoke |
| "refactor [component]" | B1:refactor, T1:regression, Review:adversarial, skip F/T3 |

---

## EXAMPLE INVOCATION

```
/superplan close the financial HTTP smoke gap identified in /pulse

→ Council generates plan:
  Stream B1: Update smoke_financial_http.py — 15 endpoints
  Stream B2: Fix valorApi.ts absolute-path bugs (2 lines)
  Stream F1: (none — no UI changes)
  Stream T2: Wire new smoke file to pytest suite
  Review: adversarial-reviewer on valorApi.ts changes
  Deploy: smoke + pytest smoke_financial_http.py

→ User reviews plan, says "go"
→ 4 agents launch simultaneously
→ Gates enforce quality at each phase
→ Plan closes with /pulse delta showing API Surface H2 → H3
```
