---
description: Deep-dive explanation of specified code.
---

Provide a deep-dive explanation of the specified code.

Target: $ARGUMENTS (file path, function name, module, or concept)

## How to Investigate

### If target is a file:
1. Read the entire file
2. Read files it imports
3. Find who calls/imports this file

### If target is a function/class:
1. Find the definition
2. Read the full function + context
3. Find all callers

### If target is a concept (e.g., "auth", "routing"):
1. Search broadly for related files
2. Trace the flow from entry to conclusion

## What to Explain

1. **Purpose**: What and why (2-3 sentences)

2. **How it works**: Step by step with line references
   ```
   Request → validates → processes → responds
   ```

3. **Inputs/Outputs**: Types, example values

4. **Where it fits**: Architecture context, what depends on it and what it depends on

5. **Non-obvious things**: Gotchas, historical decisions, known limitations

## Style
- Use headers to organize
- Include file:line references
- Show code snippets for key logic
- Offer: "Want me to go deeper on any part?"
