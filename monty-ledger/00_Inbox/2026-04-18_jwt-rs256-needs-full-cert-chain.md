---
title: "JWT RS256 needs full cert chain"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-04-18
tags: ["auth", "jwt", "crypto"]
---

**Project:** Monty-CNS
**Tags:** auth, jwt, crypto
**Confidence:** verified
**Context:** Discovered during Valor GitHub App plan review

When signing JWTs with RS256, the private key PEM must include the full certificate chain, not just the leaf key. OpenSSL and PyJWT both silently fail with truncated chains.
