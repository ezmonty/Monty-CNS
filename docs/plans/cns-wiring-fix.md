# CNS Wiring Fix Plan

**Status:** Active
**Origin:** Wiring audit (2026-04-18), 116 tool calls across all 26 commands
**Goal:** Connect all loose wires, activate dead-end MCP tools, test every connection

## Problem Statement

The MCP server has 7 tools, all tested and working against live Postgres.
But only 1 tool (`create_inbox_note`) is referenced by any command, and
even that reference is conditional. 10 dead ends, 6 loose wires, 8
missing connections identified.

## Architecture Constraint

Commands are markdown instruction files — they tell Claude what to do.
They can't "import" or "call" the MCP server directly. Instead, they
instruct Claude to use the MCP tool by name. The wiring is: command
says "use tool X" → Claude sees the tool is available → Claude calls it.

This means "wiring" = editing the command markdown to reference the
MCP tool by name with clear instructions on when and how to use it.

## Phases

### Phase W0 — Fix Broken Wires (3 commands) — ~1h

**W0.1** Fix `/learn` → vault via MCP

Edit `claude/commands/learn.md` to:
- Primary path: call `create_inbox_note` MCP tool with title, content,
  type="learning", tags
- Fallback: if MCP tool not available, write to `~/.claude/LEARNINGS.md`
- Always confirm which path was taken

Test: run `/learn "test insight"` → verify file appears in
`monty-ledger/00_Inbox/` AND row in Postgres notes table

**W0.2** Fix `/brief` vault path detection

Edit `claude/commands/brief.md` to:
- Detect vault location: check `$PWD/monty-ledger/00_Inbox/` first,
  then `~/src/Monty-Ledger/00_Inbox/`, then warn if neither exists
- Match the same detection logic `/foreman` uses
- Use `create_inbox_note` MCP if available instead of direct file write

Test: run `/brief` → verify briefing note appears in vault inbox

**W0.3** Fix `/retro` MCP detection

Edit `claude/commands/retro.md` to:
- Remove "if MCP available" ambiguity — always TRY the MCP tool first
- If MCP call fails, fall back to direct file write
- Each `/learn` call within `/retro` inherits the fix from W0.1

Test: run `/retro` → verify retro note + N learning notes in vault inbox

**Exit criteria:** All 3 commands write to vault via MCP. Fallback to
local file if MCP unavailable. Both paths tested.

**Evidence artifacts:**
- [ ] `monty-ledger/00_Inbox/` contains test notes from /learn
- [ ] `monty-ledger/00_Inbox/` contains test briefing from /brief
- [ ] `monty-ledger/00_Inbox/` contains test retro from /retro
- [ ] Postgres `SELECT * FROM v_inbox` shows all test notes
- [ ] Each note has `origin_type: ai-proposed`, `confidence: 2`

---

### Phase W1 — Activate Dead MCP Tools (5 commands) — ~2h

**W1.1** Wire `/explore` → `search_content` + `build_packet`

Edit `claude/commands/explore.md` to add a step:
"Before exploring, query the vault for related knowledge:
use `search_content` to find related notes, use `build_packet`
if a pod is relevant to the exploration topic."

Test: run `/explore` on a topic that has vault notes → verify
vault context appears in the exploration output

**W1.2** Wire `/debug` → `query_notes`

Edit `claude/commands/debug.md` to add a step:
"Query the vault for similar past issues: use `query_notes`
with tags matching the error type (e.g., 'auth', 'database',
'network'). Check if a prior learning or decision is relevant."

Test: run `/debug` on an auth error → verify vault query for
tag="auth" is attempted

**W1.3** Wire `/review` → `list_profiles` + RUBRIC.md

Edit `claude/commands/review.md` to add a step:
"If RUBRIC.md exists (at repo root or .claude/), walk through
each dimension. If vault MCP is available, load the work
execution profile via `list_profiles` for project conventions."

Test: run `/review` → verify RUBRIC.md is referenced in output

**W1.4** Wire `/brief` → `query_notes` for recent learnings

