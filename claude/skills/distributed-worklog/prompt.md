# Distributed Worklog Pattern

## Problem

When multiple Claude Code subagents work in parallel and write to a single `WORKLOG.md`, they collide. One agent's write overwrites another's, causing merge conflicts and lost entries.

## Solution

Each agent session writes to its own scratch file instead of the shared worklog:

```
worklog/agent-<session-id>.md
```

Naming convention: `agent-<first-8-chars-of-session-id>.md` (e.g. `agent-a1b2c3d4.md`).

## Scratch File Format

Each scratch file uses the same format as a normal worklog entry:

```markdown
## 2025-06-15T14:32:00Z -- agent-a1b2c3d4 -- Implement auth middleware

Status: complete
Notes: Added JWT validation to all /api routes. Tests pass.
```

Every entry must have a `## <timestamp>` heading and a `Status:` line.

## When to Use

- You are a subagent spawned in parallel with others
- You see a `worklog/` directory already containing `agent-*.md` scratch files
- The project CLAUDE.md or worklog instructions mention distributed logging

Always check for `worklog/` before writing to a shared `WORKLOG.md`. If the directory exists, use a scratch file.

## When to Merge

- The user runs `/worklog-merge`
- At session end, if all your tasks are complete and you are the last active agent

Do not merge if other agents are still running. The merge is all-or-nothing: if any scratch file has validation errors, the entire merge aborts.

## Archive

After a successful merge, scratch files move to `worklog/.merged/<YYYY-MM-DD>/` so they remain available for audit without cluttering the active directory.
