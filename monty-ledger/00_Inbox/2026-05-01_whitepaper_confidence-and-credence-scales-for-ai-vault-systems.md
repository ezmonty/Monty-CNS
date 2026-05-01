---
title: "Confidence and credence scales for AI-curated knowledge vaults"
type: whitepaper
origin_type: ai-proposed
confidence: 2
status: review-pending
open_questions: 5
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "review", "writing"]
---

**Project:** Monty-CNS (vault tooling)
**Tags:** operations, review, writing
**Confidence:** suspected (AI-proposed; awaits human ratification before becoming authoritative)
**Context:** The Monty-Ledger vault has used a 1-5 `confidence` field on every note since inception, but no document defines what the levels mean, who can write at each, or what triggers promotion/demotion. The 2026-05-01 vault audit surfaced 5 AI-written notes at confidence 4 (which the access model forbids without human verification) and the user could not make an informed promotion decision because no scale was published. This document proposes a definition grounded in existing literature, alternatives considered, and a final recommendation.

---

## 1. Problem statement

A `confidence: N` field stamped on every note implies the note can be ordered along a single dimension. In practice, "how confident I am about this note" is at least four overlapping dimensions:

1. **Epistemic certainty** — how likely the claim is to be true.
2. **Verification provenance** — who has signed off (AI alone, AI + tests, AI + human review, multiple humans, time-survived).
3. **Editability** — how rewritable the note is. A scratch idea can be deleted; a foundational decision cannot without consequence.
4. **Authority weight** — when this note conflicts with another, which wins.

Conflating these into a single integer is lossy. But a single integer is also the only thing a small LLM-driven workflow can reliably read, prompt for, and enforce. The pragmatic answer is: pick a primary dimension, define it crisply, name the others as separate fields if they end up mattering.

## 2. Prior art

### 2.1. Bayesian credence / superforecaster calibration

Tetlock's "Superforecasting" framework (Tetlock & Gardner, 2015) and the Good Judgment Project map subjective confidence onto probability bands. The canonical 5-tier mapping used by intelligence-community estimative language (ODNI, *Words of Estimative Probability*, derived from Sherman Kent's 1964 paper):

| Tier | Probability range | Phrase |
|---|---|---|
| 1 | < 10% | "very unlikely / remote" |
| 2 | 10-30% | "unlikely" |
| 3 | 30-70% | "even chance / could happen" |
| 4 | 70-90% | "likely / probable" |
| 5 | > 90% | "very likely / almost certain" |

This scale is about the **truth** of a claim. It works well for forecasts ("Will X happen?") but is awkward for vault notes that aren't claims about the future ("This is how OAuth works in our system"). A note can be 100% true but still "low confidence" in the sense that it's barely-tested.

### 2.2. LessWrong epistemic-status convention

