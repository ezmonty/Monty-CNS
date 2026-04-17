---
description: Capture a verified, generalizable finding into a persistent LEARNINGS.md knowledge base.
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

### 3. Format entry

```markdown
### <short title>
- **Project:** <project>
- **Tags:** <tag1>, <tag2>
- **Confidence:** <verified|suspected|anecdotal>
- **Date:** <YYYY-MM-DD>
- **Context:** <where discovered>

<the insight, 1-3 sentences>
```

### 4. Append to LEARNINGS.md

- If `~/.claude/LEARNINGS.md` exists, append the entry after a `---` separator.
- Otherwise, create `~/.claude/LEARNINGS.md` with header `# Learnings\n\nPersistent knowledge captured across sessions.\n\n---\n` then append.

**Never overwrite.** Always append.

### 5. Confirm

Print the formatted entry, then: **"Saved to LEARNINGS.md. N total entries."** (count `###` headings in the file).
