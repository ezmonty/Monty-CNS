Test-driven development — write failing tests first, then implement until they pass.

Feature: $ARGUMENTS

## Phase 1: RED — Write Failing Tests

### 1.1 Clarify Requirements
State clearly:
- **What** this feature does (one sentence)
- **Inputs**: What data goes in?
- **Outputs**: What should come back?
- **Edge cases**: Empty input, missing fields, invalid data

### 1.2 Detect Test Framework
Look at the project for:
- Python: `pytest`, `unittest` — check `pyproject.toml`, `setup.cfg`, existing tests
- Node: `jest`, `vitest`, `mocha` — check `package.json`
- Go: built-in `testing` package
- Follow existing test file naming and structure

### 1.3 Write Tests FIRST
Cover:
1. **Happy path** — normal usage works
2. **Edge cases** — boundaries behave correctly
3. **Error handling** — bad input produces useful error, not crash

### 1.4 Run Tests — They MUST Fail
```bash
<test command> <test file>
```
If tests pass → they aren't testing new behavior. Rewrite.

## Phase 2: GREEN — Make Tests Pass

### 2.1 Implement Minimum Code
- Pick ONE failing test
- Write the simplest code that makes it pass
- Run tests again
- Move to next failing test
- Repeat until all pass

**Rules:**
- Don't optimize yet
- Don't add features the tests don't require
- Write obvious code, not clever code

### 2.2 All Tests Green
Every test must pass before moving on.

## Phase 3: REFACTOR — Clean Up

### 3.1 Improve the Implementation
- Remove duplication
- Improve naming
- Simplify logic
- **Run tests after EVERY change** — if something breaks, undo it

### 3.2 Full Suite Check
Run the complete test suite to confirm nothing else broke.

## Summary
Report: tests written, files created, all passing yes/no.
