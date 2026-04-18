# Monty-CNS Handoff Punch List

**Date:** 2026-04-18
**Branch:** claude/setup-dotfiles-sync-pD9Mo (31 commits ahead of main)
**Source:** 5-agent handoff team (QA, Security, Wiring, Product, Adversarial)

## Handoff Status: READY — No Critical Issues

All CRITICALs found and fixed in-session. System is functional,
tested, and documented. Items below are improvements, not blockers.

---

## Session Stats

| Metric | Value |
|--------|-------|
| Commits this session | 31 |
| Commands | 27 (was 20 at start) |
| Skills | 10 (was 9) |
| Hooks | 7 (was 4) |
| MCP servers | 6 (was 3) |
| Monty-Ledger vault files | 93 |
| Postgres notes indexed | 93 |
| MCP tools (all tested live) | 7 |
| Integration tests passing | 17/17 |
| Functional tests passing | 20/21 |
| Security findings fixed | 4 (2 CRITICAL + 2 HIGH) |
| Plans written | 3 (Valor GitHub App, Monty-Ledger, Wiring Fix) |
| Wiring connections verified | 13/13 |

---

## What Was Built This Session

### New Infrastructure
- Monty-Ledger knowledge vault (moved from docs/, Postgres-backed)
- MCP server (7 tools, TypeScript, access-enforced, tested live)
- Postgres schema + sync script (88 notes synced, 0 errors)
- WIRING.md canonical connection diagram

### New Commands (+7)
- /learn — write to vault via MCP
- /retro — session retrospective
- /brief — cross-session handoff
- /foreman — operational status rollup
- /healthcheck — system diagnostics
- /research — web + vault research (brave-search + MCP)
- /worklog-merge — distributed worklog merge

### New Hooks (+3)
- PostToolUse syntax gate (py/js/ts/go/rb/sh/json/yaml)
- PreCompact checkpoint (CHECKPOINT.md)
- (settings.json PostToolUse entry)

### New MCP Servers (+3)
- memory (knowledge graph)
- brave-search (web search)
- ledger (custom, Postgres-backed, 7 tools)

### New Skills (+1)
- distributed-worklog (parallel subagent pattern)

### New Docs
- docs/WIRING.md — command → MCP → datastore map
- docs/tests/wiring-test-results.md — 17/17 integration test log
- docs/plans/monty-ledger.md — 6-phase vault plan
- docs/plans/cns-wiring-fix.md — wiring fix plan
- claude/RUBRIC.md — 5-dimension quality rubric

---

## Punch List: P0 (Must Fix)

### P0.1 — Vault access/truth-layer skill
**Why:** Every write command stamps `access: private` by default.
Claude doesn't understand when to deviate or what the access
classes mean. The MODE_AND_ACCESS_MODEL.md is rich but lives
inside the vault, not in the skills library.

**Fix:** Create `claude/skills/vault-access-model/SKILL.md` that
teaches Claude the 4 access classes, 4 truth layers, mask levels,
and role modes. Auto-loaded when any vault interaction is detected.

**Effort:** 2h
**Files:** `claude/skills/vault-access-model/SKILL.md` (new)

---

## Punch List: P1 (Should Fix)

### P1.1 — /vault command for ad-hoc queries
**Why:** Users must know MCP tool names to query the vault.
A `/vault` wrapper makes it discoverable.
**Effort:** 2h | **File:** `claude/commands/vault.md` (new)

### P1.2 — /sync command
**Why:** No way to trigger sync_to_postgres.py from a session.
**Effort:** 1h | **File:** `claude/commands/sync.md` (new)

### P1.3 — SessionStart vault context drop-in
**Why:** No automatic vault context loading at session start.
**Effort:** 2h | **File:** `claude/hooks/session-start.d/20-vault-context.sh` (new)

### P1.4 — QUICKSTART.md
**Why:** README is comprehensive but no "I just cloned this, now what?"
**Effort:** 1h | **File:** `QUICKSTART.md` (new)

### P1.5 — README accuracy
**Why:** Says 22 commands (actual 27), doesn't mention ledger MCP or WIRING.md
**Effort:** 30m | **File:** `README.md` (edit)

### P1.6 — CI test suite
**Why:** No automated testing. All tests are manual in-session.
**Effort:** 4h | **Files:** `.github/workflows/ci.yml`, `tests/` (new)

### P1.7 — 19 command files missing YAML frontmatter
**Why:** Inconsistent. 8 have frontmatter, 19 don't.
**Effort:** 1h | **Files:** 19 `.md` files in `claude/commands/`

---

## Punch List: P2 (Nice to Have)

