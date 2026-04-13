---
description: Quick capture to working notebook — tag, save, confirm, keep flow.
---

# /note — Quick capture to working notebook

Capture ideas, tangents, and inspiration during a workflow without breaking flow.

Target: $ARGUMENTS (the thought to capture)

## Resolving the notebook location

Use the first of these that exists or can be created:

1. `$NOTES_FILE` — explicit override
2. `${CLAUDE_PROJECT_DIR:-$PWD}/NOTES.md` — project-local notebook
3. `$HOME/NOTES.md` — personal notebook

Prefer project-local for project-specific thoughts; fall back to `$HOME/NOTES.md` when there's no project context or when the thought is about life/workflow in general.

## Steps

### 1. Parse and tag

Read the user's text. Auto-detect 1-2 tags based on content:

- `#idea` `#product` — business / product ideas
- `#insight` `#tech` — technical realizations
- `#bug` — something broken worth following up on
- `#question` `#research` — things to look into
- `#tangent` — random but worth keeping
- `#inspiration` — sparked by something seen / heard
- `#decision` — a choice made, with context

### 2. Append to the notebook

Open the resolved notebook file, append at the bottom:

```
### YYYY-MM-DD #tag Title
The thought, lightly cleaned up.
- Context: what prompted this
- Action: next step or "capture only"
```

Create the file with a top-level `# Notes` header if it doesn't exist.

### 3. Confirm

Say briefly: `Noted. #tag — Title` — one line, they're in flow, don't interrupt.

## Rules

- **Don't break flow.** This command should feel instant. No questions, no "did you mean...", no paragraph-long confirmations.
- **Never overwrite.** Always append.
- **Don't commit.** Leave that to the user or `/commit`.
- **Lightly clean up.** Fix obvious typos, but preserve their voice. Don't editorialize.
