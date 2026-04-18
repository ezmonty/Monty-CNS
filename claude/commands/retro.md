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
