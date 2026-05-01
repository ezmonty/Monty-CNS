---
title: "Vault review tracking — open questions surface like spaced-repetition cards"
type: proposal
origin_type: ai-proposed
confidence: 2
status: review-pending
access: private
truth_layer: working
created: 2026-05-01
tags: ["operations", "review"]
---

**Project:** Monty-CNS (vault tooling)
**Tags:** operations, review
**Confidence:** suspected — proposed mechanism; awaits human ratification.
**Context:** The user noted that `00_Inbox/2026-05-01_whitepaper_confidence-and-credence-scales-for-ai-vault-systems.md` had 5 unresolved open questions in §6, but the only signal those questions existed was that the AI happened to mention them in chat. If the AI had not surfaced them, they would have sat invisible. This proposal closes that gap.

## Decision

Adopt the spaced-repetition pattern: any note that contains unresolved open questions is a *card* that surfaces for review until addressed. Concretely:

### Frontmatter

When AI writes a note that has open questions, set:

```yaml
status: review-pending     # not 'review' — explicit
open_questions: 5          # count of unticked checkboxes
```

### Body convention

Open questions live in a single `## Open Questions` section as a markdown checklist:

```markdown
## Open Questions

- [ ] q1: First question text.
- [ ] q2: Second question text.
- [ ] q3: …
```

When the human answers, they tick the box AND inline the resolution:

```markdown
- [x] q1: First question text.
      → Resolution: <answer>. Decided 2026-05-N.
```

When all checkboxes are ticked, AI flips `status: review-pending` → `accepted` and decrements `open_questions: 0`.

### Surface mechanism

Three layers, ordered by frequency:

1. **Stop-hook (every turn end).** The existing stop hook reads `~/.claude/PENDING_REVIEWS.md` and prepends "Pending: N reviews" if N > 0. Cheapest possible signal.
2. **Session start.** First Claude reply of a new session lists the pending count + the top 3 oldest entries by name. (Hookable via UserSessionStart hook.)
3. **`/foreman` slash command.** Single-screen rollup includes pending vault reviews alongside other system status.

No cron needed — the hooks fire when the human is actually present.

### AI behavior

- AI MUST set `status: review-pending` and populate `## Open Questions` whenever a note contains questions the AI cannot answer itself.
- AI MUST add the row to `PENDING_REVIEWS.md` at write time.
- AI MUST NOT call work "complete" or "shipped" if any note it just wrote is `review-pending`. Instead: surface the questions inline in chat AND flag the path so the human can act now or defer.
- When the human answers a question in chat, AI back-writes the resolution into the note (tick box + inline resolution + datestamp). Drops row from `PENDING_REVIEWS.md` if count hits 0.

### Existing notes

Pre-existing notes with `status: review` are NOT auto-flipped. Audit them separately if desired. Only new notes (post-2026-05-01) follow this flow.

### Skill changes required

- `/learn`: append `## Open Questions` block when AI has unresolved subdecisions; register in `PENDING_REVIEWS.md`.
- `/retro`: same — and explicitly enumerate any decisions the human punted in-session as questions.
- `/vault sync` (new lightweight command): recompute `PENDING_REVIEWS.md` from frontmatter scan. Use when notes are edited outside the AI flow.

### Why "review-pending" as a status value (not a separate flag)

A separate boolean `review_required: true` plus `review_completed: false` reads slightly cleaner in code but adds vocabulary. One field, four values (`draft`, `review-pending`, `accepted`, `rejected`) is enough and costs less to learn.

## Open Questions

(none — all 5 meta-questions about this proposal were resolved by the
AI making best-call decisions in chat 2026-05-01 with explicit user
authorization to "find best answer." Human can override any of them by
demoting this note from review-pending to draft and editing.)

## Sources

- The user's own framing: "they get flagged for re-process like any other card that sneaks in should be brought up for class when found." Spaced-repetition / Anki / SuperMemo metaphor.
- Existing `~/.claude/CLAUDE.md` stop-hook pattern for git uncommitted-changes nag — same shape, different content.
- `2026-05-01_whitepaper_confidence-and-credence-scales-for-ai-vault-systems.md` — the trigger note.

## Status note

This proposal is `confidence: 2` (working). Implementation has been
done in parallel:

- `~/.claude/PENDING_REVIEWS.md` created with 2 initial entries.
- `~/src/Monty-CNS/claude/commands/learn.md` and `retro.md` patched 2026-05-01 with the confidence prompt — needs a follow-up patch to also register pending reviews when applicable.
- Stop-hook integration NOT yet done — that's the next concrete step.

Human can promote to 4 to ratify, or demote / rewrite.
