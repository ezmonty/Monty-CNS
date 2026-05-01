---
id:
type: note
status: active
created: 2026-05-01
updated: 2026-05-01
tags: [knowledge, builder, architecture]
confidence: 4
source: docs/monty_core_docs_savepack/max_monty_invariants.md
summary: Load this instead of the full invariants doc — 10 category summaries with link to source.
access: private
truth_layer: working
role_mode: strategist
origin_type: ai-proposed
review_due: 2026-08-01
---

# Knowledge - System Invariants

**Source:** `docs/monty_core_docs_savepack/max_monty_invariants.md` (v1, ~420 lines)
**Rule:** If code conflicts with the invariants doc, code is wrong (or the doc must be explicitly updated).

---

## The 10 invariant categories

**1. Global architecture**
- MontyCore is the only user-facing `/ask` router. All requests go through it. No agent exposes its own public ask endpoint.
- All agents: `GET /health` + `POST /run` with standard AgentInput/AgentOutput shape.
- Only LLMToolAgent calls LLMs directly. All other agents route through it or use deterministic logic.
- Core behavior must work without cloud (local LLMs via Ollama, local SQLite data).

**2. Builder / meta-OS**
- AgentLauncher manages processes using `configs/agent_processes.json`. MontyCore routes using `configs/agents.json`.
- Only SysArchAgent + builder stack can write to either registry file.
- Pods are the main bundling mechanism. Pod definitions must map to docs in `configs/pod_blueprints.json`.

**3. ConstructionOS domain**
- Covers: CYA/comms (RFIs, email), docs/plans (specs, drawings), safety (incidents, OSHA), ops/tasks (daily logs, autopilot).
- Data lives in `data/construction_*` JSON or `data/monty.db` tables.
- No new JSON files or DB tables without updating `docs/data_schemas_v1.md` and `core/schemas.py`.
- CYA bundles must preserve dates, responsible parties, decisions, and maintain pointers to raw records.

**4. FinanceOS domain**
- Multi-client by design: every entity is keyed by `user_id`.
- Agents must refuse client-specific operations without `user_id` in context.
- Covers: portfolio analytics, study/CFA, future trading.

**5. Data and schema**
- Canonical schemas: `docs/data_schemas_v1.md` (human) + `core/schemas.py` (code).
- Agents operate on DTO-like structures (Pydantic models), not ad-hoc dicts.
- Adding fields: allowed with docs update. Removing/renaming: requires addendum doc + migration note.

**6. Shell and safety**
- ShellAgent is a developer tool, not a production autopilot.
- Default: read/inspect only. Write/admin actions require explicit whitelist + `unsafe_ok` flag + logging.
- Every agent logs under `logs/<AgentName>/server.log`.

**7. Drift and documentation**
- Every agent file needs: Python module + `agent_processes.json` entry + blueprint doc mention.
- Every pod needs: `pod_blueprints.json` entry + `pods.json` entry (if active) + blueprint doc.
- Tests are a contract: every non-trivial agent needs at least one test via MontyCore or direct.

**8. Smoke tests**
- `tests/smoke_monty_simple.py` must stay green. Fix it before adding features.
- Builder stack, SystemCheck, domain RAG each need their own lightweight smokes.
- Any new pod or major agent needs at least one smoke test.

**9. DriftGuard and SystemCheck (planned)**
- DriftGuardAgent will read all configs + docs + invariants and flag misalignments.
- SystemCheckAgent aggregates health + drift findings into human-readable reports + action suggestions.
- Both are read-only; no automatic fixes.

**10. Versioning this doc**
- This is Invariants v1. Breaking changes require an addendum doc.
- DriftGuardAgent should eventually parse the version and flag code/config/docs drift.

---

## When to load this note

Load this in any builder session that involves:
- Adding or modifying an agent
- Changing a pod configuration
- Making a data schema change
- Reviewing whether a proposed feature violates any constraint
- Running /pulse on the builder stack

Do NOT use this as a substitute for the full source doc when making a consequential change — read the source.
