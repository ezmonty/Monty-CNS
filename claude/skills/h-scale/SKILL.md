---
name: h-scale
description: Rate code, features, or systems against the Capability Honesty Scale (H1-H5). A framework for being brutally honest about where you actually are vs where you're pretending to be. Use when the user wants to assess readiness, plan upgrades, or sanity-check claims of "production-ready".
---

# H-Scale — Capability Honesty Rating

Target: $ARGUMENTS (file path, feature, component, or "system")

## The Scale

```
H1 — STUB           Placeholder / mock / hardcoded. Never show to users.
H2 — APPROXIMATION  Directionally correct, uses shortcuts. Show with caveat.
H3 — FUNCTIONAL     Correct methodology, limited scope / data. Usable with awareness.
H4 — PRODUCTION     Correct method, real data, tested. Client-facing ready.
H5 — AUDITED        Production + independently verified. Certified / regulated.
```

## Evaluation Axes

Rate the target on all four axes. The overall score is the **lowest** axis — weakest link wins.

### Methodology — is the math/logic right?

- **H1:** No real computation. Hardcoded values, stubs, random.
- **H2:** Simplified formula or heuristic proxy.
- **H3:** Correct published methodology. Cite the source.
- **H4:** Correct + validated against known-good results.
- **H5:** Correct + third-party audited.

### Data Quality — is the input real?

- **H1:** Hardcoded or random.
- **H2:** Synthetic / simulated.
- **H3:** Real but limited (partial history, single source, small sample).
- **H4:** Production feeds, reconciled, monitored.
- **H5:** Audited data with chain of custody.

### Testing — is it verified?

- **H1:** No tests.
- **H2:** Compiles / imports / lints clean.
- **H3:** Smoke tests + basic structural verification.
- **H4:** Unit + integration + adversarial tests + edge cases.
- **H5:** Independent verification + regression suite + continuous monitoring.

### Documentation — can someone else understand and use it?

- **H1:** No docs.
- **H2:** Minimal docstring / README.
- **H3:** Docstring + limitations + references.
- **H4:** Full methodology doc + citations + upgrade path + runbook.
- **H5:** Published methodology / regulatory filing.

## Report Format

```
H-SCALE RATING: <component name>
════════════════════════════════
  Methodology:   H<N> — <one-line reason>
  Data Quality:  H<N> — <one-line reason>
  Testing:       H<N> — <one-line reason>
  Documentation: H<N> — <one-line reason>
  ─────────────────────
  OVERALL:       H<N>  (weakest link)

Limitations
  - <brutal honesty about what's weak>
  - <what could bite you>

Upgrade path
  - H<N+1>: <specific things needed to move up>
  - H<N+2>: <stretch goal>

References
  - <papers, docs, standards — required for H3+>
```

## Rules

- **Be brutal.** An H2 is not a failure — it's honesty. Pretending an H2 is H4 is the failure.
- **The point is knowing where you are**, not pretending you're further along.
- **Every rating must include a concrete upgrade path** — "here's how to get to the next level".
- **H3+ requires citations.** If you can't name the source, you're at H2.
- **Client-facing claims require H4 minimum.** Anything H3 or below needs an explicit caveat on the page.
- **Regulatory / compliance claims require H5.** Anything less is fraud waiting to happen.

## Limitations and Provenance

The H-Scale is a **custom heuristic**, not a published standard.
It draws loosely from CMM/CMMI (SEI), TRL (NASA), and the Dreyfus
skill model, but is not any of those frameworks formally. It has:
- No inter-rater reliability testing
- No peer review or publication
- Arbitrary axes and levels (why 4 axes? why 5 levels?)
- No measure of value, impact, user experience, or architecture quality

It is useful as a **thinking tool** that forces honesty about gaps.
It is NOT useful as proof of quality — the proof is the tests, the
code, and the docs. The rating is just a summary.

Always state when reporting: "H-Scale is a custom heuristic, not
a formal standard. Rated by [who] on [date] with [context]."

See: `monty-ledger/04_Decisions/Decision - H-Scale Adoption and
Limitations - 2026-04-18.md` for the full analysis.

## When to Use

- Before shipping a feature to customers.
- When planning a quarter — what's H2 today that needs to be H4 in 3 months?
- When a claim feels too good. Rate it. If the rating is honest, the claim adjusts itself.
- As a post-mortem lens — what was this incident's real H-level?
