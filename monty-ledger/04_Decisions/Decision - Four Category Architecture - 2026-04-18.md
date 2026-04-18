---
type: decision
status: active
created: 2026-04-18
tags: [decision, architecture, vault, categories]
confidence: 4
access: private
truth_layer: working
role_mode: strategist
persona_mix: [strategist, builder]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — Four Category Architecture

## Context

The original principle was "Config yes, State no, Secrets never" — a
3-category model for what to track in version control. This proved too
coarse. Learnings and decisions ARE state but need to sync across
machines, while checkpoints and session logs do not. The distinction
emerged during a session exploring a YouTube research portal and a
thesis on Postgres use cases: some "state" is durable knowledge, some
is throwaway ephemera.

## Options considered

| Option | Description | Problem |
|---|---|---|
| **Keep 3 categories** | Force knowledge into Config or State | Knowledge is not config (it changes) and treating it as excluded state loses it across machines |
| **Split into 4** | Structure, Knowledge, Ephemera, Secrets | Cleanly separates sync-worthy from local-only |
| **Split into 5+** | Add "Plans" as a separate category | Plans are project-specific and belong in project repos, not the personal system |

## The four categories

1. **Structure** — dotfiles, configs, shell setup. Version-controlled,
   symlinked, identical on every machine. (Formerly "Config.")
2. **Knowledge** — decisions, profiles, learnings, writing. Version-
   controlled, synced everywhere. This is the vault.
3. **Ephemera** — session logs, checkpoints, scratch buffers, agent
   working memory. Local only, never committed.
4. **Secrets** — credentials, tokens, private keys. Managed via sops
   or environment injection. Never in plaintext repos.

## Chosen path

**4 categories.** The key insight is that "state" was doing double duty.
Knowledge (what you learned) and Ephemera (what happened during a
session) have opposite sync requirements. Splitting them makes the
mental model precise without adding unnecessary complexity.

## Consequences

- Vault notes (Knowledge) get full git tracking and cross-machine sync
- Agent scratch files (Ephemera) stay in gitignored local directories
- Bootstrap scripts create the ephemeral directories but never populate them
- Plans live in project repos, not here — keeping the CNS personal
