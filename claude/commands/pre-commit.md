Run all verification checks before committing — tests, lint, build, secrets scan.

## Steps (run ALL in order — stop on first failure)

### 1. What's Being Committed?
```bash
git status
git diff --cached --stat
```
If nothing is staged, check unstaged changes and warn the user.

### 2. Run Tests
Detect the test framework and run it:
- Python: `pytest -v` or `python -m pytest -v`
- Node: `npm test` or `npx jest` or `npx vitest`
- Go: `go test ./...`
- Rust: `cargo test`
- Check package.json scripts or Makefile for custom test commands

ALL tests must pass. If any fail → report which tests and the error, STOP.

### 3. Syntax/Type Check (all staged files)
**Python:** `python3 -m py_compile <file>` for each `.py`
**TypeScript:** Check for `tsc --noEmit` or build command
**Go:** `go vet ./...`

### 4. Lint (if configured)
Look for lint config in the project and run it:
- `.eslintrc*` → `npx eslint`
- `pyproject.toml` with ruff/flake8 → `ruff check` or `flake8`
- `.golangci-lint.yml` → `golangci-lint run`
- `package.json` scripts → `npm run lint`

### 5. Build (if applicable)
If there's a build step, run it:
- `npm run build`
- `cargo build`
- `go build ./...`

### 6. Secrets Scan
Scan ALL staged files for:
- Patterns: `sk-`, `ghp_`, `ghu_`, `AKIA`, `Bearer `, `token=`, `password=`, `API_KEY=`, `SECRET`
- File types: `.env`, `.pem`, `.key`, `credentials`, `secrets`
If ANY found → **STOP. Do not commit. Show what was found.**

### 7. Debug Artifact Scan
Scan staged files for:
- Python: `breakpoint()`, `pdb`, `print()` debugging
- JS/TS: `console.log`, `console.debug`, `debugger`
- General: `TODO`, `FIXME`, `HACK`, `XXX` without explanation
Report as warnings (don't block, just flag).

### 8. Test Gate Marker
If ALL checks above passed (no failures):
- Write the current ISO 8601 timestamp (e.g. `2026-04-17T14:32:00Z`) on a single line to `.claude/.last-test-pass` (create the file and directory if needed).

If ANY check FAILED:
- Delete `.claude/.last-test-pass` if it exists.
- Include in the failure output: "Tests failed. The test gate marker has been removed. `/commit` will require a passing `/pre-commit` first."

### 9. Summary
```
Pre-commit results:
─────────────────────
  Tests:       ✓ passed
  Syntax:      ✓ valid
  Lint:        ✓ clean
  Build:       ✓ success
  Secrets:     ✓ none found
  Debug:       ⚠ 2 console.log (warning)
─────────────────────
  RESULT: Ready to commit
```

If everything passes: "All checks passed. Run /commit to finalize."
