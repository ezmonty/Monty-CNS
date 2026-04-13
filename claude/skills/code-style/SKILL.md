---
name: code-style
description: General code style and conventions. Use when writing new code or reviewing existing code. For per-project overrides, consult the project's own style docs first.
---

# Code Style — General

This is a generic baseline. Whenever a project has its own style guide (`CONTRIBUTING.md`, `.editorconfig`, linter config, project `CLAUDE.md`), that wins. This skill is the fallback.

## Universal Rules

- **Match the existing codebase.** Consistency beats personal preference. If the repo uses `snake_case`, don't introduce `camelCase`.
- **No debug leftovers** — no `console.log`, `print()` debugging, `debugger`, `breakpoint()` in committed code.
- **No commented-out code.** Delete it — git has history.
- **No magic numbers.** Use named constants.
- **No TODOs without context.** Every TODO should link an issue or say exactly what's needed.
- **No bare `except:` / `catch(e)` swallowing errors.** Catch specific types, or re-raise with context.
- **Keep files under ~500 lines.** Split by responsibility, not by line count.
- **Keep functions under ~50 lines.** Extract helpers when they grow.

## Python

### Naming

- **Files:** `snake_case.py`
- **Functions, variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private/internal:** leading `_underscore`

### Structure

- Imports at top, grouped: stdlib → third-party → local, one blank line between groups
- Type hints on every function signature you write
- Prefer `pathlib.Path` over `os.path` for paths
- Prefer `dataclasses` / `pydantic.BaseModel` over dict-of-anything
- f-strings for formatting, not `%` or `.format`

### Example

```python
import json
from pathlib import Path

from pydantic import BaseModel

from myproject.constants import DEFAULT_TIMEOUT


class Request(BaseModel):
    command: str
    timeout: int = DEFAULT_TIMEOUT


def load_config(path: Path) -> dict:
    """Load a JSON config file."""
    return json.loads(path.read_text())
```

## TypeScript / JavaScript

### Naming

- **Files:** `PascalCase.tsx` for React components, `camelCase.ts` for everything else
- **Components:** `PascalCase` (prefer function declarations over arrow-assigned consts for top-level components)
- **Hooks:** `useCamelCase`
- **Interfaces/types:** `PascalCase` with descriptive suffix (`Props`, `State`, `Config`)
- **Constants:** `UPPER_SNAKE_CASE` for module-level immutables, `camelCase` for everything else

### Structure

- One main export per file
- Props interface defined immediately above the component
- Named exports for libraries, default export fine for pages/routes
- **No `any`** — use `unknown` and narrow, or fix the type

### Example

```tsx
import { Card, Text } from 'some-ui-lib';

interface StatusBadgeProps {
  label: string;
  active: boolean;
}

export function StatusBadge({ label, active }: StatusBadgeProps) {
  return <Card>{label}: {active ? 'on' : 'off'}</Card>;
}
```

## Go

- `gofmt` is law — never argue with it.
- Exported names start with uppercase, unexported with lowercase.
- Errors are values — return `(result, error)`, check with `if err != nil`, wrap with `fmt.Errorf("context: %w", err)`.
- Small interfaces, defined near the consumer, not the producer.

## Rust

- `cargo fmt` is law.
- Prefer `Result<T, E>` over panics in library code.
- Use `?` operator for propagation, not manual matches.
- `clippy` catches most style issues — listen to it.

## Comments

Only comment the **why**, not the **what**. The code already says what it does. Comments explain intent, constraints, surprising context, or link to external decisions.

```python
# Bad:  increment i
i += 1

# Good: offset by 1 because the upstream API uses 1-indexed pages
i += 1
```