Edit `claude/commands/brief.md` to add:
"Query recent vault notes via `query_notes(type='learning',
limit=5)` and include a 'Recent Learnings' section in the
briefing."

Test: run `/brief` after `/learn` → verify learnings appear

**W1.5** Wire `/foreman` → `query_notes` for inbox count

Edit `claude/commands/foreman.md` to add:
"If vault MCP available, use `query_notes(path LIKE '00_Inbox/%')`
for inbox count instead of counting files on disk."

Test: run `/foreman` → verify inbox count comes from MCP

**Exit criteria:** All 5 commands reference MCP tools by name.
Each tool is called by at least one command.

**Evidence artifacts:**
- [ ] MCP tool usage matrix: every tool has ≥1 caller
- [ ] `/explore` output includes vault context
- [ ] `/debug` output shows vault query attempt
- [ ] `/review` references RUBRIC.md dimensions
- [ ] `/brief` includes recent learnings section
- [ ] `/foreman` shows inbox count

**Updated tool matrix after W1:**

| Tool | Callers |
|------|---------|
| create_inbox_note | /learn, /retro, /brief |
| query_notes | /debug, /brief, /foreman |
| search_content | /explore |
| build_packet | /explore |
| get_pod | (Valor integration — Phase 4) |
| list_profiles | /review |
| get_note | (general use — available to all) |

---

### Phase W2 — Wire Unused MCP Servers (2 new commands) — ~1h

**W2.1** Create `/research` command → brave-search + memory

New `claude/commands/research.md`:
- Step 1: Query memory MCP for prior research on the topic
- Step 2: Search web via brave-search MCP for current information
- Step 3: Synthesize findings
- Step 4: Save key findings to vault via create_inbox_note
- Step 5: Save to memory MCP for future recall

Test: run `/research "sops age encryption best practices"` →
verify web search results + memory storage + vault note

**W2.2** Wire `/note` → memory MCP

Edit `claude/commands/note.md` to add:
"After writing to NOTES.md, also save to memory MCP if available
(add_observation with project and topic tags). This enables
cross-session note recall."

Test: run `/note "important thing"` → verify memory MCP called

**Exit criteria:** memory and brave-search MCP servers have
at least one command caller each.

**Evidence artifacts:**
- [ ] `/research` produces web search results
- [ ] `/research` saves to memory MCP
- [ ] `/note` saves to memory MCP
- [ ] Memory MCP has stored observations queryable in next session

---

### Phase W3 — Integration Test Suite — ~1h

Run every wired connection end-to-end and produce evidence.

**W3.1** Full knowledge loop test:
```
/learn "JWT RS256 needs full cert chain"
  → verify: vault inbox note created
  → verify: Postgres row with origin_type=ai-proposed
/foreman
  → verify: inbox count shows the new note
/brief
  → verify: recent learnings section includes the JWT insight
/retro
  → verify: retro note created with learnings
```

**W3.2** Exploration integration test:
```
/explore "leadership patterns in the vault"
  → verify: search_content called with "leadership"
  → verify: vault notes included in exploration context
```

**W3.3** Debug integration test:
```
/debug "authentication error in webhook handler"
  → verify: query_notes called with tag="auth"
  → verify: vault decisions/learnings surfaced if relevant
```

**W3.4** MCP health test:
```
For each of the 7 ledger tools:
  Send a JSON-RPC tools/call via stdin
  Verify non-error response
  Record: tool name, input, output snippet, pass/fail
```

**W3.5** Cross-machine simulation:
```
/learn on "machine A" (this session)
  → verify: note in vault + Postgres
Simulate "machine B" by querying Postgres directly:
  SELECT * FROM v_inbox WHERE origin_type = 'ai-proposed'
  → verify: the learning is queryable from any machine
```

**Exit criteria:** All tests pass. Evidence committed to git.

**Evidence artifacts:**
- [ ] `docs/tests/wiring-test-results.md` — full test log with
  inputs, outputs, pass/fail for every connection
- [ ] `monty-ledger/00_Inbox/` contains test artifacts from each phase
- [ ] Postgres query results showing all test notes
- [ ] Screenshot or output capture of /foreman showing correct inbox count

---

### Phase W4 — Documentation & Wiring Diagram — ~30min

**W4.1** Create `docs/WIRING.md` — the canonical wiring diagram

Shows every command → MCP tool → data store connection. Updated
whenever a new command or tool is added. Format:

```
COMMAND        MCP TOOL              DATA STORE
─────────      ─────────────────     ──────────────
/learn      →  create_inbox_note  →  vault + Postgres
/retro      →  create_inbox_note  →  vault + Postgres
/brief      →  create_inbox_note  →  vault + Postgres
            →  query_notes        →  Postgres (read)
/foreman    →  query_notes        →  Postgres (read)
/explore    →  search_content     →  Postgres (read)
            →  build_packet       →  Postgres (read)
/debug      →  query_notes        →  Postgres (read)
/review     →  list_profiles      →  Postgres (read)
/research   →  brave-search       →  web
            →  memory             →  local JSON
            →  create_inbox_note  →  vault + Postgres
/note       →  memory             →  local JSON
```

**W4.2** Update README.md with wiring diagram reference

**W4.3** Add wiring check to healthcheck.sh — verify each
command file contains expected MCP tool references

**Exit criteria:** WIRING.md committed. README references it.
Healthcheck can detect if a wire is missing.

---

## Effort Summary

| Phase | Effort | Files changed | Tests |
|-------|--------|---------------|-------|
| W0 Fix broken wires | 1h | 3 commands | 3 tests |
| W1 Activate dead tools | 2h | 5 commands | 5 tests |
| W2 Wire unused servers | 1h | 2 commands (1 new) | 3 tests |
| W3 Integration tests | 1h | 1 test doc | 5 test suites |
| W4 Documentation | 30min | 3 docs | 1 healthcheck update |
| **Total** | **~5.5h** | **14 files** | **17 tests** |

## What We Deliberately Skip

- Wiring github/filesystem/fetch MCP servers to commands: these are
  general-purpose tools Claude uses implicitly. Explicit wiring adds
  no value.
- get_note and get_pod: these are building blocks for Valor integration
  (Phase 4 of Monty-Ledger plan), not user-facing commands.
- Writing unit tests for the MCP server: the live Postgres tests in W3.4
  are more valuable than mocked unit tests at this scale.
