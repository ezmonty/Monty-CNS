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

### 3. Query recent learnings (if vault MCP available)

If `query_notes` MCP tool is available, query recent learnings:
```
query_notes(type: "learning", limit: 5)
```
Add a "Recent Learnings" section to the briefing with the results.

### 4. Save the briefing

**Primary (MCP):** Use `create_inbox_note` MCP tool:
```
create_inbox_note(
  title: "Brief - <project> - <date>",
  content: <the full briefing markdown>,
  type: "brief",
  tags: ["brief", "<project>"]
)
```

**Fallback (direct file):** Detect vault path — check `$PWD/monty-ledger/00_Inbox/`, then `~/src/Monty-Ledger/00_Inbox/`. Write with frontmatter:
```yaml
---
type: brief
status: active
origin_type: ai-generated
access: private
truth_layer: working
tags: [brief, <project>]
---
```

**Last resort:** If no vault found, write to `~/.claude/briefings/<project>-<date>.md` and warn user.

### 5. Confirm

Print: **"Briefing saved to vault inbox."** (or fallback location).
Report which path was taken.
