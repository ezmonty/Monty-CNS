# Monty-Ledger — Phased Implementation Plan

**Status:** Phase 0 complete, Phase 1 ready
**Owner:** Project lead
**Origin:** 5-expert round table (2026-04-17), 2 rounds of cross-examination

## 1. What this is

Monty-Ledger is the personal knowledge vault — profiles, decisions,
evidence units, leadership thinking, writing rules. Markdown files
are the 50-year source of truth. PostgreSQL is the query accelerator
for Valor's 53 agents. If Postgres dies, the markdown is the full
recovery path.

## 2. Architecture

```
monty-ledger/          (git repo, markdown source of truth)
├── 00_Inbox/          AI writes land here (origin_type: ai-proposed)
├── 03_Profiles/       canonical identity notes
├── 04_Decisions/      decision records with confidence scores
├── 05_Leadership/     leadership thinking
├── 08_Knowledge/      evidence units
├── 13_Pods/           context-loading configurations
├── 15_Agent_Prompts/  reusable prompts for agents
├── db/
│   ├── schema.sql     PostgreSQL schema
│   └── seed.sql       views for agent queries
├── scripts/
│   └── sync_to_postgres.py   markdown → Postgres sync
└── mcp-server/        (Phase 2) MCP server backed by Postgres
```

## 3. Design decisions (from round table)

- Markdown + frontmatter is the format. Obsidian is a GUI, not the engine.
- PostgreSQL for queries (Valor uses Postgres, build once build right).
- AI writes to 00_Inbox/ only, origin_type: ai-proposed, human promotes.
- Access enforcement in code (MCP server), not just convention.
- Git-signed commits for tamper evidence.
- Connection string from sops secrets (works local, Neon, or rack).

## 4. Phases

### Phase 0 — Extraction & Scaffold (DONE)

- [x] Move vault from docs/Isen_Obsidian_AI_Pack_v4/ to monty-ledger/
- [x] Write db/schema.sql (notes, tags, links, persona_mix tables)
- [x] Write db/seed.sql (v_profiles, v_decisions, v_evidence, v_inbox, v_pods)
- [x] Write scripts/sync_to_postgres.py (idempotent, hash-based)
- [x] Wire filesystem MCP to include vault path
- [x] Add auto-clone to install.sh (Phase 5)
- [x] EXTRACT_LATER.md with repo-split instructions

**Exit criteria:** vault browsable in Obsidian from monty-ledger/,
Claude Code can read via filesystem MCP, schema ready for Postgres.

### Phase 1 — PostgreSQL Live (~3h)

**Goal:** Vault contents queryable via SQL.

- `ml-1.1` Set up Postgres instance (Neon.tech free tier or local)
- `ml-1.2` Add LEDGER_DATABASE_URL to sops secrets scaffold
- `ml-1.3` Run schema.sql + seed.sql against the instance
- `ml-1.4` Run sync_to_postgres.py — verify all 92 files indexed
- `ml-1.5` Wire sync as git post-commit hook in monty-ledger/
- `ml-1.6` Add 10-decrypt-sops.sh support for LEDGER_DATABASE_URL
- `ml-1.7` Test: query v_profiles, v_decisions, v_evidence from psql

**Exit criteria:** `SELECT * FROM v_profiles WHERE role_mode = 'executive'`
returns the right profile notes. Sync runs automatically on commit.

**Tests:**
- Sync 92 files, verify row count matches file count
- Modify one file, re-sync, verify only that row updated (hash check)
- Delete a file, re-sync, verify orphan cleaned up
- Query by access class, verify secret/hidden notes filtered correctly

### Phase 2 — MCP Server (~6-8h)

**Goal:** Claude Code sessions can query vault knowledge via MCP tools.

- `ml-2.1` Scaffold mcp-server/ (TypeScript, official MCP SDK)
- `ml-2.2` Implement tools:
  - `query_notes(type, tags, access_max, confidence_min, role_mode, limit)`
  - `get_note(path)` — returns full content + frontmatter
  - `search_content(query)` — full-text via pg_trgm
  - `build_packet(question, pod_name, token_budget)` — curated context bundle
  - `get_pod(name)` — returns pod definition with default-load chain
  - `list_profiles()` — all profile notes with summaries
  - `create_inbox_note(title, content, type, tags)` — writes to 00_Inbox/
    with origin_type: ai-proposed, confidence: 2, status: review
- `ml-2.3` Access enforcement: access_max parameter caps what's returned.
  Default: "private". "secret"/"hidden" require explicit opt-in.
- `ml-2.4` Register as claude/mcp/servers/ledger.json in Monty-CNS
- `ml-2.5` LEDGER_DATABASE_URL from env (sops-decrypted at session start)

