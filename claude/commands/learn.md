---
description: Capture a verified, generalizable finding into the Monty-Ledger vault.
---

# /learn — Structured knowledge capture

Capture reusable, tagged knowledge — not raw notes, but distilled findings with metadata.

Target: $ARGUMENTS (the insight to capture)

## Vault rules (from VAULT_RULES.md)

Only save something if it changes how future writing, decisions, planning, or AI support should happen. If it's merely interesting but won't change future output, skip it.

## Steps

### 1. Parse input

If `$ARGUMENTS` is non-empty, use it as the insight. If empty, ask: "What did you learn?"

### 2. Determine metadata

- **Project:** detect from `git remote get-url origin` or `$PWD` basename (e.g., "valor2.0", "Monty-CNS"). Fall back to "general".
- **Tags:** 1-3 tags from the TAG_DICTIONARY at `~/src/Monty-CNS/monty-ledger/TAG_DICTIONARY.md`.
  Topic tags to choose from: `operations`, `strategy`, `finance`, `writing`, `property`, `school`, `relationships`.
  Functional tag always included: `review`.
  Use specific technical terms (e.g., "auth", "jwt") only if no topic tag fits — keep tags broad for retrieval.
- **Date:** today's date as `YYYY-MM-DD`.
- **Confidence:** infer from language, or ask if ambiguous. Values: `verified` (tested/proven), `suspected` (likely but untested), `anecdotal` (heard/observed once).
- **Context:** one sentence about where/how this was discovered.

### 3. Format: title + frontmatter + body

Filename: `YYYY-MM-DD_short-slug-no-special-chars.md`
Title: concise phrase, no punctuation that breaks portability (from NAMING_CONVENTIONS.md).

Frontmatter must include `title:` field (quoted), `created:` (not `date:`), and tags as a JSON string array:

```yaml
---
title: "Short plain title"
type: learning
origin_type: ai-proposed
confidence: 2
status: review
access: private
truth_layer: working
created: YYYY-MM-DD
tags: ["tag1", "tag2"]
---

**Project:** <project>
**Tags:** <tags>
**Confidence:** verified | suspected | anecdotal
**Context:** <one sentence>

<1-3 sentence insight body — direct, structured, retrievable per VAULT_RULES.md Rule 7>
```

### 4. Write to vault (primary path)

Try the `create_inbox_note` MCP tool first:
```
create_inbox_note(
  title: "<short title>",
  content: "**Project:** <project>\n**Tags:** <tags>\n**Confidence:** <confidence>\n**Context:** <context>\n\n<insight body>",
  type: "learning",
  tags: [<tag1>, <tag2>]
)
```

This writes to `monty-ledger/00_Inbox/` AND inserts into Postgres with `origin_type: ai-proposed`, `confidence: 2`, `status: review`.

### 5. Fallback (if MCP unavailable)

If `create_inbox_note` is not available or fails, detect vault path in this order:
1. `~/src/Monty-CNS/monty-ledger/00_Inbox/` — primary (CNS repo)
2. `$PWD/monty-ledger/00_Inbox/` — project-local
3. `~/src/Monty-Ledger/00_Inbox/` — legacy path
4. Append to `~/.claude/LEARNINGS.md` as last resort

Write using the exact frontmatter format above (Step 3).

### 6. Confirm

Print the formatted entry, then state which path was used. One of:
- "Saved to vault inbox." (MCP path)
- "Saved to ~/src/Monty-CNS/monty-ledger/00_Inbox/<filename>."
- "Saved to LEARNINGS.md (vault unavailable)."
