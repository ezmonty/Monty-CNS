---
type: decision
status: active
created: 2026-04-18
tags: [decision, ai-governance, vault, trust]
confidence: 4
access: private
truth_layer: working
role_mode: strategist
persona_mix: [strategist, guardian]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — AI Writes to Inbox Only

## Context

AI agents (Claude Code, Valor agents) generate insights worth keeping.
The question: where can they write, and with what authority?

VAULT_RULES.md Rule 1: "Save what changes future output." AI insights
qualify — but the vault contains identity notes (03_Profiles),
canonical decisions (04_Decisions), and leadership thinking
(05_Leadership). Letting AI write directly to those folders risks
corrupting the owner's self-model.

## Options considered (Round Table resolution)

| Position | Advocate | Problem |
|---|---|---|
| **Full write access** | AI Integration role | AI could overwrite identity notes or promote its own framing as canonical |
| **Read-only** | Systems Integration role | Loses valuable AI insights entirely — no capture path |
| **Gated staging** | Compromise | AI proposes, human promotes — captures value without trust risk |

## Chosen path

**AI writes to `00_Inbox/` only.** Every AI-created note gets:
- `origin_type: ai-proposed`
- `confidence: 2`
- `status: review`

Human reviews and promotes to canonical folders (03_Profiles,
04_Decisions, etc.). AI never writes directly to identity notes.

## Why both trust AND quality

This is not just about trust ("AI shouldn't define your identity").
It is also about quality. The inbox is a staging area. Notes that
survive human review are stronger than notes that bypass it. The
review step is a filter, not a bottleneck.

## Consequences

- `create_inbox_note` MCP tool enforces the inbox constraint
- AI-proposed notes are visible in vault queries but flagged
- Promotion is a human action (move file + update frontmatter)
- No AI writes to 03_Profiles, 04_Decisions, or 05_Leadership
