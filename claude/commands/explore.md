Deep codebase exploration — trace how a feature works, map data flows and dependencies.

Topic: $ARGUMENTS

## Investigation Steps

### 0. Query vault for related knowledge
If the `search_content` MCP tool is available, search for notes related to the exploration topic. If `build_packet` is available and a relevant pod exists, build a context packet. Include any vault findings as background context for the exploration.

### 1. Find ALL Relevant Files
Search broadly — don't stop at first match:
- Search by name, keywords, related terms, abbreviations
- Check all directories: source, config, tests, docs
- Follow imports to find connected files

### 2. Trace the Data Flow
Map the complete path from input to output:
```
Input source → Processing → Storage → Response → Output
```

### 3. Map Dependencies
- What does this depend ON?
- What depends on THIS?
- What configs control it?

### 4. Find Tests and Gaps
- Existing test coverage
- What's NOT tested?

### 5. Spot Issues
- Inconsistencies with project conventions
- Missing error handling
- Dead code
- Performance concerns

## Report
```
Exploration: [topic]
═══════════════════
Overview:   [2-3 sentences]
Key Files:  [paths with descriptions]
Data Flow:  [step by step]
Dependencies: [upstream and downstream]
Tests:      [coverage and gaps]
Issues:     [anything wrong]
```
