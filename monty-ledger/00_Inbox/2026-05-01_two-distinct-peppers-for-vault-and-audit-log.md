---
title: "Use two distinct peppers when audit log references vaulted content"
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
**Context:** Designing `egress_scrub_log` to record handle-leak events for the secrets vault. Naive design: log the raw handle, or log a single-pepper HMAC of it. Adversarial review pointed out: if the handle pepper leaks, the audit log becomes a perfect rainbow table back into the vault. Fix shipped: `VALOR_SECRET_VAULT_PEPPER` for handle generation; **distinct** `VALOR_SCRUB_LOG_PEPPER` for the `handle_hmac` column in the audit log. Different env vars, rotatable independently.

Whenever you have (a) encrypted-at-rest content with an opaque handle and (b) an audit log that references that handle, use **two distinct peppers**: one for handle generation, one for any HMAC-keyed field in the audit/log table. Even if both are stored on the same host, rotation can be staggered, and an attacker who exfiltrates one pepper doesn't get to invert the other. Default pattern any time "encrypted vault" + "audit telemetry mentioning vault entries" coexist.
