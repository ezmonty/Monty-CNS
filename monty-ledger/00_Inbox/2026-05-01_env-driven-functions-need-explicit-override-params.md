---
title: "Env-flag-driven functions need explicit override parameters for tests"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "review"]
---

**Project:** valor2.0
**Tags:** operations, review
**Confidence:** verified
**Context:** `scrub_for_egress(payload, ...)` reads `VALOR_EGRESS_FAIL_CLOSED` from env to decide whether to raise on a hit. Tests verifying redaction behavior were written with the env-flag implicitly off. When production flipped the flag to true, the same tests started raising `EgressViolation` and broke. Fix: added `fail_closed_override: Optional[bool] = None` parameter — `None` honors env, `False` forces observe-only, `True` forces fail-closed. Tests now pin behavior independent of caller env. The dedicated raise-path test still exists and exercises the env-true path.

Whenever a function's behavior is gated by a process-wide env flag (`VALOR_*_ENABLED`, `DEBUG`, `STRICT_MODE`), expose an explicit override parameter from day one — `Optional[bool]` defaulting to `None` (= "honor env"). Tests should pin the override; production code should leave it `None`. Without this, every env-flag flip in prod silently changes the test surface and you can't run "test the redaction path" + "test the raise path" in the same suite without monkeypatching env per test. Cheap to design in; painful to retrofit.
