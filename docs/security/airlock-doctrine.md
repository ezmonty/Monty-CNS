# AI Agent Trust Airlock — Doctrine Pointer

This is a **cross-repo pointer**. The canonical doctrine and full
architecture live in the `valor2.0` repo. Read those for the binding
authority and the implementation specifics.

## Canonical Sources

| Doc | Tier | Path (in valor2.0) |
|---|---|---|
| Doctrine (non-negotiable principle) | Tier 0 — Intent | `docs/m2codex/AGENT_TRUST_DOCTRINE.md` |
| Architecture (9-layer airlock + P0/P1/P2 punch list) | Tier 1 — Canonical Architecture | `docs/valor2_prompt_docs_v3/airlock_architecture_v3.md` |
| Worklog entry | append-only audit | `docs/m2codex/WORKLOG.md` (2026-05-01 entry) |

Precedence in `docs/m2codex/LINK_MATRIX.md`: **slot 4**, sibling to
`EVIDENCE_AND_AUDIT_DOCTRINE.md`.

## One-Paragraph Summary

Valor / Monty AI agents act on the principal's behalf with broad authority —
web fetch, money, code execution, communication. The threat is the
*confused-deputy via prompt injection*: an attacker plants instructions in
ingested content and the agent acts on the attacker's intent while wearing
the principal's authority. The deeper threat is **integrity of the policy
itself**: a compromised agent that can rewrite its own enforcement code,
configs, or audit log defeats every internal control. The airlock doctrine
codifies three non-negotiable principles to address this structurally:

1. **Trust is enforced from outside the blast radius of the thing being
   trusted.** The Trusted Computing Base must be smaller than the agent
   platform, and physically/identity-separated from it.
2. **Hard limits live in systems the agent cannot reprogram, ideally
   outside our own infrastructure** — vendor-side card velocity, signed
   policy bundles, external append-only audit.
3. **Untrusted data must never be indistinguishable from principal
   instructions** — quarantine envelopes, P-LLM/Q-LLM split (CaMeL
   pattern), taint propagation through plan steps.

## Why This Doc Exists in Monty-CNS

`docs/security/` is the cross-machine security posture index for the CNS
system itself. The agent-trust airlock doctrine is adjacent to several docs
already here — particularly:

- `actor-model.md` (AI-agent actor type and inherited permissions)
- `threat-model.md` (what we defend against)
- `compromise-playbook.md` (post-incident response — the audit DAG in the
  airlock architecture is the forensic anchor)

Treat this pointer as the link from CNS-side identity / actor / compromise
thinking to the Valor-side enforcement architecture. If you're building
anything that touches an agent's authority — web access, money, code
execution, communication — read the canonical sources above before merging.

## Quick Reference: The Nine Layers

| # | Layer | One-line |
|---|---|---|
| 0 | External Enforcement Boundary | Vendor card caps, out-of-process PDP, signed configs, external WORM audit, code-integrity attestation |
| 1 | Ingress / Quarantine | Wrap external bytes at ingestion; provenance + trust tag + tool-call bait stripper |
| 2 | Planner / Reviewer / Executor privilege separation | CaMeL P-LLM/Q-LLM; planner sees only structured state; quarantined LLM has no tool access |
| 3 | Capability-based action mediation (PDP) | Single deny-first decision point; capabilities bind to argument hashes |
| 4 | Behavioral & spend governor | Velocity, first-time-recipient, off-hours, taint-spike, rapid-fire — independent of $ amount |
| 5 | Egress controls | URL allowlist, recipient allowlist, schema'd shell tools, network-namespace firewall |
| 6 | Tamper-evident audit + provenance | Hash-chained DAG; HSM signing; external WORM mirror |
| 7 | Per-agent identity, per-action credentials | SPIFFE/SPIRE; no shared bearer secrets |
| 8 | Out-of-band confirmation | Push-to-phone signed challenge; FIDO2; two-person rule for highest tier |

## Reading Order

If you arrived here from CNS:

1. `actor-model.md` (this folder) — understand the AI-agent actor.
2. `threat-model.md` (this folder) — understand the existing CNS posture.
3. `valor2.0/docs/m2codex/AGENT_TRUST_DOCTRINE.md` — the binding doctrine.
4. `valor2.0/docs/valor2_prompt_docs_v3/airlock_architecture_v3.md` — the
   nine-layer architecture and the P0/P1/P2 punch list.
5. `valor2.0/docs/m2codex/WORKLOG.md` (2026-05-01 entry) — the change
   record and the rationale.
