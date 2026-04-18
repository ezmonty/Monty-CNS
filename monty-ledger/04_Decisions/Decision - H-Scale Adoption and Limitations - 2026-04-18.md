---
type: decision
status: active
created: 2026-04-18
tags: [decision, methodology, evaluation, h-scale]
confidence: 3
access: private
truth_layer: working
role_mode: strategist
persona_mix: [strategist, student]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — H-Scale Adoption and Limitations

## Context

We used the "H-Scale" (Capability Honesty Scale, H1-H5) throughout
the CNS buildout to rate the readiness of each vertical. The final
tear-down team rated every vertical H3. But we never interrogated
the instrument itself: where it came from, what it actually
measures, whether it's valid, or how to apply it consistently.

## What the H-Scale is

The H-Scale is a **custom heuristic** created during the Valor 2.0
development process. It is NOT a published standard, NOT peer-
reviewed, and NOT derived from formal research methodology.

It evaluates 4 axes:
1. Methodology — is the logic/approach correct?
2. Data Quality — is the input real or synthetic?
3. Testing — is it verified?
4. Documentation — can someone else understand it?

The overall score is the WEAKEST axis (weakest-link model).

## What it draws from (but is NOT)

| Established framework | What H-Scale borrows | How it differs |
|---|---|---|
| **CMM/CMMI** (Capability Maturity Model, SEI/Carnegie Mellon) | 5-level maturity scale, process-focused | CMM rates organizational processes, not individual components. CMM has formal appraisal methods (SCAMPI). H-Scale is informal. |
| **TRL** (Technology Readiness Levels, NASA) | 9-level scale from concept to flight-proven | TRL is specifically for technology maturation through development stages. H-Scale collapses this into 5 levels and applies it to software features, not hardware. |
| **SRL** (Software Readiness Levels, DoD) | Readiness assessment for software | SRL has formal criteria and government backing. H-Scale has neither. |
| **Dreyfus skill model** | Novice → Expert progression | Dreyfus rates human competence. H-Scale rates artifact readiness. |

The H-Scale is best understood as a **simplified, opinionated
synthesis** of these frameworks, designed for fast in-session
assessment rather than formal evaluation.

## What it measures well

1. **Claim-reality gap** — forces you to compare what you say
   something does vs what you can prove it does
2. **Upgrade path clarity** — every rating requires "here's how
   to get to the next level," which prevents vague readiness claims
3. **Weakest-link awareness** — the overall = lowest axis model
   prevents hiding a gap behind strong scores in other areas
4. **Speed** — can rate a component in 5 minutes. Formal methods
   (CMMI SCAMPI) take weeks.

## What it measures poorly or not at all

1. **Validity** — the 4 axes and 5 levels are arbitrary. Why not
   3 axes? Why not 7 levels? No theoretical justification exists.
2. **Subjectivity** — "H3: correct methodology" vs "H2: simplified
   heuristic" is a judgment call. Two raters can disagree and both
   be reasonable. No inter-rater reliability has been tested.
3. **Value/impact** — an H5 logging system matters less than an
   H2 core product. The scale rates readiness, not importance.
4. **User experience** — no axis for "does it feel right to use."
   A system can be H4 on all axes and still be confusing.
5. **Architecture quality** — methodology asks "is the logic
   right?" but not "is the design good?" A correctly implemented
   bad design scores H4.
6. **Reproducibility** — we rated CNS H3 in one session. Would
   a different team on a different day rate it the same? Unknown.

## How we actually applied it

In this session, we:
1. Had a subagent read the H-Scale SKILL.md
2. Gave it 8 verticals to rate
3. It read HANDOFF.md, README, WIRING.md, and test results
4. It produced ratings with evidence and upgrade paths

**Problems with this application:**
- The rater (Claude) wrote most of the code it was rating
- The rater read the HANDOFF doc (also written by Claude) as
  evidence — circular self-assessment
- No independent verification (no human ran the tests)
- The "weakest link" model means CI (which we can't do in this
  sandbox) drags everything to H3 regardless of actual quality

## What we should do about it

### Option A: Accept the H-Scale as a useful heuristic (CHOSEN)
Use it for quick internal assessments with the explicit caveat that
it is subjective, custom, and not a formal evaluation. Always note
its limitations when reporting ratings.

### Option B: Replace with a formal framework
Adopt TRL or CMMI formally. This requires significant overhead
(formal appraisals, trained assessors, documented evidence trails)
that is disproportionate for a personal dotfiles project.

### Option C: Formalize the H-Scale
Add inter-rater reliability testing, formal criteria definitions,
and published scoring rubrics. This would make it more rigorous
but risks over-engineering a tool that works precisely because
it's lightweight.

## Chosen path

**Option A with guardrails:**
1. Always state that H-Scale is a custom heuristic, not a standard
2. Always note the rater and context (who rated, when, what they
   had access to)
3. Never use H-Scale ratings in external-facing claims without
   independent verification
4. Review the scale itself quarterly — does it still serve us?
5. When a formal evaluation is needed (regulatory, contractual),
   use the actual standard (CMMI, TRL, SOC2, etc.), not H-Scale

## The meta-lesson

**Using a self-invented rating system to rate your own work and
then citing the rating as evidence of quality is circular.**
The H-Scale is valuable as a thinking tool — it forces honesty
about gaps. It is not valuable as a proof of quality. The proof
is the tests, the code, and the docs. The rating is just a
summary of what the proof says.

## References

- Humphrey, W. (1989). Managing the Software Process. SEI/CMU.
  (Origin of CMM.)
- Mankins, J. (1995). Technology Readiness Levels. NASA.
  (Origin of TRL.)
- Dreyfus, S. & Dreyfus, H. (1980). A Five-Stage Model of the
  Mental Activities Involved in Directed Skill Acquisition.
  (Dreyfus model.)
- No published reference exists for the H-Scale itself. It is
  a project artifact of Valor 2.0 / Monty-CNS development.
