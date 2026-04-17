Smart commit workflow — stage, verify, and commit with a well-structured message.

Target: $ARGUMENTS (optional commit message hint, or empty for auto-generated)

## Steps

### 0. Test Gate Check
Before anything else, check for `.claude/.last-test-pass`:
- **File exists and timestamp is less than 15 minutes old** → proceed normally.
- **File exists but timestamp is older than 15 minutes** → warn: "Test results are stale (>15 min old). Run `/pre-commit` again." Ask the user whether to continue — if they say "commit anyway", proceed.
- **File does not exist** → warn: "No recent `/pre-commit` pass found. Run `/pre-commit` first." Ask the user whether to continue — if they say "commit anyway", proceed.

This check is advisory, not blocking — the user can always override.

### 1. Assess What Changed
```bash
git status
git diff --stat
git diff --cached --stat
```
Categorize: new files, modified files, deleted files.

### 2. Stage the Right Files
Stage all relevant changed files. NEVER stage:
- `.env`, `.env.*`, credentials, secrets, `.pem`, `.key` files
- `node_modules/`, `__pycache__/`, `.pyc`, `.o`, `.so` files
- Database files (`.db`, `.sqlite`, `.sqlite3`)
- Large binary files, build output (`dist/`, `build/`)
If unsure whether a file should be committed, ask the user.

### 3. Quick Verification
**Python files changed?**
```bash
python3 -m py_compile <each staged .py file>
```

**JavaScript/TypeScript files changed?**
Look for a lint command in package.json and run it.

**Go/Rust/etc.?**
Run the language-appropriate compiler check.

If verification fails: fix the issue, re-stage, then continue.

### 4. Generate Commit Message
Read the diff and write a message following this format:
```
<type>: <short description> (under 72 chars)

<body — what changed and WHY, not just what files>
```

Types:
- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — restructuring without behavior change
- `test` — adding or updating tests
- `docs` — documentation changes
- `chore` — config, deps, tooling
- `style` — formatting, lint fixes

If $ARGUMENTS contains a hint, incorporate it into the message.

### 5. Commit
```bash
git add <specific files>
git commit -m "<message>"
```

### 6. Confirm
Show: commit hash, message, files included.
Ask: "Want me to push this to the remote?"
