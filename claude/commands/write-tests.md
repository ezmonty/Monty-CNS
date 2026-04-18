---
description: Write tests matching the project's existing patterns and frameworks.
---

Write tests for existing code — detect the framework and follow project patterns.

Target: $ARGUMENTS (file path, module name, or function name)

## Step 1: Detect Test Setup
Look for existing tests and framework:
- `pytest.ini`, `pyproject.toml` → pytest
- `jest.config.*`, `vitest.config.*` → Jest/Vitest
- `*_test.go` → Go testing
- `Cargo.toml` with `[dev-dependencies]` → Rust tests
- Check `package.json` for test scripts
- Follow existing test file naming conventions

## Step 2: Read the Target Code
- Read the full file
- Identify the public interface
- Find edge cases: what inputs could break this?
- Check if tests already exist — extend, don't duplicate

## Step 3: Write Tests

Structure:
```
TestClassName / describe block:
  test_happy_path              — normal usage works
  test_edge_case_empty_input   — handles empty/null
  test_edge_case_large_input   — handles extremes
  test_error_invalid_input     — bad input → useful error
  test_error_missing_required  — missing fields handled
```

### Python (pytest)
```python
class TestFunctionName:
    def test_happy_path(self):
        result = function_name(valid_input)
        assert result == expected

    def test_empty_input(self):
        result = function_name("")
        assert result is not None

    def test_invalid_raises(self):
        with pytest.raises(ValueError):
            function_name(bad_input)
```

### TypeScript (Jest/Vitest)
```typescript
describe('functionName', () => {
  it('handles normal input', () => {
    expect(functionName(validInput)).toBe(expected);
  });

  it('throws on invalid input', () => {
    expect(() => functionName(badInput)).toThrow();
  });
});
```

## Step 4: Run and Verify
All tests should pass against the current code.

## Step 5: Report
```
Tests written: X in [file]
  - test names listed
All passing: yes
```

## Rules
- Test behavior, not implementation details
- Each test independent — no shared mutable state
- Descriptive names: `test_what_when_then`
- Use timeouts on network requests
- One test file per module/component
