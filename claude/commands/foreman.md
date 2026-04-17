Single-screen operational status rollup — everything you need to know about the current session state in one view.

## Steps

### 1. Gather State (run all in parallel)

**a. Git**
```bash
git rev-parse --abbrev-ref HEAD && git rev-parse --short HEAD
git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
git diff --cached --numstat | wc -l && git diff --numstat | wc -l
git ls-files --others --exclude-standard | wc -l
```
Capture: branch, short SHA, ahead/behind, uncommitted (staged+unstaged), untracked count.

**b. Tests** — Check `.claude/.last-test-pass`. If exists, read timestamp:
- < 15 min ago → PASS (fresh) | >= 15 min → STALE | Missing → NO RUN

**c. Worklog** — Find newest: `worklog/agent-*.md`, `docs/plans/worklogs/*.md`, or `WORKLOG.md`. Show its last `Status:` line.

**d. Checkpoint** — If `CHECKPOINT.md` exists, extract `Current task:` and `Next steps:` lines.

**e. Vault** — Check `monty-ledger/00_Inbox/` and `~/src/Monty-Ledger/00_Inbox/`. Count files. If neither exists: "No vault found."

### 2. Render Status Card
```
=== FOREMAN STATUS ===

Git:        main @ abc1234 (3 ahead, 0 behind) — 2 uncommitted, 1 untracked
Tests:      PASS (12 min ago) ✓  |  or: STALE (2h ago) ⚠  |  or: NO RUN ✗
Worklog:    Status: done — "Phase 2.A JWT signer"
Checkpoint: "Implementing auth middleware"
Inbox:      3 notes pending review

=== VERDICT ===
PROCEED  — all clear, keep working
```

### 3. Verdict Logic
Evaluate top-down — first matching rule wins:

**STOP** (critical — do not continue):
- On wrong branch (`main`/`master` when work branch expected)
- Secrets in staged files (`sk-`, `ghp_`, `AKIA`, `.env`, `.pem`, `.key`)
- Merge conflicts present (`git diff --check`)

**ESCALATE** (warning — needs attention):
- Tests stale (>15 min) or no test run recorded
- Worklog shows `blocker` or `blocked` status
- More than 10 uncommitted files

**PROCEED** — none of the above triggered.

### 4. Standup Mode (--standup flag)
If `--standup` passed, append after the status card:
```
=== STANDUP ===
Yesterday:  <from git log --since="yesterday" --oneline --no-merges>
Today:      <from Checkpoint current task + next steps>
Blockers:   <from worklog "blocker"/"blocked" entries, or "None">
```
