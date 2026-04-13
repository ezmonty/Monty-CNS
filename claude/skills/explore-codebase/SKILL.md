---
name: explore-codebase
description: Deep codebase exploration using a subagent — find how a feature works, trace data flows, map dependencies across many files. Use when the user wants to understand how something works or needs a thorough investigation.
context: fork
agent: Explore
---

# Deep Codebase Exploration

Topic: $ARGUMENTS

## Mission

Thoroughly investigate the topic across the entire codebase. This runs in an isolated (forked) context so you can read many files without polluting the main conversation.

## Investigation Steps

1. **Find all relevant files.**
   - Search by the topic name, related keywords, and likely synonyms.
   - Walk the obvious entry points: routing tables, config files, module indices, schema definitions.
   - Don't stop at the first match — find everything that touches the topic.

2. **Trace the data flow end-to-end.**
   - Where does input originate? (user action / external API / scheduled job)
   - How does it transform at each layer? (validation → business logic → storage → response)
   - What's the read path? Is it the same as the write path or different?

3. **Map dependencies.**
   - What does this feature call into?
   - What calls into this feature?
   - Which configs, environment variables, or feature flags control its behavior?

4. **Identify patterns and inconsistencies.**
   - Is this implemented the same way as similar features?
   - Are there places doing the same thing differently?
   - Is the code path tested? Where?

## Report Format

Return a structured summary the caller can act on:

```
## Overview
<2-3 sentences: what this is, what it does, where it lives>

## Key files
- path/to/file.ext:line  — brief role
- path/to/other.ext      — brief role
...

## Data flow
1. Input: <origin>
2. <step>: <what happens, file:line>
3. <step>: <what happens, file:line>
4. Output: <destination>

## Dependencies
- Depends on: <modules, services, libs>
- Depended on by: <callers>
- Config / env: <flags, settings, vars>

## Tests
- <test file and what it covers, or "none found">

## Observations
- <anything that looks wrong, inconsistent, or worth flagging>
```

## Rules

- **Never guess.** If the file doesn't say it, say "not found" — don't invent.
- **Cite file:line** for every concrete claim so the caller can jump straight to the code.
- **Bound the search.** If the topic spans hundreds of files, summarize categories instead of enumerating.
- **Flag ambiguity.** If a name is overloaded (e.g. two classes called `Manager`), list all matches and disambiguate.
