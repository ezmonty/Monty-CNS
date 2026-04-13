---
description: Progressive review of working notes — distill insights, surface connections, suggest action items.
---

# /note-review — Progressive review of working notes

Surface relevant ideas, distill insights, connect dots across your notebook. Uses **Progressive Summarization** (Tiago Forte): each review distills further — raw capture → highlighted essentials → core insights → action items.

## Resolving the notebook location

Same lookup as `/note`:

1. `$NOTES_FILE`
2. `${CLAUDE_PROJECT_DIR:-$PWD}/NOTES.md`
3. `$HOME/NOTES.md`

If none exist, report that there's nothing to review and suggest `/note` to start capturing.

## Steps

### 1. Load notes

Read the notebook. Parse entries (each starts with `### YYYY-MM-DD #tag Title`).

### 2. Present the review

```
═══════════════════════════════════════
  NOTE REVIEW — YYYY-MM-DD
  [X] notes | [Y] need attention
═══════════════════════════════════════

🔥 RELEVANT TO CURRENT WORK
  - [note title] — [why it connects to what's happening now]

💡 DISTILLED INSIGHTS
  - [note] → [one-sentence core takeaway]

🔗 CONNECTIONS (notes that combine into something bigger)
  - [note A] + [note B] → [new insight that emerges]

📋 READY TO ACT ON
  - [note] → suggested next step: [concrete action]

💤 ARCHIVE (old, no connections, no action)
  - [note] — captured [X days ago]
```

### 3. Surface connections to the current session

Check the conversation context. If any note relates to what the user is currently working on, call it out explicitly:

> Your note from [date] about [X] connects here because [reason]. Want to pull it in?

### 4. Update maturity markers

For reviewed notes, add a `Reviewed: YYYY-MM-DD` line below the note. If an insight was extracted, note it inline:

```
### 2026-03-15 #tech Better cache invalidation pattern
...
Reviewed: 2026-04-13
Insight: tag-based invalidation is cleaner than TTL for this workload
```

### 5. Offer to clean up

- **Archive** notes flagged 💤 (move to `NOTES.archive.md` in the same directory, or add an `Archived:` line).
- **Promote** `📋 READY TO ACT ON` items into a task tracker if one exists (TODO file, issue tracker, etc.).

## Rules

- **Don't rewrite the user's thoughts.** Distill, don't replace.
- **Be selective.** Don't show every note — surface what matters today.
- **Respect the second-brain loop:** capture → review → distill → recall → apply. Each review should move notes along that loop, not just re-display them.
- **Never delete without confirmation.** Archive is reversible; deletion isn't.
