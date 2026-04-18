# CNS Wiring Diagram

How every command, hook, MCP tool, and data store connects.
Update this when adding new commands or tools.

## Command → MCP Tool → Data Store

```
COMMAND         MCP TOOL              DATA STORE          STATUS
──────────      ──────────────────    ──────────────      ──────
/learn       →  create_inbox_note  →  vault + Postgres    WIRED
/retro       →  create_inbox_note  →  vault + Postgres    WIRED
             →  (calls /learn)     →  (inherits)
/brief       →  create_inbox_note  →  vault + Postgres    WIRED
             →  query_notes        →  Postgres (read)     WIRED
/foreman     →  query_notes        →  Postgres (read)     WIRED
/explore     →  search_content     →  Postgres (read)     WIRED
             →  build_packet       →  Postgres (read)     WIRED
/debug       →  query_notes        →  Postgres (read)     WIRED
/review      →  list_profiles      →  Postgres (read)     WIRED
/research    →  brave_web_search   →  web                 WIRED
             →  search_content     →  Postgres (read)     WIRED
             →  query_notes        →  Postgres (read)     WIRED
             →  create_inbox_note  →  vault + Postgres    WIRED
```

## Hook → Script → Effect

```
HOOK            SCRIPT                          EFFECT
──────────      ──────────────────────────      ──────────────────────
SessionStart →  session-start.sh             →  git pull, bootstrap, load env
             →  session-start.d/10-decrypt   →  sops decrypt → $CLAUDE_ENV_FILE
PreToolUse   →  (inline in settings.json)    →  block secrets writes + destructive bash
PostToolUse  →  post-tool-syntax-check.sh    →  py_compile/node --check/bash -n/etc
PreCompact   →  pre-compact-checkpoint.sh    →  write CHECKPOINT.md
Stop         →  stop-hook-git-check.sh       →  nag about uncommitted work
```

## MCP Tool Coverage

```
TOOL                  CALLERS                     STATUS
──────────────────    ────────────────────────    ──────
create_inbox_note     /learn, /retro, /brief,     ✓ 4 callers
                      /research
query_notes           /debug, /brief, /foreman,   ✓ 4 callers
                      /research
search_content        /explore, /research         ✓ 2 callers
build_packet          /explore                    ✓ 1 caller
list_profiles         /review                     ✓ 1 caller
get_note              (general use)               ✓ available
get_pod               (Valor integration)         ✓ available
```

## MCP Server Coverage

```
SERVER          CALLERS                STATUS
──────────      ─────────────────     ──────
ledger          /learn, /retro, etc   ✓ primary knowledge interface
brave-search    /research             ✓ web search
memory          (available)           ○ no explicit caller yet
github          (implicit)            ○ used by Claude Code directly
filesystem      (implicit)            ○ used by Claude Code directly
fetch           (implicit)            ○ used by Claude Code directly
```

## Data Flow: /learn → queryable knowledge

```
User: /learn "insight"
  → Claude calls create_inbox_note MCP tool
    → MCP server writes markdown to monty-ledger/00_Inbox/
    → MCP server INSERTs into Postgres notes table
      → Row has: origin_type=ai-proposed, confidence=2, status=review
  → User runs /foreman
    → query_notes reads inbox count from Postgres
  → User runs /brief
    → query_notes reads recent learnings from Postgres
  → Next session on ANY machine
    → Postgres has the data (if shared instance)
    → OR sync_to_postgres.py re-indexes from markdown files
```

## Fallback Chain

Every vault-writing command uses this fallback:

```
1. Try create_inbox_note MCP tool (best: file + Postgres)
2. Direct file write to monty-ledger/00_Inbox/ (good: file only)
3. Write to ~/.claude/LEARNINGS.md (last resort: local only)
```
