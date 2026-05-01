---
title: "Monty knowledge capture architecture — design thesis"
type: design
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["strategy", "operations"]
---

# Monty knowledge capture architecture — design thesis

**Seeded from:** live design session, 2026-05-01, shanu + Claude
**Promote to:** `04_Decisions/` or `06_Writing/` after review
**Purpose:** working design doc — not a polished paper yet, but captures the core decisions and open questions before they dissolve

---

## The core insight

The vault was built for two different purposes that look similar but aren't:

1. **Operational learnings** — debug patterns, gotchas, tool quirks, smoke test findings. Captured with `/learn`. Short-lived relevance. Example: "axios discards baseURL for absolute paths."

2. **Architectural thesis** — fundamental decisions that shape the whole project's design. White paper–level positions. Example: "Monty uses agents not microservices because..." or "the financial approval state machine is designed this way because..." These are load-bearing: future Claude sessions, future contributors, and future-Shanu need to find and understand these.

These are not the same. Operational learnings decay. Architectural thesis documents compound — they make every future decision faster and better-grounded.

---

## The PARA flow (and why we were overcomplicating it)

PARA already answers the routing question:

```
Everything → 00_Inbox (universal landing zone)
     ↓
/retro or manual review
     ↓
Operational learning → stays in 00_Inbox or 12_Audit
Architectural decision → promotes to 04_Decisions/
Design thesis / white paper → promotes to 06_Writing/ or 13_Pods/
```

The `/learn` command doesn't need a `--decision` flag. The inbox IS the sorting mechanism. The promotion step (retro, review, manual) is where classification happens. Adding routing complexity to `/learn` works against PARA's own model.

The right fix is: **trust the inbox → sort step**. Make `/retro` prompt for promotion explicitly.

---

## What belongs in 04_Decisions

A decision note is not a learning. It answers:
- What was the choice?
- What options were considered?
- Why this one?
- What would change the decision?

These should be created directly as decision notes (not via `/learn`) when:
- A fundamental architecture call is made (agent model, data model, auth model)
- A design direction is chosen after real debate (push-back, alternatives weighed)
- A project thesis is established (what Monty is, what Valor is, what the boundary is)

Format: `YYYY-MM-DD_short-title.md`, `type: decision`, `truth_layer: canonical`, `status: active`

---

## The "builder knowledge" thesis

One of the most valuable things the vault can accumulate is **builder knowledge for Monty itself** — not project knowledge (what Valor does) but system knowledge (how Claude sessions, the agent architecture, prompt design, debug patterns, and tool chains actually work together).

This is different from project docs:
- It's about the *meta-system* (how we build)
- It compounds across all projects, not just Valor
- It's what makes future Claude sessions smarter about Monty's patterns without needing to re-discover them

This category probably deserves its own pod or area: something like `13_Pods/builder-knowledge/` or a dedicated `BUILDER.md` in Monty-CNS.

---

## The LEARNINGS.md fallback problem

When vault is unreachable, `/learn` writes to `~/.claude/LEARNINGS.md`. This is a dead end — nothing promotes those entries when the vault comes back. Two options:

1. **Manual**: `/retro` should check for LEARNINGS.md backlog and surface it for promotion
2. **Automatic**: a post-connect hook could scan LEARNINGS.md and run `/learn` on each entry

Neither is implemented. Until one is: LEARNINGS.md is a rescue file, not a store. Treat it as a queue to drain at next session start.

---

## When should /learn run?

Not on every commit. The right triggers:
- **End of session** → `/retro` as structured prompt: "what did we learn? what decisions were made?"
- **After a plan closes** → Phase 7 checklist item: "run `/learn` on any non-obvious findings"
- **After a real debate** → whenever a push-back or alternative was weighed and resolved, capture it immediately while the reasoning is fresh
- **Never** → on mechanical commits, routine deploys, passing tests — these aren't insights

The signal is: *did the outcome surprise you, or would it have surprised a future collaborator?* If yes, `/learn` it.

---

## Open questions (not yet decided)

- Should `builder knowledge` live in Monty-CNS (the config repo) or Monty-Ledger (the vault)? Currently split awkwardly.
- Should design sessions like this one produce a proper white paper draft, or is a seed note in inbox sufficient?
- What's the right `/retro` prompt structure to surface promotion decisions, not just summarize work?
- Should LEARNINGS.md be checked at session start automatically (via hook or foreman check)?

---

## Next actions

- [ ] Promote this note to `04_Decisions/` or `06_Writing/` after review
- [ ] Add LEARNINGS.md backlog check to `/foreman` status card
- [ ] Add "promotion step" to `/retro` skill — explicitly ask which inbox items should move
- [ ] Draft the builder knowledge pod structure in `13_Pods/`
- [ ] Write a proper decision note for the agent architecture thesis (separate doc)
