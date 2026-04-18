---
description: Capture a verified, generalizable finding into the Monty-Ledger vault.
---

# /learn — Structured knowledge capture

Capture reusable, tagged knowledge — not raw notes, but distilled findings with metadata.

Target: $ARGUMENTS (the insight to capture)

## Steps

### 1. Parse input

If `$ARGUMENTS` is non-empty, use it as the insight. If empty, ask: "What did you learn?"

### 2. Determine metadata

- **Project:** detect from `git remote get-url origin` or `$PWD` basename (e.g., "valor2.0", "Monty-CNS"). Fall back to "general".
- **Tags:** infer 1-3 topic tags from the content (e.g., `auth`, `sops`, `performance`, `shell`, `git`, `docker`, `testing`).
- **Date:** today's date as `YYYY-MM-DD`.
- **Confidence:** infer from language, or ask if ambiguous. Values: `verified` (tested/proven), `suspected` (likely but untested), `anecdotal` (heard/observed once).
- **Context:** one sentence about where/how this was discovered.

### 3. Format as short title + body

Title: a concise phrase (e.g., "JWT RS256 needs full cert chain").
Body: 1-3 sentences explaining the insight.

### 4. Write to vault (primary path)

Try the `create_inbox_note` MCP tool first:
```
create_inbox_note(
  title: "<short title>",
  content: "**Project:** <project>\n**Tags:** <tags>\n**Confidence:** <confidence>\n**Context:** <context>\n\n<insight body>",
  type: "learning",
  tags: [<tag1>, <tag2>, <project>]
)
```

This writes a markdown file to `monty-ledger/00_Inbox/` AND inserts into Postgres with `origin_type: ai-proposed`, `confidence: 2`, `status: review`.

### 5. Fallback (if MCP unavailable)

If the `create_inbox_note` tool is not available or fails:
- Detect vault path: check `$PWD/monty-ledger/00_Inbox/`, then `~/src/Monty-Ledger/00_Inbox/`
- If found, write the file directly with frontmatter (type: learning, origin_type: ai-proposed, confidence: 2, status: review, access: private, truth_layer: working)
- If no vault found, append to `~/.claude/LEARNINGS.md` as last resort

### 6. Confirm

Print the formatted entry, then: **"Saved to vault inbox."** (or "Saved to LEARNINGS.md (vault unavailable).")
Report which path was taken so the user knows.
