Fix a GitHub issue end-to-end — read it, find the code, fix it, test it, commit it.

Issue: $ARGUMENTS (issue number, URL, or description)

## Step 1: Understand the Issue
- If a GitHub issue number/URL is given, read the issue title, body, and comments
- Identify: bug fix, feature request, or improvement?
- Note reproduction steps and error messages

## Step 2: Find the Relevant Code
- Search the codebase for files mentioned in the issue
- If a traceback is given, go directly to the file:line
- Read surrounding context
- Check for existing tests

## Step 3: Root Cause Analysis
Before writing code, state:
- **Root cause**: Why exactly is this happening?
- **Fix approach**: What specifically needs to change?
- **Files to modify**: List each file
- **Risk**: What could this break?

If the fix touches more than 3 files or involves architecture, confirm with the user first.

## Step 4: Write a Regression Test
Write a test that reproduces the bug — it should FAIL now and PASS after the fix.

## Step 5: Implement the Fix
- Minimal change that fixes the root cause
- Don't refactor surrounding code
- Don't add unrelated improvements
- Follow existing code patterns

## Step 6: Verify
Run the full test suite. The regression test passes, all existing tests still pass.

## Step 7: Report
```
Fixed: [one-line description]
Root cause: [what was wrong]
Files changed:
  - path/to/file.py (line X: what changed)
Tests: all passing
```
Ask: "Ready to commit? Run /commit to finalize."
