---
type: pattern
status: review
origin_type: ai-proposed
confidence: 3
demoted_from: 4
demoted_at: 2026-05-02
demoted_reason: "AI self-set without human Type-2 verification — demoted per VAULT_RULES confidence scale"
access: private
truth_layer: working
tags: [valor, harness, security, adversarial-review, meta-tools, hooks]
date: 2026-05-01
---

# Adversarial review on hooks/meta-tools > self-review (7 CRITICAL caught)

When building tools that **modify Claude's own behavior** (precommit hooks, meta-agents, harness extensions, slash-command implementations), self-review is monoculture: the author and the reviewer share a mental model of the tool, so they share the same blind spots. Running `adversarial-reviewer` (a hostile-persona review skill) on the self-improving-harness diff caught **7 CRITICAL** findings before commit:

1. Bypass log in `/tmp` — symlink-attackable; moved to `~/.local/state/valor/` with append-only mode
2. Git-commit detection via regex — bypassable by `/usr/bin/git`, `git -c`, `git -C`, `--git-dir`. Replaced with `shlex` + structured arg parse
3. First-match verdict — spoofable by injecting "VERDICT: PASS" earlier in output. Replaced with worst-severity escalation
4. Sanitizer gaps — no NFKC normalization, no zero-width unicode strip, no 8-bit CSI handling
5. Diff fed to reviewer without XML fencing — prompt-injection vector via diff content
6. Empty `SCOPE_FILES` silently bypassed the entire deny-list (fixed-string contains over empty string == false)
7. Missing prompt-injection marker list — only checked a few patterns

**Rule:** any tool that runs in the loop where Claude reviews/commits/deploys code must be reviewed *as if it were adversarial input itself*. Self-review on this category is a coin flip. Adversarial-review on this category is non-optional.

**Heuristic for "this needs adversarial-review":** does the file appear in any of (`hooks/`, `agents/*-improver*`, `settings.json`, `.github/workflows/`, anywhere that `bash` is `eval`'d on AI-generated text)? If yes, run adversarial-review before merge — even if all tests pass.

The 7-CRITICAL haul is the pattern, not the outlier.
