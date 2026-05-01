---
type: pattern
status: review
origin_type: ai-proposed
confidence: 4
access: private
truth_layer: working
tags: [valor, e2e, playwright, test-design, frontend, react]
date: 2026-05-01
---

# Click-through E2E tests must target by data-testid, never by ordinal

`InboxList` rendered Preview (button #1), Acknowledge for alerts (#2), Primary Action (#3). E2E tests doing `.getByRole('button').first()` got Preview every time — only the primary action opens the DecisionWorkspace. The bug had been silently in the codebase across multiple sessions because unit tests never exercised the click path. The fix was a `data-testid="primary-action-{id}"` on the meaningful button plus updated selectors in 4 spec files.

**Why ordinal selection is fragile in React:**
- Conditional rendering (`{isAlert && <AckButton/>}`) reorders sibling buttons per-row
- Mantine wrappers, focus-traps, and tooltips inject hidden buttons
- Adding a new icon next to an existing one silently shifts every "first()" assertion in the suite
- Unit tests rendering a single component pass; integration tests against the real list explode

**Rule:** every interactive element that participates in a user flow gets a `data-testid`. Don't rely on role+text either — i18n, tooltips, and decorative siblings all break that. The testid is documentation that says "this button is part of a contract with a test."

**Naming convention that survived the rewrite here:** `{action}-{entity}-{id}` (e.g. `primary-action-co-018`, `defer-menu-rfi-77`). Stable, greppable, doesn't collide with CSS classes.

If a click test is brittle, the bug is in the selector, not the test runner.
