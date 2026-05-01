# Pending vault reviews

Auto-maintained rolling list of vault notes with `status: review-pending`
AND open_questions > 0. Stop hook surfaces the count at every turn end.

When a note's open questions all close (all `- [ ]` ticked to `- [x]`),
AI flips its `status:` to `accepted`, sets `open_questions: 0`, and
removes the row here.

| Note | Created | Open Q | Owner |
|---|---|---|---|
| `monty-ledger/00_Inbox/2026-05-01_whitepaper_confidence-and-credence-scales-for-ai-vault-systems.md` | 2026-05-01 | 5 | human |

## How to close

1. Open the note.
2. For each `- [ ] qN: ...` checkbox in `## Open Questions`: write the answer inline as `→ Resolution: <answer>. Decided <date>.` and tick the box.
3. Save. Next time `/learn`, `/retro`, or `/vault sync` fires (or just edit `open_questions:` count by hand) the row drops from this file.

## Surface points

- **Stop hook** (every turn end): one-line "Pending: N reviews" prepended to existing git-check output.
- **`/foreman`**: included in single-screen rollup.
- **Session start**: should mention the count + top 3 oldest. (UserSessionStart hook integration TBD.)