Posts on LessWrong (and Andy Matuschak's notes) carry an *epistemic status* header, which is freeform but clusters around:

- **Exploratory** — thinking out loud; could be wrong
- **Researched** — looked into it; cite sources
- **Endorsed** — author stands behind it
- **Canonical** — repeatedly referenced; load-bearing

This is a **provenance/verification** scale, not a probability scale. It answers "how seriously should I take this?" rather than "how likely is this true?" Better fit for personal-knowledge-management (PKM) than Bayesian probability.

### 2.3. Zettelkasten progression

Niklas Luhmann's Zettelkasten and its modern descendants (Sönke Ahrens, *How to Take Smart Notes*, 2017) describe a **maturity** scale:

- **Fleeting** — a stray thought, captured before it's lost
- **Literature** — your summary of someone else's idea, with citation
- **Permanent** — your idea, written for future you to read cold

Maturity, not truth. A fleeting note can be 100% correct and still get promoted to permanent only after you've thought about it more. The promotion gate is "would I want to read this in five years?" — a *usefulness* test, not a *truthfulness* test.

### 2.4. Wikipedia article quality grading

Wikipedia uses a 7-tier article-quality scale (Stub, Start, C, B, GA, FA, FL) plus separate importance ratings. The quality ratings are governance markers — who has reviewed, what process ratified. This is the closest analog to what an AI-curated vault actually needs: a multi-eye verification gate.

### 2.5. Software readiness scales (TRL, H-Scale)

NASA's Technology Readiness Levels (TRL 1-9) and the user's existing H-Scale (H1-H5) measure **maturity-toward-production** of a system, not the truth of a single claim. Useful conceptually because they bake in "who has signed off and at what stage" — exactly what a vault note needs.

## 3. The conflation problem (and why one number is still right)

Looking at the four prior-art scales, an honest classification of vault notes would carry at least three fields:

- `epistemic` — how likely the claim is true (1-5, calibration-style)
- `verification` — who has reviewed (ai-only / ai+test / human / human+time)
- `maturity` — how rewritable (fleeting / draft / endorsed / canonical)

The vault uses one field today. Splitting into three is technically clean but operationally heavy: every prompt would need three sub-prompts, every query would need three filters, and the human would have to learn three vocabularies.

**Pragmatic recommendation:** keep the single `confidence: N` field, but **define N as a composite** that is dominated by *verification provenance* (since that's the question the vault constraint actually enforces — "AI cannot self-promote past 3"). Truth-likelihood and maturity are correlated with provenance closely enough that a single number is workable.

## 4. Recommended scale (composite, provenance-dominant)

| Level | Name | Definition | Provenance | Maturity | Truth-likelihood (loose) |
|---|---|---|---|---|---|
| **1** | speculative | Hypothesis worth capturing before it's lost. Could be wrong. May contradict other notes. | AI or human | Fleeting | < 50% confident |
| **2** | working | AI-proposed default. Internally consistent and reasoned, but no independent verification. **Default for AI-written notes.** | AI alone | Draft | 50-80% — "more likely than not" |
| **3** | supported | Has in-body evidence (test results, citations, observed behavior in real systems). AI ceiling without explicit human input. Promotion to 3 requires the body to actually contain the evidence. | AI with evidence | Endorsed by AI | 80-95% |
| **4** | verified | Human has read and confirmed, OR AI has independently re-tested in a separate session and the original holds. Durable; future AI runs should treat as authoritative for its scope. | Human-reviewed | Endorsed by human | > 95% within scope |
| **5** | canonical | Load-bearing. Other notes defer to this. Foundational identity, design decisions, irreversible facts. Demoting a 5 should require a deliberate process, not a casual edit. | Multi-eye / time-survived | Permanent | Treated as ground truth |

### 4.1. Promotion rules

- 1 → 2: AI satisfies itself the claim is reasoned, even if speculative remains an option. Self-promotion allowed.
- 2 → 3: requires evidence in-body (tests, command output, citations). AI may self-promote IF the evidence is present in the note.
- 3 → 4: HUMAN ONLY. Reads the note, agrees, confirms. AI may not self-promote.
- 4 → 5: HUMAN ONLY. Note has been referenced and stood up for some duration (suggested: 30+ days), or is explicitly designated foundational.
- Demotion: any user can demote any level for cause. AI may demote on contradiction with a higher-confidence note (and should flag this).

### 4.2. Constraints baked in

- **AI ceiling at 3.** Already enforced by `vault-access-model` skill.
- **Default at 2 for new AI writes.** Already enforced.
- **Prompt the human at write time** for an explicit override. NEW (added to `/learn` and `/retro` skills 2026-05-01).

## 5. Alternatives considered (and rejected)

| Alternative | Why rejected |
|---|---|
| Pure Bayesian (probability bands) | Awkward for non-future-claim notes; users don't think in % when writing |
| Pure Zettelkasten maturity | Doesn't carry the "human has signed off" signal that the access constraint needs |
| Three-field split (epistemic/verification/maturity) | Operationally heavy; user would have to learn three vocabularies and answer three prompts per note |
| Boolean "verified / not verified" | Loses the speculative / canonical extremes that map to actual usage today |
| Continuous 0-1 score | LLM cannot reliably calibrate to 0.01 granularity; integer ladder is more legible |

## 6. Open Questions

Before this whitepaper is promoted to 4 (verified), resolve each below.
Tick the box, write `→ Resolution: <answer>. Decided <date>.` inline.
When all five close, status auto-flips to `accepted` and the row is
removed from `~/.claude/PENDING_REVIEWS.md`.

- [ ] q1: **Time-survived as a 4→5 trigger** — is "30 days without contradiction" the right threshold, or does it need explicit human re-affirmation?
- [ ] q2: **Multi-tenant or solo?** Right now there's one human reviewer (the user). When a second person ratifies a note, does that count as a 4→5 jumpstart, or stay at 4?
- [ ] q3: **Confidence on `type: profile` notes** — most existing profiles are at 4. Is that right (verified once and stable) or should they be 5 (canonical identity, load-bearing)?
- [ ] q4: **Demotion mechanic** — when a higher-confidence note contradicts a lower-confidence one, what's the workflow? Auto-demote the lower? Flag both for review?
- [ ] q5: **AI-internal re-verification as a 3→4 path** — should re-running a smoke test in a separate session be enough to promote, or does promotion always require human?

## 7. Recommendation

1. Adopt §4 as the working scale.
2. Codify it in `VAULT_RULES.md` once this whitepaper is human-promoted to 4.
3. Keep the prompt-at-write workflow that was added to `/learn` and `/retro` 2026-05-01.
4. Revisit in 90 days; if the scale isn't surviving real use, consider the three-field split.

## 8. Sources

- Kent, S. (1964). *Words of Estimative Probability.* CIA Studies in Intelligence.
- Tetlock, P. & Gardner, D. (2015). *Superforecasting: The Art and Science of Prediction.* Crown.
- Ahrens, S. (2017). *How to Take Smart Notes.*
- Matuschak, A. *Evergreen notes / epistemic status conventions.* https://notes.andymatuschak.org
- Wikipedia (n.d.). *Content assessment / article quality grading.* https://en.wikipedia.org/wiki/Wikipedia:Content_assessment
- Mankins, J. (1995). *Technology Readiness Levels: A White Paper.* NASA OSAT.
- ODNI (2007). *Analytic Standards.* Intelligence Community Directive 203.
- LessWrong (n.d.). *Epistemic status conventions* (community wiki).
- Internal: `~/.claude/skills/h-scale/` — H1-H5 capability honesty scale (the closest in-house analog).

## 9. Status note

This document is itself confidence: 2 (working). It is the AI's first draft. The user is invited to:

- Read in full
- Mark up open questions in §6
- Promote to 4 if accepted as-is, OR
- Demote / rewrite / reject and propose alternative

Once promoted to 4, the relevant clauses of §4 should be copied verbatim into `VAULT_RULES.md` under a new "Confidence Scale" heading, and the `/learn` and `/retro` skills should be updated to mirror the final wording.
