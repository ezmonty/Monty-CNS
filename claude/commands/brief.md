---
description: Structured cross-session handoff document — replaces manual copy-paste between sessions.
---

# /brief — Session briefing for handoff

Generate a structured briefing so the next session can pick up where this one left off.

## Steps

### 1. Gather context

- Current branch, HEAD, uncommitted changes.
- Last 5 commits with messages.
- `CHECKPOINT.md` contents (if exists).
- Active worklog entries.
- Any recent `/learn` entries from this session.

### 2. Generate structured briefing

```markdown
# Session Briefing — <project> — <date>

## What was done
<bullet list from commits>

## Key decisions made
<any architectural or design decisions>

## In-flight work
<branches, uncommitted changes, partial implementations>

## Blockers / open questions
<anything unresolved>

## Recommended next steps
<prioritized list>

## Context the next session needs
<files to read, concepts to understand, gotchas>
```

### 3. Save the briefing

Write to `~/src/Monty-Ledger/00_Inbox/Brief - <project> - <date>.md` (or `monty-ledger/00_Inbox/`). Frontmatter:

```yaml
---
type: brief
status: active
origin_type: ai-generated
access: private
truth_layer: working
---
```

### 4. Confirm

Print: **"Briefing saved. Next session will see this automatically."**
