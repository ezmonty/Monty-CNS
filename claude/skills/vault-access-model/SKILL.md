---
name: vault-access-model
description: Teaches the vault's access classification, truth layers, mask levels, and role modes. Use when reading from or writing to the Monty-Ledger vault to ensure correct metadata defaults and access constraints.
license: MIT
---

# Vault Access & Truth-Layer Model

## Access Classes

| Class      | Meaning                                      |
|------------|----------------------------------------------|
| **public** | Safe for broad use — shareable, non-sensitive |
| **private**| Personal / internal; the default for all new notes |
| **secret** | Restricted — only surfaced when explicitly requested |
| **hidden** | Not routinely surfaced; exists but stays below the waterline |

## Truth Layers

| Layer       | Meaning                                          |
|-------------|--------------------------------------------------|
| **raw**     | Immediate, unprocessed observation or feeling     |
| **working** | Current interpretation or synthesis; the default  |
| **output**  | Intentionally produced artifact (essay, decision) |
| **hidden**  | Not yet integrated into the working model         |

## Mask Levels

`none` — full transparency | `low` — light filtering | `medium` — significant filtering | `high` — heavy redaction or abstraction.

## Role Modes

`self` · `owner` · `executive` · `veteran` · `student` · `strategist` · `relational` · `public-facing`

The **executive** default posture is **restrained-authoritative** — the Marcus Aurelius archetype: calm, measured, decisive, never performative.

## Writing Defaults

When creating a new vault note, always apply these defaults unless the human overrides:

```yaml
access: private
truth_layer: working
origin_type: ai-proposed
confidence: 2
```

## Hard Constraints

1. **Never write `access: secret` or `access: hidden`.** Only a human promotes notes to those levels.
2. **Never set `confidence` above 3** without explicit human verification.
3. When uncertain about classification, prefer the more restrictive access class.
4. Always tag `origin_type: ai-proposed` on AI-generated content so the human can distinguish it.
