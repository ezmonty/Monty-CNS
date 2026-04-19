---
type: decision
status: active
created: 2026-04-18
tags: [decision, architecture, access-control, postgres]
confidence: 4
access: private
truth_layer: working
role_mode: strategist
persona_mix: [strategist, owner]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — Access Enforcement in Postgres, Not Application Layer

## Context

The Ledger MCP server enforces access classes (public/private/
secret/hidden) via CASE expressions in every SQL query. But Valor's
VaultContextAgent (Phase 4) will also need the same enforcement.
Duplicating access logic in two application layers is a maintenance
and security liability.

## The Problem

```
NOW: access logic duplicated
  MCP server (TypeScript)  → CASE LOWER(access) ... <= $N
  VaultContextAgent (Python) → would need same logic, different language
  Any future client         → must reimplement again
```

If one implementation drifts or has a bug, access enforcement is
inconsistent. The get_note bypass we found (and fixed) in this
session proves how easy it is to miss one handler.

## Chosen Path

Move access enforcement into Postgres using Row-Level Security
(RLS) policies. The database itself refuses to return rows the
caller's role isn't authorized to see.

```
FUTURE: access logic in Postgres
  Postgres RLS policy      → rows filtered at the DB layer
  MCP server (TypeScript)  → just queries, no access CASE
  VaultContextAgent (Python) → just queries, no access CASE
  Any future client         → automatically protected
```

Implementation:
1. Create Postgres roles: `ledger_public`, `ledger_private`,
   `ledger_secret`, `ledger_admin`
2. Each role maps to an access ceiling
3. RLS policy on `notes` table: `access_level(access) <= current_role_level()`
4. MCP server connects with the role matching LEDGER_ACCESS_CEILING
5. Valor agents connect with roles matching their token's access grant
6. Views (v_profiles, v_decisions, etc.) inherit RLS automatically

## When to Build

Phase 4 of the Ledger plan (Valor integration). The current
application-layer enforcement works for single-user MCP. Migrate
to RLS when the second client (VaultContextAgent) is built — that's
when duplication would start.

## Why Not Now

RLS requires Postgres role management, connection pooling per role,
and testing with multiple roles. Premature for a single client.
The application-layer enforcement is correct and tested (17/17
integration tests pass). Migrate when there's a real second client.

## Risks

- RLS adds complexity to Postgres administration
- Connection pooling per role requires pool-per-role or SET ROLE
- Testing RLS requires multiple database roles in the test suite
- Mitigated: the application-layer code stays as a defense-in-depth
  layer even after RLS is added (belt and suspenders)
