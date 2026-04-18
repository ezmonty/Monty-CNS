---
description: Research a topic using web search and vault knowledge, save findings.
---
# /research — Web + vault research

Research a topic by combining web search, vault knowledge, and memory.

Target: $ARGUMENTS (the research topic)

## Steps

### 1. Check vault for prior knowledge
If `search_content` MCP tool is available, search the vault for existing notes on the topic. If `query_notes` is available, also check for related decisions and evidence units.

### 2. Search the web
If `brave_web_search` MCP tool is available, search for current information on the topic. Summarize the top 3-5 results.

### 3. Synthesize
Combine vault knowledge (what you already know) with web results (what's current). Identify: what's confirmed, what's new, what contradicts prior knowledge.

### 4. Save findings
Use `create_inbox_note` MCP tool to save key findings to the vault:
- type: "research"
- tags: [research, <topic tags>]
Each finding becomes a separate inbox note if it's significant enough.

### 5. Report
Present the synthesized findings to the user with sources cited.
