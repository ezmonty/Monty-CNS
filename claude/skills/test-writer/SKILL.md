---
name: test-writer
description: Write tests following the project's existing patterns — smoke, unit, integration, E2E. Detect the framework, mirror the style, cover happy path and edge cases. Use when creating tests for new code.
---

# Test Writer

Target: $ARGUMENTS (file, function, feature, or "coverage gap")

## Step 1: Detect the Framework and Style

Before writing anything, figure out what the project already uses:

```bash
# Python
ls tests/ conftest.py pytest.ini pyproject.toml 2>/dev/null
grep -r "^def test_\|^class Test" tests/ | head

# JavaScript / TypeScript
cat package.json | grep -E '"test|jest|vitest|mocha|playwright'
find . -name '*.test.*' -o -name '*.spec.*' | head

# Go
find . -name '*_test.go' | head
```

Match the existing pattern. A codebase with 500 pytest tests does **not** want a unittest class sneaking in.

## Step 2: Decide the Test Layer

| Layer | Purpose | When to use |
|---|---|---|
| Unit | One function, no I/O | Pure logic, branches, edge cases |
| Integration | Real dependencies (DB, HTTP) | Contracts between modules |
| Smoke | "Does it boot and respond" | Service-level sanity |
| E2E | Full user journey | Critical flows only (slow, flaky) |

Prefer the lowest layer that catches the bug you care about. Unit tests are cheap and fast — write lots. E2E tests are expensive — write few.

## Step 3: Cover the Right Cases

For any function, aim for:

1. **Happy path** — typical valid input
2. **Boundary** — empty, one, max
3. **Invalid** — bad types, None/null, out-of-range
4. **Error** — what happens when a dependency fails
5. **Side effects** — if it writes to disk/DB, verify that too

## Generic Templates

### Python + pytest

```python
"""Tests for <module>."""
import pytest
from mymodule import the_function

class TestTheFunction:
    def test_happy_path(self):
        assert the_function(valid_input) == expected

    def test_empty_input(self):
        assert the_function([]) == []

    def test_invalid_type(self):
        with pytest.raises(TypeError):
            the_function(object())

    @pytest.mark.parametrize("inp,expected", [
        (1, "one"),
        (2, "two"),
    ])
    def test_cases(self, inp, expected):
        assert the_function(inp) == expected
```

### TypeScript + Vitest / Jest

```ts
import { describe, it, expect } from 'vitest';
import { theFunction } from './myModule';

describe('theFunction', () => {
  it('handles happy path', () => {
    expect(theFunction(validInput)).toBe(expected);
  });

  it('returns empty for empty input', () => {
    expect(theFunction([])).toEqual([]);
  });

  it('throws on invalid type', () => {
    expect(() => theFunction(null as any)).toThrow();
  });
});
```

### HTTP service smoke test (language-agnostic shape)

```python
import requests

BASE = "http://localhost:8000"

def test_health():
    r = requests.get(f"{BASE}/health", timeout=5)
    assert r.status_code == 200
    assert r.json().get("status") == "ok"

def test_main_endpoint_shape():
    r = requests.post(f"{BASE}/api/thing", json={"command": "ping"}, timeout=10)
    assert r.status_code == 200
    body = r.json()
    # Verify the response envelope the service promises
    assert "status" in body and "data" in body
```

## Rules

- **Behavior, not implementation.** Test what the function returns/does, not how it does it. Makes refactoring safe.
- **One assertion concept per test.** Don't cram 10 unrelated checks into one `test_everything`.
- **Deterministic.** No `datetime.now()`, random, network, or filesystem unless explicitly mocked.
- **Fast.** Unit tests should run in milliseconds. If it needs real I/O, it's an integration test.
- **Independent.** No shared state — each test sets up and tears down its own world.
- **Descriptive names.** `test_user_login_rejects_empty_password` beats `test_login_2`.
- **Test the failure mode.** If a function is supposed to raise, test that it raises.