**Exit criteria:** from any Claude Code session, running
`/learn "JWT RS256 needs full cert chain"` creates a vault inbox note
queryable via `query_notes(type="evidence", tags=["auth"])`.

**Tests:**
- query_notes with type filter returns correct results
- access_max="private" never returns secret/hidden notes
- build_packet respects token budget (truncates, doesn't overflow)
- create_inbox_note stamps origin_type: ai-proposed, confidence: 2
- get_pod resolves default-load chain to actual profile paths

### Phase 3 — CNS Integration (~3h)

**Goal:** CNS commands and hooks use the vault natively.

- `ml-3.1` Update /learn to write via MCP ledger server (create_inbox_note)
- `ml-3.2` Create /retro command — end-of-session retrospective that
  writes structured evidence units to inbox via MCP
- `ml-3.3` SessionStart drop-in (20-vault-context.sh) — detects project
  from git remote, loads matching pod context if available
- `ml-3.4` Update /brief to query recent decisions and learnings from
  vault when generating cross-session handoffs
- `ml-3.5` Add LEDGER_DATABASE_URL to env.sops.yaml.example

**Exit criteria:** /learn and /retro produce vault notes. SessionStart
loads relevant context automatically.

### Phase 4 — Valor Integration (~4-6h)

**Goal:** Valor's 53 agents have vault intelligence.

- `ml-4.1` Create VaultContextAgent in Valor (new agent, system_builders pod)
- `ml-4.2` VaultContextAgent queries Postgres directly for:
  - Pod resolution (load profiles by pod name)
  - Evidence retrieval (by topic, confidence, role)
  - Decision lookup (by project, status, date range)
- `ml-4.3` Other agents request context via MontyClient.ask():
  ```python
  MontyClient.ask(
      target_agent="VaultContextAgent",
      payload={"command": "load_context", "pod": "Executive Negotiation"}
  )
  ```
- `ml-4.4` Build_packet as a Valor command — any agent can request a
  curated knowledge packet scoped to a question
- `ml-4.5` Wire GitHubWebhookAgent (from the GitHub App plan) to load
  work execution profile before generating PR reviews

**Exit criteria:** a Valor agent can request "executive negotiation context"
and receive the right profiles, tone controls, and evidence.

### Phase 5 — Hardening & Legal Foundation (~2-3h)

**Goal:** Tamper-evident history, health monitoring, backup.

- `ml-5.1` Enable git commit signing on vault repo
- `ml-5.2` OpenTimestamps post-commit hook (ots stamp)
- `ml-5.3` Health check script — verify Postgres in sync with markdown
  (compare note count, spot-check 10 random hashes)
- `ml-5.4` pg_dump backup to encrypted file (sops-encrypted, stored on NAS)
- `ml-5.5` Document the "crypto DNA" properties in a vault decision note

**Exit criteria:** every vault commit is signed + externally timestamped.
Health check passes. Backup verified restorable.

## 5. What we deliberately deferred

| Item | Why deferred | Revisit when |
|------|-------------|--------------|
| DID:web identity anchor | No counterparty needs verifiable credentials | Someone asks |
| Merkle selective disclosure | Solution looking for a lawsuit | Legal situation arises |
| Per-access-class encryption (4 age keys) | One person, one trust boundary | Rack ships + key ceremony |
| Hidden lane as separate encrypted repo | No hidden-lane content exists yet | Content requires it |
| SQLite/JSON index | Postgres is the index; we built right | Never (Postgres is the answer) |
| Custom Obsidian plugins | Obsidian is GUI, not engine | Proven friction after 1 month |

## 6. Risks

- **Postgres availability.** If the instance goes down, the MCP server
  and Valor agents lose query access. Markdown files still work via
  filesystem MCP (degraded but functional). Mitigation: health check
  alerts, pg_dump backups.
- **Sync drift.** If someone edits markdown but sync doesn't run, Postgres
  is stale. Mitigation: post-commit hook + health check that compares
  file count and random hashes.
- **AI write quality.** AI-proposed inbox notes may be low quality.
  Mitigation: confidence: 2, status: review, human promotion required.
- **Schema migration.** As the vault evolves, the Postgres schema may need
  columns. Mitigation: frontmatter JSONB column holds everything; typed
  columns are query accelerators, not the source of truth.

## 7. Effort summary

| Phase | Effort | Dependencies |
|-------|--------|-------------|
| 0 Extraction | DONE | — |
| 1 Postgres live | 3h | Postgres instance |
| 2 MCP server | 6-8h | Phase 1 |
| 3 CNS integration | 3h | Phase 2 |
| 4 Valor integration | 4-6h | Phase 2 + Valor repo access |
| 5 Hardening | 2-3h | Phase 1 |
| **Total** | **~20h** | |
