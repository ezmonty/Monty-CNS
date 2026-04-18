---
type: decision
status: active
created: 2026-04-18
tags: [decision, security, architecture, access-control]
confidence: 4
access: private
truth_layer: working
role_mode: strategist
persona_mix: [strategist, owner]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — Valor Controls Vault Access, Not the MCP Server

## Context

The Ledger MCP server currently has a single env var
(LEDGER_ACCESS_CEILING) that caps access for ALL callers equally.
This is wrong for three reasons:

1. Different agents need different access to different parts of you
2. Sometimes zero knowledge is the right answer (unbiased opinions)
3. The orchestrator (Valor) already has agent identity — the MCP
   server should enforce what the orchestrator decides, not make
   its own access decisions

## The Problem with Equal Access

A code review agent reading your leadership philosophy is noise
and potential bias. An executive negotiation agent without your
strategic posture is useless. A generic helper asked for an
unbiased opinion should see NOTHING from the vault.

The Pods (13_Pods/) already define which profiles load for which
context. The access model (MODE_AND_ACCESS_MODEL.md) already
defines 4 access classes. The missing piece: connecting agent
identity to access grants.

## Design

```
Valor (orchestrator)
  │
  ├─ Agent: CodeReviewBot
  │    token: { access_max: "public", pods: [], clean_room: false }
  │    → sees: public notes only, no personal profiles
  │
  ├─ Agent: ExecutiveNegotiation
  │    token: { access_max: "private", pods: ["Executive Negotiation"], clean_room: false }
  │    → sees: public + private, executive pod context loaded
  │
  ├─ Agent: ReflectionWork
  │    token: { access_max: "secret", pods: ["Reflection and Pattern Work"], clean_room: false }
  │    → sees: public + private + secret, deep personal context
  │
  ├─ Agent: GenericHelper (unbiased mode)
  │    token: { access_max: "none", pods: [], clean_room: true }
  │    → sees: NOTHING from vault, deliberately context-free
  │
  └─ Hidden lane
       → no token can access this, ever
       → human-only, direct file read on single device
```

## How It Works

1. Valor mints a short-lived JWT or signed token per agent dispatch
2. Token contains: agent_name, access_max, allowed_pods, clean_room
3. MCP server validates the token signature (shared secret or public key)
4. MCP server caps access to whatever the token allows
5. If clean_room: true, all query tools return empty results
6. If no token provided: fall back to LEDGER_ACCESS_CEILING env var
   (backward compatible with current single-user mode)

## The "Unbiased Opinion" Insight

Sometimes the VALUE is in NOT knowing. When you ask "is this a
good idea?" and the AI has your profiles loaded, it will
unconsciously align with your values, your style, your patterns.
That might be what you want (when writing in your voice) or
exactly what you don't want (when seeking a genuinely independent
assessment).

Clean room mode makes this explicit: "give me an opinion WITHOUT
loading who I am." The vault stays available — it's not deleted —
it's just not injected into this particular context.

## When to Build This

Not now. The current LEDGER_ACCESS_CEILING is sufficient for
single-user mode (just you calling the MCP server). Build the
token system when:
- Valor agents start calling the MCP server (Phase 4 of Ledger plan)
- Multiple users or services need different access levels
- The rack is live and Valor is persistent

## Chosen Path

1. Keep LEDGER_ACCESS_CEILING as the single-user fallback (now)
2. Design the token schema when Valor integration starts (Phase 4)
3. The Pod system already defines "which context for which task" —
   wire pods to agent tokens, not to user commands
4. Add clean_room mode as a first-class concept in the MCP server

## Risks

- Over-engineering auth for a single-user system (mitigated:
  defer until Valor integration)
- Token management complexity (mitigated: Valor already handles
  agent dispatch, adding a token field is incremental)
- Clean room mode could be confusing ("why doesn't /learn work?" —
  because you're in clean room). Needs clear UX.
