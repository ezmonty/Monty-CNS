---
type: decision
status: active
created: 2026-04-18
tags: [decision, infrastructure, postgres, database]
confidence: 4
access: private
truth_layer: working
role_mode: builder
persona_mix: [builder, strategist]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — Postgres Over SQLite for Vault Index

## Context

The vault MCP server needs a queryable index of all markdown notes —
frontmatter, content, tags. Two realistic options: SQLite (zero
infrastructure, embedded) or Postgres (requires a running server).

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **SQLite** | Zero infrastructure, single file, embedded | No network access (agents on different machines can't query it), no concurrent writers, weaker full-text search |
| **Postgres** | Full-text via pg_trgm, JSONB for frontmatter queries, concurrent access, network-accessible | Requires running server, more infrastructure to maintain |

## Reasoning

1. **Valor already uses Postgres for everything** — same connection
   patterns, same tooling, same mental model. No new technology.
2. **pg_trgm for similarity search** — `similarity()` gives fuzzy
   full-text matching out of the box, which powers `search_content`.
3. **JSONB for frontmatter** — structured queries against metadata
   without a separate schema migration for each new field.
4. **Scales to 100k+ notes** without redesign or performance cliffs.
5. **Network-accessible** — multiple agents on different machines can
   query the same index concurrently.

## Chosen path

**Postgres.** Accept the infrastructure cost now to avoid a migration
later. "Build once, build right" — SQLite would be simpler today but
would hit walls (no network, no concurrency) within months.

## Tradeoffs accepted

- Requires a running Postgres instance (managed via existing infra)
- Connection string management via environment variables / sops
- Slightly more complex local development setup
