Generate or update documentation — docstrings, JSDoc, API docs, module docs.

Target: $ARGUMENTS (file path, directory, module name, or "api" for full API docs)

## For Python Files
Module-level docstring at top:
```python
"""
ModuleName — What this module does in one line.

Key functions:
    function_name — What it does
    another_func  — What it does
"""
```

Function docstrings (only where not self-explanatory):
```python
def process_data(input: DataModel, config: Config) -> Result:
    """Process incoming data according to configuration rules.

    Args:
        input: The validated input data.
        config: Processing configuration.

    Returns:
        Result with processed data or error details.
    """
```

## For TypeScript/JavaScript
```tsx
/**
 * ComponentName displays/handles [what it does].
 *
 * @param propName — description
 * @param onAction — called when [trigger]
 */
```

## For API Documentation
1. Find all route definitions / endpoints
2. Generate a markdown table:
```markdown
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /health | Health check | No |
| POST | /api/data | Create record | Yes |
```

## Rules
- Match existing docstring style in the file
- Focus on WHY, not WHAT
- Don't over-document obvious code
- Include types, return values, side effects
- Keep docstrings concise
