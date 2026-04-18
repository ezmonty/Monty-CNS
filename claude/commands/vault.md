---
description: Ad-hoc vault query — search, filter, or fetch notes from the Monty-Ledger vault.
---

# /vault — Query the vault

Target: $ARGUMENTS (the query)

## Routing

Parse `$ARGUMENTS` and dispatch:

1. **Type filter** (e.g., "profiles", "decisions", "learnings"):
   Use `query_notes` MCP with `type` filter matching the argument. Limit 20.

2. **"inbox"**:
   Use `query_notes` MCP with `path_filter: '00_Inbox/%'`. Show count and titles.

3. **"pods"**:
   Use `query_notes` MCP with `path_filter: '13_Pods/%'`, or call `get_pod` for a specific pod name.

4. **Path** (contains `/` or ends in `.md`):
   Use `get_note` MCP with the given path.

5. **Free text** (anything else):
   Use `search_content` MCP with the query string. Summarize top 5 results.

## Access Control

- Default: `access_max: "private"` on all queries.
- Only set `access_max: "secret"` if the user explicitly says "include secret" or "show secret".
- Never request `access_max: "hidden"` — hidden notes are not surfaced by AI.

## Output

- Show results as a concise list: title, type, path, and a one-line summary if available.
- If no results, say so and suggest alternative queries.
