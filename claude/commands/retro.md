---
description: End-of-session retrospective — extract learnings and write structured vault notes.
---

# /retro — Session retrospective

Synthesize what happened this session into a structured retrospective note.

## Steps

### 1. Gather session data

- Run `git log --oneline` for commits this session (since last CHECKPOINT.md timestamp, or last 2 hours).
- Read `CHECKPOINT.md` if it exists.
- Read any worklog entries from this session.
- Count files changed, tests run, errors encountered.

### 2. Synthesize into three sections

- **Accomplished:** bullet list of what was done (derived from commits).
- **Learned:** generalizable insights discovered. Call `/learn` for each one.
- **Next time:** what should be different, what's unfinished, what was harder than expected.

### 2.5. Confidence prompt (REQUIRED before save)

Before writing the retro note, present the proposed metadata to the
human and prompt for confidence override. Format:

```
About to save retro: "Retro - <project> - <date>"
Confidence default: 2 (working — AI-proposed; unverified)

Override? Reply with "default" or 1-5:
  1  speculative   could be wrong; capture as hypothesis
  2  working       AI-proposed default; unverified
  3  supported     evidence in-body; AI ceiling without human verify
  4  verified      you've reviewed and confirmed (HUMAN-ONLY)
  5  canonical     load-bearing / foundational (HUMAN-ONLY)
```

Same rules as `/learn` step 3.5 — AI must NOT auto-promote to 4 or 5.
The same prompt should also fire once per discovered learning before
calling `/learn` so each one gets a confidence opportunity, not a
batch default.

### 3. Write retrospective note

**Primary (MCP):** Use `create_inbox_note` MCP tool:
```
create_inbox_note(
  title: "Retro - <project> - <date>",
  content: <the three sections + stats>,
  type: "retro",
  tags: ["retro", "<project>"]
)
```

**Fallback (direct file):** If MCP fails, detect vault path — check `$PWD/monty-ledger/00_Inbox/`, then `~/src/Monty-Ledger/00_Inbox/`. Write with frontmatter:

```yaml
---
type: retro
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [retro, <project>]
---
```

- Body contains the three sections from step 2, plus session stats (files changed, commits, duration).

### 4. Confirm

Print a summary: accomplishments count, learnings captured, and where the retro was saved.
