---
title: "Docs to vault bridge — which repo docs belong in vault vs stay in repo"
type: decision
origin_type: ai-assisted
confidence: 3
status: active
access: private
truth_layer: canonical
role_mode: strategist
created: 2026-05-01
tags: ["strategy", "operations"]
---

# Decision — Docs to Vault Bridge

## Context

Valor 2.0 has a rich docs folder (~100 files) with design decisions,
invariants, blueprints, canon declarations, governance rules, and
technical specs. The vault (Monty-Ledger) has 04_Decisions/ and
08_Knowledge/ for persistent knowledge. The question: what belongs where,
and how do sessions know which to load?

The goal is "Monty knows how to build Monty" — a session doing builder
work should not need to read 420 lines of max_monty_invariants.md every
time. But copying docs into the vault creates two sources of truth that
will drift.

## The rule

**Bridge by type, link to source, never duplicate spec content.**

| Document type | Where it lives | Vault treatment |
|---|---|---|
| Design decisions — *why* we chose X over Y | Repo (canonical) | Vault decision note summarizes the choice + rationale, links to source |
| Invariants — *what must never break* | Repo (canonical) | Vault knowledge note with category summaries + link; no spec fields |
| Architecture blueprints — *how it's structured* | Repo (canonical) | Vault knowledge note with key patterns + link |
| Builder philosophy — *how we think about building* | Both | Vault is authoritative for the thinking; repo doc links to vault |
| Technical specs — field names, port numbers, API contracts | Repo only | Never in vault; too volatile, wrong abstraction level |
| Runbooks — step-by-step operational procedures | Repo only | Never in vault |
| H-Scale reports | Repo (historical) | Not in vault; ratings are point-in-time artifacts |

## Chosen path

### For invariants
Create `Knowledge - System Invariants.md` in `08_Knowledge/` that:
- Lists the 10 invariant categories with one-sentence summaries
- Links to `docs/monty_core_docs_savepack/max_monty_invariants.md`
- Is the thing a builder session loads — not the full doc

### For canon decisions already in the repo
Key decisions in `docs/m2codex/` (DOCS_GOVERNANCE.md tiers, CANON.md
authority hierarchy) are already in decision format in the repo.
They should have mirror decision notes in `04_Decisions/` with the
rationale captured — not the full spec, just the choice and why.

### For builder philosophy
The "build the builder" philosophy (agent-based, local-first, MontyCore
as single router, LLM access only through LLMToolAgent) belongs in
the vault as a Pod (Pod - Builder Knowledge) that loads the right
notes for a builder session.

### What does NOT bridge
- Port assignments (repo only — changes frequently)
- API field names (repo only — Pydantic models are the truth)
- Runbooks (repo only — operational, not knowledge)
- H-Scale reports (repo only — historical artifacts)

## The drift problem

If a vault note links to a repo doc and that doc changes, the vault
note may become stale. Mitigations:
1. Vault notes should summarize the *decision* (which is stable) not
   the *specification* (which changes). "We use MontyCore as single
   router" won't change. Field names will.
2. Vault notes should include the repo path so they can be checked.
3. /pulse or periodic review should flag vault notes that reference
   repo docs that have changed significantly.

## References

- `docs/m2codex/DOCS_GOVERNANCE.md` — doc tier system (Tier 0-4)
- `docs/m2codex/CANON.md` — authority hierarchy for conflicting docs
- `docs/monty_core_docs_savepack/max_monty_invariants.md` — the invariants doc
- [[Pod - Builder Knowledge]] — the context bundle this decision enables
