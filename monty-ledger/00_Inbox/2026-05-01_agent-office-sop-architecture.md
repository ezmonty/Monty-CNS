---
title: "AI agent office SOP architecture — the office you get to design and train"
type: design
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["strategy", "operations"]
---

# AI agent office SOP architecture

**Seeded from:** design session 2026-05-01
**Promote to:** `04_Decisions/` — this is a foundational architecture position
**Thesis:** SOPs matter more with AI agents than with humans. The SOP infrastructure is the organizational design layer that prevents drift, shortcuts, and hallucinated compliance.

---

## The core position

Human employees drift from SOPs but at least remember yesterday's meeting, feel social pressure to conform, and experience shame when caught cutting corners. Agents have none of these. Every session is day one. Every constraint must be encoded or it doesn't exist.

This means:
- An undocumented constraint will be violated, guaranteed, eventually
- An unaudited gate will be skipped the moment it adds friction
- A plan without a checklist will be "completed" with items silently dropped

The SOP infrastructure is not bureaucracy. It's the persistent memory the agent doesn't have.

---

## The office analogy (complete mapping)

| Office layer | Monty equivalent | Purpose |
|---|---|---|
| Employee handbook | CLAUDE.md (user + project scope) | Always-loaded ground rules |
| Job SOPs | Skills (skills/*.md) | How to perform specific job functions |
| Project briefs | Plans (/plan, superplan) | What we're building this sprint, with gates |
| Institutional memory | Vault (monty-ledger) | Decisions made, lessons learned, why things are the way they are |
| End-of-shift log | /retro | What moved, what was decided, what promotes |
| Quality auditor | /adversarial-reviewer | Finds drift, shortcuts, corner-cutting |
| Compliance audit | /pulse | Full stack coherence check, H-Scale rating |
| Onboarding packet | /onboarding skill | Gets a new agent (or human) up to speed |

The difference from a real office: **you get to design and train every employee from scratch.** No inherited bad habits. No legacy "we've always done it this way." The SOP is the constitution.

---

## Where agents fail like humans (and the countermeasures)

| Failure mode | Human version | Agent version | Countermeasure |
|---|---|---|---|
| Drift from plan | "We pivoted but forgot to update the brief" | Agent loses track of original constraint mid-session | Gated plans with checklists; /superplan gates |
| Shortcuts | "I skipped the code review, it looked fine" | Agent skips adversarial review, declares CLEAN | /adversarial-reviewer is mandatory in Phase 2 of superplan |
| Hallucinated compliance | "Yeah I tested that" (didn't) | "Tests pass" (didn't run them) | Smoke tests with real HTTP calls, not mocks; /smoke as verification |
| Fraud/fabrication | Employee fakes a report | Agent invents a plausible-sounding result | H-Scale rating surfaces honesty level; stub code is H1/H2 |
| Lost institutional memory | "Why did we build it this way again?" | Fresh session, no context, repeats old mistakes | Vault; CLAUDE.md; /explore before major work |
| Empire building | Employee adds unnecessary complexity | Agent over-engineers, adds abstractions | Karpathy principles skill; "don't add what task doesn't require" |

---

## What makes this different from just writing docs

Traditional docs are written once, read rarely, ignored under pressure. This system is different because:

1. **Skills are executable** — CLAUDE.md and skill files aren't passive documentation; they're loaded into every session and actively shape behavior
2. **Gates are enforced** — superplan gates block progression; the agent can't "continue" without passing the gate
3. **Auditors are adversarial** — /adversarial-reviewer and /pulse are designed to find what the working agent missed
4. **Memory compounds** — each vault entry makes the next session smarter without human intervention

The office runs itself, but you designed the org chart.

See also: [[Decision - AI Writes to Inbox Only - 2026-04-18]] (the specific trust rule for where AI can write).

---

## Open questions

- Should there be a formal "agent onboarding checklist" that runs before any major task? (Read CLAUDE.md → check vault for relevant decisions → run /foreman → confirm plan)
- What's the right cadence for /pulse? Weekly? After each major feature?
- Should skills have explicit "compliance gates" — steps that must be confirmed before the skill proceeds?
- How do you audit whether an agent actually followed the SOP vs just claimed it did?
