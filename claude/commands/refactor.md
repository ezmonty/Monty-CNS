Safely refactor code with test verification at every step.

Target: $ARGUMENTS (file path, description, or "suggest" for recommendations)

**Golden rule: Refactoring = changing structure without changing behavior.**

## Step 1: Establish Baseline
```bash
<test command>
```
Record: X tests passing out of Y total.

If the target code has NO tests → **write them first**, get them passing, THEN refactor.

## Step 2: Understand What You're Refactoring
- Read the target code completely
- Find all callers (who imports/uses this?)
- Map the public interface (what MUST stay the same)
- Identify what makes this code painful

## Step 3: Plan
```
Refactoring plan:
  Changing:      [structure, organization, naming]
  NOT changing:  [behavior, public API, contracts]
  Strategy:      [extract | split | rename | simplify | consolidate]
  Steps:         [ordered list of small changes]
```

## Step 4: Execute Incrementally
For EACH small change:
1. Make ONE change
2. Run tests IMMEDIATELY
3. Tests pass → continue
4. Tests FAIL → revert, try smaller step

**Never make multiple changes between test runs.**

## Step 5: Final Verification
- Test count must match or exceed baseline
- No public interfaces changed (unless that was the goal)
- Run lint

## Step 6: Report
```
Refactoring complete:
  Target:   [what]
  Strategy: [how]
  Tests:    X/Y passing (same as baseline)
  Files:    [modified files]
```