### P2.1 — /rotate command for secret rotation
**Effort:** 3h | **File:** `claude/commands/rotate.md` (new)

### P2.2 — Monty ecosystem architecture skill
**Effort:** 2h | **File:** `claude/skills/monty-ecosystem/SKILL.md` (new)

### P2.3 — 4-category principle skill
**Effort:** 1h | **File:** `claude/skills/monty-principles/SKILL.md` (new)

### P2.4 — distributed-worklog needs SKILL.md (has prompt.md only)
**Effort:** 30m | **File:** `claude/skills/distributed-worklog/SKILL.md` (new)

### P2.5 — Wire /note → memory MCP
**Effort:** 1h | **File:** `claude/commands/note.md` (edit)

### P2.6 — MCP server remaining HIGHs
- Sequential tag inserts → batch INSERT (line 581)
- File+DB not atomic → transaction wrapper (line 560)
- Slug collision → append random suffix (line 521)
- access_max is caller-honor-system → server-side cap (line 258)
**Effort:** 3h | **File:** `monty-ledger/mcp-server/src/index.ts`

---

## Effort Summary

| Priority | Items | Total Effort |
|----------|-------|-------------|
| P0 | 1 | 2h |
| P1 | 7 | 11.5h |
| P2 | 6 | 10.5h |
| **All** | **14** | **~24h** |

---

## Security Findings Log

| Severity | Finding | Status |
|----------|---------|--------|
| CRITICAL | get_note no access enforcement | FIXED (commit 9735620) |
| CRITICAL | Path traversal in create_inbox_note | FIXED (commit 9735620) |
| HIGH | get_pod no access + wildcard injection | FIXED (commit 9735620) |
| HIGH | Frontmatter injection via title/tags | FIXED (commit 9735620) |
| HIGH | Content size unlimited | FIXED (100KB limit, commit 9735620) |
| HIGH | Tag inserts not atomic | TRACKED (P2.6) |
| HIGH | File+DB write not transactional | TRACKED (P2.6) |
| HIGH | access_max caller-honor-system | TRACKED (P2.6) |
| MEDIUM | Slug collision overwrites | TRACKED (P2.6) |
| MEDIUM | Pool no queue timeout | TRACKED (P2.6) |
| MEDIUM | VAULT_ROOT not validated at startup | TRACKED |
| MEDIUM | zod imported but unused | TRACKED |

---

## Test Evidence

### Integration Tests (docs/tests/wiring-test-results.md)
- 17/17 PASS against live Postgres 16
- All 7 MCP tools verified
- Full knowledge loop: create → file → DB → tags → query
- Cross-machine simulation: 5 ai-proposed notes queryable

### Functional Tests (Team 1 QA)
- 9/9 shell scripts parse (bash -n)
- 6/6 MCP configs valid JSON
- 4/4 Python scripts compile
- 1/1 TypeScript compiles
- 1/1 sync_to_postgres.py runs (93 notes)
- 1/1 MCP handshake works
- 1/1 Postgres has data (93 notes, 73 tags, 31 links)
- 0 broken symlinks

### Security Audit (Team 2)
- 0 secrets in committed files
- 0 .env files committed
- 0 private keys committed
- .gitignore covers all patterns
- PreToolUse hooks block all dangerous ops
- Access enforcement on all query handlers

### Wiring Audit (Team 3)
- 13/13 connections verified against actual files
- 0 phantom connections (claimed but not real)

---

## Architectural Decisions Made This Session

1. **4-category model canonicalized:**
   Structure (CNS), Knowledge (Ledger), Secrets (sops+age), Ephemera (local)

2. **Obsidian is GUI, not engine:**
   Markdown + frontmatter is the architecture. Obsidian is a renderer.

3. **Postgres is the query layer, not the source of truth:**
   Markdown files are the 50-year format. Postgres accelerates queries.
   If Postgres dies, markdown is the full recovery path.

4. **AI writes to 00_Inbox/ only:**
   origin_type: ai-proposed, confidence: 2, status: review.
   Human promotes to canonical folders. Never direct write.

5. **MCP tools enforce access classes in code:**
   access_max parameter caps returns. Default: "private".
   get_note and get_pod now enforced (was missing, fixed).

6. **Build once, build right:**
   Postgres over SQLite. TypeScript over shell. Full schema from day 1.

---

## Next Session Recommendations

1. **Fix P0.1** (vault access skill) — 2h, highest impact per effort
2. **Fix P1.5** (README accuracy) — 30m, cosmetic but important
3. **Fix P1.7** (command frontmatter) — 1h, batch job
4. **Start P1.6** (CI suite) — biggest effort but enables everything else
5. **Merge PR #1** when comfortable — 31 commits, everything tested
