---
id:
type: note
status: active
created: 2026-05-01
updated: 2026-05-01
tags: [pod, builder, strategy]
confidence: 3
source:
summary: Context bundle for meta/builder sessions — Monty knows how to build Monty.
related_projects: [valor2.0, Monty-CNS]
related_profiles: [[Profile - Roles and Modes]]
review_due: 2026-08-01
access: private
mask_level: low
truth_layer: working
role_mode: strategist
persona_mix: [strategist, student]
origin_type: ai-proposed
---

# Pod - Builder Knowledge

## Purpose

Load this pod when the work is about Monty itself — building agents,
designing the system, making architectural decisions, extending the
skill library, or reviewing builder knowledge for gaps.

"Monty knows how to build Monty" requires a context bundle that is
different from any domain (construction, finance) or personal work.
This pod assembles it.

## Default load

- `Knowledge - System Invariants` (vault summary of max_monty_invariants.md)
- `Decision - AI Writes to Inbox Only - 2026-04-18`
- `Decision - H-Scale Adoption and Limitations - 2026-04-18`
- `Decision - Personality Diverse Agent Panels - 2026-04-18`
- `Decision - Docs to Vault Bridge` (when written)
- Relevant docs canon: `docs/m2codex/CANON.md`, `docs/m2codex/DOCS_GOVERNANCE.md`

## Lens

Apply `Lens - Agent and System Design` when reading material in this pod.

## Tone controls

- display_self: builder-self
- expose_depth: technical
- strategic_tone: direct-and-precise
- role_mode: strategist + student blend (understand deeply, then act decisively)

## What this pod is for

| Task | Load this pod? |
|---|---|
| Adding a new agent to Valor | Yes |
| Writing or updating a skill | Yes |
| Reviewing invariants for a new feature | Yes |
| Making an architectural decision | Yes |
| Debugging a domain feature (construction, finance) | No — use domain pod |
| Personal reflection or journaling | No — use Reflection pod |
| Writing a school paper | No — use Academic Output pod |

## What "Monty knows how to build Monty" means

Builder knowledge is distinct from project knowledge (what Valor does)
and personal knowledge (who Shanu is). It is the accumulated understanding
of how the agent system works, what its invariants are, what design
decisions have been made and why, and what patterns are proven vs suspected.

This knowledge compounds across all projects and all future sessions.
Loading this pod gives a session the institutional memory it needs to
make good builder decisions without re-discovering everything from scratch.

## Risks

- Over-indexing on existing patterns — may resist needed architectural change
- Conflating builder knowledge with domain knowledge — keep them separate
- Loading too much — this pod is a context bundle, not a full history dump
