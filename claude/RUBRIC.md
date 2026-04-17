# CNS Default Quality Rubric

Used by `/review` and `/adversarial-review`. Score each dimension 1–5.

## 1. Correctness
1=broken, 2=works on happy path, 3=handles common edge cases, 4=handles rare edge cases, 5=provably correct
- Does it do what it claims?
- Are error paths handled?
- Are edge cases considered?

## 2. Safety
1=has known vulnerabilities, 2=no obvious holes, 3=validates inputs, 4=defense in depth, 5=security-reviewed
- Input validation at trust boundaries
- No hardcoded secrets
- Error messages don't leak internals

## 3. Clarity
1=unreadable, 2=readable with effort, 3=clear to the team, 4=clear to a newcomer, 5=self-documenting
- Names communicate intent
- Functions do one thing
- No magic numbers/strings

## 4. Test Coverage
1=untested, 2=happy path only, 3=edge cases covered, 4=failure injection, 5=mutation-tested
- Are changes tested?
- Are tests meaningful (not just assertions that pass)?
- Could a regression slip through?

## 5. Consistency
1=contradicts codebase, 2=different style, 3=follows patterns, 4=improves patterns, 5=exemplary
- Matches project conventions
- Uses existing utilities instead of reinventing
- Error handling follows project patterns

---

This is the CNS default rubric. Projects override by placing RUBRIC.md at repo root or .claude/. Scores are advisory, not gating — use judgment.
