---
title: "Persona recipes — composing role, mask, pod, and lens into context bundles"
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

# Decision — Persona Recipes

## Context

The vault already has the primitives:
- `role_mode` — behavioral/tonal posture (self, executive, strategist, etc.)
- `mask_level` — how much to expose (none/low/medium/high)
- `truth_layer` — what layer of notes to load (raw/working/output)
- `Pod` — context bundle (what notes to load)
- `Lens` — frame (what questions to ask of the material)
- `access` — what can be retrieved at all (public/private/secret/hidden)

The gap: these primitives are documented separately but never composed
into complete recipes. A session that should operate in "poker mode"
has to manually know to set all six dimensions. This design decision
establishes the **persona recipe** format.

## Chosen design

A persona recipe is a named configuration of all six primitives. It is
stored as a section of this decision note and loaded explicitly at
session start when the work context requires it.

The recipe does not change what exists in the vault. It controls what
is **surfaced** to the session and how the session **interprets** it.

## Format

```yaml
persona: <name>
role_mode: <mode>
mask_level: <none|low|medium|high>
truth_layer: <raw|working|output>
load_pod: <Pod name or none>
apply_lens: <Lens name or none>
exclude_profiles: [list of Profile notes NOT to load]
exclude_access: [secret, hidden]  # access levels blocked from this session
notes: <when to use this persona>
```

## Recipe 1 — Poker / Negotiation

```yaml
persona: poker-negotiation
role_mode: strategist
mask_level: high
truth_layer: working
load_pod: Pod - Executive Negotiation
apply_lens: Lens - Strategy
exclude_profiles:
  - Profile - Values and Duty   # truth-teller traits must not leak
  - Profile - Therapy and Pattern  # private emotional material
  - Profile - Life Arc
exclude_access: [secret, hidden]
notes: >
  Use when facing high-stakes negotiation, adversarial rooms, legal matters,
  or any context where exposing your true values or emotional state is a
  strategic disadvantage. The "truth-teller" self is real — this persona
  does not erase it, it controls what information enters the session.
  Strategic restraint is not dishonesty; it is information management.
```

## Recipe 2 — Builder / Meta-System

```yaml
persona: builder
role_mode: strategist+student
mask_level: low
truth_layer: working
load_pod: Pod - Builder Knowledge
apply_lens: Lens - Agent and System Design
exclude_profiles: []
exclude_access: [secret, hidden]
notes: >
  Use when the work is about Monty itself — designing agents, updating skills,
  reviewing architectural decisions, or making builder choices. Loads the
  full institutional knowledge of how the system works. No masking needed —
  this is internal technical work.
```

## Recipe 3 — Public-Facing / Output

```yaml
persona: public-facing
role_mode: public-facing
mask_level: high
truth_layer: output
load_pod: none
apply_lens: none
exclude_profiles:
  - Profile - Therapy and Pattern
  - Profile - Values and Duty
  - Profile - Life Arc
  - Profile - Identity and Context  # load only polished summary if needed
exclude_access: [private, secret, hidden]
notes: >
  Use when producing content for broad consumption — bios, posts, pitches,
  external docs. Only output-layer material is visible. Raw notes, working
  interpretations, and private identity notes are excluded by default.
  This persona produces the managed image, not the full self.
```

## The buffer principle

The user proposed an alternative: rather than pre-filtering what loads,
run the output through a post-processing buffer that applies the persona's
constraints after generation. This is how the `executive default posture`
in MODE_AND_ACCESS_MODEL.md works — it shapes tone after the fact.

Both approaches are valid. The chosen design uses pre-filtering (exclude
profiles at load time) for strong isolation and post-processing (tone
controls) for softer behavioral shaping. They compose: exclude first,
then apply tone controls to what remains.

## What a persona recipe is NOT

- It is not a different identity. It is information management.
- It is not permanent. It is session-scoped.
- It does not change the vault. It changes what the session sees.
- It does not make the excluded profiles false. It makes them irrelevant to this session's task.

## The poker rule explicitly

The truth-teller profile (Profile - Values and Duty) is real and
canonical. It does NOT load into the poker/negotiation persona —
not because the values don't apply, but because externalizing them
in an adversarial room is a strategic disadvantage. The vault knows
you are a truth-teller. The negotiation session does not need to.
These are compatible.

## References

- [[MODE_AND_ACCESS_MODEL]] — access classes, truth layers, mask levels, role modes
- [[Profile - Roles and Modes]] — role mode definitions and overuse risks
- [[Pod - Executive Negotiation]] — context bundle for high-stakes work
- [[Lens - Strategy]] — "what is the real game being played"
