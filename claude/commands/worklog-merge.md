---
description: Merge distributed worklog scratch files into the master worklog.
---

Merge distributed worklog scratch files into the master worklog.

Target: $ARGUMENTS (unused)

## Steps

### 1. Find Scratch Files
```bash
ls worklog/agent-*.md 2>/dev/null
```
If no files match, report "No scratch worklogs to merge." and stop.

### 2. Validate Every Scratch File (all-or-nothing)
Read each `worklog/agent-*.md`. For each file, verify:
- It contains at least one `## <timestamp>` heading
- Every entry has a `Status:` line
- Collect any task IDs; if duplicates exist across files, abort

If ANY file fails validation, abort immediately. Report which file failed and why. Do not merge anything.

### 3. Collect and Sort Entries
Parse all `## <timestamp>` entries from all scratch files. Sort them chronologically by timestamp (earliest first).

### 4. Detect Master Worklog Path
Choose the first match:
1. If `docs/plans/worklogs/` exists and contains `*.md` files, use the most recently modified one
2. Else if `WORKLOG.md` exists at repo root, use that
3. Else create `WORKLOG.md` at repo root

### 5. Append Entries
Append all sorted entries to the end of the master worklog. Separate with a blank line before the first new entry.

### 6. Archive Scratch Files
```bash
mkdir -p worklog/.merged/$(date +%Y-%m-%d)
mv worklog/agent-*.md worklog/.merged/$(date +%Y-%m-%d)/
```

### 7. Stage Changes
```bash
git add <master-worklog-path>
git add worklog/.merged/
git rm --cached worklog/agent-*.md 2>/dev/null || true
```
Only stage — do NOT commit. Let the user decide when to commit.

### 8. Report
Print:
> Merged N entries from M scratch files into `<master-path>`. Archived originals to `worklog/.merged/<date>/`.
