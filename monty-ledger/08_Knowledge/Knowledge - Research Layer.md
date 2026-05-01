---
title: "Knowledge - Research Layer"
type: note
status: active
created: 2026-05-01
updated: 2026-05-01
origin_type: ai-proposed
access: private
truth_layer: working
confidence: 3
tags: ["knowledge", "vault", "research"]
role_mode: strategist
---

# Knowledge - Research Layer

## The problem this solves

Decisions don't come from nowhere. They come from things that were read, evaluated, tested, or rejected. Without tracking that evaluation history, the vault holds conclusions but not the reasoning trail. Six months later you can't tell: did we look at X and reject it, or did we never look at it?

The research layer preserves the evaluation trail — including dead ends.

## Two note types

### `type: research` — Evaluated Source

Something formally weighed against a question or decision. Has a verdict.

| Verdict | Meaning |
|---------|---------|
| `adopted` | Incorporated into a decision or design |
| `rejected` | Evaluated and ruled out — reason recorded |
| `deferred` | Merit exists; timing or fit is wrong now |
| `watching` | Not ready to evaluate; monitoring for development |
| `timing` | Right idea, wrong moment — revisit trigger noted |
| `superseded` | Replaced by a better source or later evidence |

Even rejected sources are valuable: they document what was considered and why it didn't fit. A DriftGuardAgent should never have to re-evaluate something that was already ruled out.

### `type: signal` — Curiosity/Breadth Capture

Something interesting that hasn't been formally evaluated. Adds depth, surfaces connections, may become decision-grade later when a relevant question opens up.

No verdict required. Tagged by domain so it's findable when that domain becomes active.

## Document ingestion (RAG)

When the source document itself can be obtained:
- Store in `09_Assets/` (PDFs, scraped articles, tool docs, specs, repos)
- Set `ingested: true` and `asset_path:` in the research note frontmatter
- Both the research note AND the raw asset chunk into RAG

The research note is high-signal RAG (pre-evaluated, has verdict and decision link).
The raw asset is full-coverage RAG (chunked content for direct retrieval).

They compose: the research note surfaces the conclusion; the asset surfaces the evidence behind it.

## The bidirectional link rule

- Research notes set `evaluated_for: [[Decision - X]]`
- Decision notes include a `## Sources` section with wikilinks to research notes that fed them

This makes decisions auditable and research retrievable from either direction.

## Where these live

- `08_Knowledge/Research - [Topic] - [Date].md` — evaluated sources
- `08_Knowledge/Signal - [Topic] - [Date].md` — breadth/curiosity captures
- `09_Assets/[domain]/[filename]` — ingested documents

## Templates

- [[Template - Research Source]]
- [[Template - Signal Note]]
