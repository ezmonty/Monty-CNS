---
id:
type: decision
status: active
created: 2026-04-15
updated: 2026-04-15
tags: [decision, active]
confidence: 4
source:
summary: Chose Obsidian as the main durable system and NotebookLM as optional packet analyzer.
related_projects: [[Project - Vault Implementation]]
related_profiles: [[Profile - Work and Execution]], [[Profile - Voice and Writing]]
review_due: 2026-05-15
access: private
mask_level: low
truth_layer: working
role_mode: strategist
persona_mix: [strategist, owner]
origin_type: revised-entry
quote_status: exact
---
# Decision - Obsidian as System of Record

## Context

Need one primary system that:
- supports markdown
- supports linking
- can be operated on by AI agents
- does not trap the knowledge in a rigid SaaS structure
- can still be used by a human without endless system-building

## Options

- Obsidian as primary
- OneNote as primary
- Notion as primary
- Capacities as primary
- NotebookLM as primary

## Reasoning

Obsidian won because it is file-based, markdown-native, link-friendly, agent-friendly, and mature enough to support growth.
NotebookLM stays secondary because it is stronger as a packet analyzer than as a lifelong home base.

## Risks

- plugin temptation
- system-building drift
- overcomplexity too early

## Chosen path

Use Obsidian as the durable second-brain layer.
Use packet exports for outside AI analysis when needed.
