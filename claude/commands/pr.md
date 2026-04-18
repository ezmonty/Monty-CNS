---
description: Create a well-structured pull request with quality checks.
---

Create a well-structured pull request with quality checks.

Target: $ARGUMENTS (base branch, or empty for main/master)

## Step 1: Analyze All Changes
```bash
git log main..HEAD --oneline
git diff main..HEAD --stat
```
Read EVERY commit. Understand the full story — what's the theme?

## Step 2: Pre-PR Quality Gate
Run and fix before creating PR:
- **Tests**: Run the project's test suite
- **Lint**: Run the project's linter
- **Build**: Run build if applicable
- **Secrets scan**: Scan diff for API keys, tokens, passwords, `.env` contents
- **Debug artifacts**: Check for `console.log`, `print()`, `debugger`, `breakpoint()`

## Step 3: Write the PR
**Title**: Under 70 chars, describes the WHAT.

**Body**:
```markdown
## Summary
- [What changed and WHY — 1-3 bullets]

## Changes
- [Key changes by area]

## Test Plan
- [ ] Tests pass
- [ ] [Specific verification steps]
```

## Step 4: Push and Create
```bash
git push -u origin <current-branch>
```
Create PR using available GitHub tools.

## Step 5: Post-PR
- Show PR URL
- Ask: "Want me to watch for CI results and review comments?"
