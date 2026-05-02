---
type: incident
status: review
origin_type: ai-proposed
confidence: 3
demoted_from: 4
demoted_at: 2026-05-02
demoted_reason: "AI self-set without human Type-2 verification — demoted per VAULT_RULES confidence scale"
access: private
truth_layer: working
tags: [security, deny-list, shell, edge-cases, harness]
date: 2026-05-01
---

# Empty SCOPE_FILES silently bypasses any deny-list using fixed-string contains

In the Layer-2 meta-agent bootstrap, the deny-list check was structured as: "for each path in DENY, check if it appears in SCOPE_FILES." If `SCOPE_FILES` was empty (no files matched the meta-agent's scope pattern, or the upstream filter returned nothing), every `grep -F -q "$denied_path" <<< "$SCOPE_FILES"` returned **false** — meaning **nothing was denied**, and the agent could then write-anywhere as a side effect of "we didn't find a match."

**The bug class:** any deny-list that asks "is this denied path mentioned in this haystack?" silently inverts when the haystack is empty. The default-deny posture flips to default-allow precisely when the input is degenerate.

**Fix patterns that survive empty inputs:**
1. **Fail closed on empty:** `if [ -z "$SCOPE_FILES" ]; then echo "FATAL: empty scope" >&2; exit 1; fi`
2. **Iterate over scope, not over deny-list:** for each scope file, check if it matches any deny pattern. Empty scope -> empty loop -> nothing happens (correct).
3. **Use full-path + basename matching with case-insensitivity:** path/to/Settings.json should also match `settings.json` in the deny-list, regardless of case.

**Generalizable rule:** when writing a deny-list, always test the empty-input case explicitly. Three test cases minimum: (a) empty input, (b) input containing exactly one denied item, (c) input containing only allowed items. The empty case is the one that gets skipped during normal development because "of course there's something in the input" — until production hits a degenerate case.

This same shape applies to JSON Schema "additionalProperties: false", iptables ACCEPT/DROP defaults, and CORS allowlists.
