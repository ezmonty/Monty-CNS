---
title: "W3 Test: sops age key rotation"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: 2026-04-18
tags: ["test", "sops", "security"]
---

When rotating age keys, run sops updatekeys on every encrypted file. Missing even one file means that file becomes undecryptable with the new key.
