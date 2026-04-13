Build a feature end-to-end — plan, implement, test, and prepare for review.

Feature: $ARGUMENTS

## Phase 1: Plan

### 1.1 Understand the Requirement
- **What**: One-sentence description
- **Why**: What problem does this solve?
- **Where**: Which part of the system?
- **Scope**: What's in and what's explicitly out?

### 1.2 Architecture Decision
- Does this need new files or can we extend existing ones?
- Database changes needed?
- New API endpoints?
- New UI components?
- Find a similar existing feature to model after

### 1.3 Implementation Plan
Ordered list of steps. Present to the user and wait for approval.

## Phase 2: Build (TDD Style)

### 2.1 Write Tests First
Define expected behavior in tests. They should fail initially.

### 2.2 Implement Layer by Layer
Work bottom-up: data → logic → API → UI.
Run tests after each layer.

### 2.3 Wire the Full Round-Trip
Every UI control should complete the full cycle:
```
User action → API call → Backend processes → DB write → Response → UI update
```

## Phase 3: Verify

### 3.1 Tests Pass
Run the full test suite.

### 3.2 Lint and Build
Run whatever linters and build tools the project uses.

## Phase 4: Wrap Up
```
Feature: [name]
Files created: [list]
Files modified: [list]
Tests: X new, Y total passing
```
Ask: "Ready to commit? Run /commit, then /pr to create a pull request."
