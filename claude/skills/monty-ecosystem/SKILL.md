---
name: monty-ecosystem
description: Monty ecosystem architecture — 4 repos, 4 categories, merge semantics, wiring. Use when reasoning about where something belongs, how repos connect, or what tools are available.
---

# Monty Ecosystem Architecture

## Four repos

| Repo | Role |
|---|---|
| **Monty-CNS** | Structure — portable Claude Code config (hooks, commands, skills, MCP defs) |
| **Monty-Ledger** | Knowledge — Obsidian vault + Postgres-backed MCP (learnings, notes, context) |
| **Monty-CNS-Secrets** | Credentials — sops+age encrypted env vars, API keys, file secrets |
| **Valor 2.0** | Platform — the product being built; consumes CNS as its global baseline |

## Four-category principle

Everything in the ecosystem belongs to exactly one category:

1. **Structure** — config, commands, skills, hooks (Monty-CNS, git-tracked)
2. **Knowledge** — learnings, notes, vault entries (Monty-Ledger, git+Postgres)
3. **Ephemera** — sessions, caches, runtime state (local only, never committed)
4. **Secrets** — API keys, tokens, credentials (Monty-CNS-Secrets, encrypted at rest)

## Claude Code merge semantics

Project `.claude/` overrides global `~/.claude/` that CNS manages. Resolution order:
1. Project `.claude/settings.json` composes on top of user `~/.claude/settings.json`
2. Project commands override user commands (by exact filename match)
3. Skills from both scopes are available; project skills take precedence on name collision

## Canonical connection diagram

`docs/WIRING.md` is the single source of truth for how commands, MCP servers, and datastores connect.

## SessionStart flow

`pull` → `bootstrap.sh` → `decrypt sops` → `load .env.local` → `run session-start.d/ drop-ins`

## MCP tools available

- **Monty-Ledger**: 7 tools (Postgres-backed, access-enforced)
- **memory**: knowledge-graph memory (local JSON store)
- **brave-search**: web search (needs API key)
- **filesystem**: local file access
- **github**: GitHub API operations
- **fetch**: HTTP fetching
