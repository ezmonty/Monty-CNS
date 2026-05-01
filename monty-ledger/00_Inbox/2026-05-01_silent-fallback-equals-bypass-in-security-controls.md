---
title: "Silent fallback paths in security controls are bypass branches"
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
**Context:** Building Valor's two-layer secret-handling system. Adversarial review verdict was BLOCK — five of the findings were silent-fallback paths I'd shipped without flinching: import failure → set `_AVAILABLE=False` and fall through; audit DB unreachable → swallow exception; missing pepper → use a dev default. Each one would have made the security control a no-op under the precise conditions an adversary tries to provoke.

When shipping any security control, every code path that catches an exception or notices a missing dependency is a *bypass branch* unless it raises. Logging-and-continuing makes the failure mode "no security" rather than "loud error." Default to fail-closed; require explicit env-flag opt-in (e.g. `VALOR_REQUIRE_GATE=false`) before *any* fallback path executes — and even then, keep the cheapest layer of defense (URL allowlist, audit log) mandatory. A silent-fallback control is strictly worse than no control: it gives a false sense of coverage while shipping the bypass.
