# Plans — index

This directory holds **implementation plans**: detailed, phased,
actionable blueprints for work that spans multiple milestones and
workstreams. Each plan is the canonical reference for "how are we
actually going to build this thing" and tracks its own progress via
a dedicated `WORKLOG.md`.

## Philosophy

- **Plans are living documents.** Check them in, amend them as you
  learn, commit the amendments. A plan that's out of date is a worse
  liability than no plan.
- **Plans are phase-based.** Each phase has explicit workstreams
  (parallelizable), milestones (checkpointable), TODOs (actionable),
  tests (verifiable), and exit criteria (unambiguous).
- **Plans are agent-friendly.** The coordination conventions make it
  safe for multiple humans and AI subagents to work on different
  workstreams in parallel without stepping on each other.
- **Plans cite dogfood lessons.** When we learn something painful in
  one project, the lesson goes into the next plan so we don't repeat
  the mistake.

## Active plans

| Plan | Status | Summary |
|---|---|---|
| [valor-github-integration.md](valor-github-integration.md) | 📋 Not started | Valor's GitHub App build — PAT → App migration, webhook handler, CI/CD integration, full QA suite, phased rollout for Remedy Reconstruction as the first customer |

## Conventions all plans follow

### Structure

Every plan in this directory has the following sections:

1. **Overview** — what we're building and for whom
2. **Success criteria** — how we know we're done
3. **Non-goals** — what's explicitly out of scope
4. **Architecture** — the shape of the thing being built
5. **Dogfood lessons** — what we learned from previous projects that this plan should avoid repeating
6. **Coordination rules** — how multiple workers coordinate without conflict
7. **Phases** — the sequence of work, with parallelizable streams per phase
8. **Full QA suite** — unit / integration / E2E / security / load testing
9. **Deployment plan** — how it ships to staging and then production
10. **Operations runbook** — how to run it once it's shipped
11. **Risks and unknowns** — what could go wrong and what we don't yet know

### Phase anatomy

Each phase has:

- **Goal:** one sentence summary of what this phase accomplishes
- **Dependencies:** which other phases must be complete first
- **Workstreams:** parallelizable tracks within the phase (usually A/B/C/…)
- **Milestones:** concrete deliverables that mark phase progress
- **TODOs:** granular tasks an agent or human can claim and work on
- **Tests:** what must pass before the phase is considered done
- **Exit criteria:** unambiguous statement of "phase is complete"

### Workstream parallelism

Workstreams within a single phase are designed to run **in parallel**
when dependencies allow. Each workstream:

- Is owned by exactly one worker at a time (human or agent)
- Has its own named branch off the main feature branch
- Commits frequently with conventional-commit-style messages
- Logs its progress to `WORKLOG.md` on claim, progress, blocker, and completion
- Merges back to the feature branch via PR once milestones are hit

### Task claim protocol

To prevent duplicate work and merge conflicts:

1. **Before starting a task**, append a `claimed` entry to `WORKLOG.md`:
   ```markdown
   ## 2026-04-13T17:30:00Z — agent-foo — phase-2.A — JWT signer
   Status: claimed
   Branch: phase-2/jwt-signer
   ETA: 2 hours
   Files planned: valor/github/auth/jwt.py, tests/github/auth/test_jwt.py
   Notes: Starting RS256 signer, target 100% branch coverage
   ```
2. **While working**, append progress entries at logical checkpoints
   (test pass, blocker encountered, etc.)
3. **On completion**, append a `done` entry:
   ```markdown
   ## 2026-04-13T19:15:00Z — agent-foo — phase-2.A — JWT signer
   Status: done
   Branch: phase-2/jwt-signer
   Commits: [abc123, def456]
   Notes: 100% coverage, edge cases tested, ready for PR review
   ```
4. **If blocked**, update the status and add a `Blocker:` line so other
   workers know not to pick up the same task.

### Commit conventions

Commits on workstream branches use the conventional commit format:

```
<type>(<scope>): <subject>

<body explaining why>

Phase: <phase-number>.<workstream-letter>
Task: <short-task-id>

https://claude.ai/code/session_<session-id>  (if authored by an AI agent)
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`, `ci`

### Handoff protocol

When a worker needs to hand off a partially-completed task:

1. Push whatever is committed so far to the workstream branch
2. Update `WORKLOG.md` with status `handing-off`, a summary of what's
   done and what's left, and any tricky decisions made so far
3. Open an issue or ping in the team channel so another worker knows
   to pick it up

### Conflict resolution

If two workers both try to claim the same task:

- **The later claimant backs off.** Check `WORKLOG.md` before claiming.
- If the first claimant is an AI subagent and has been idle for >30
  minutes, assume it's abandoned and reclaim.
- When in doubt, ask a human.

## Ownership

Plans are **owned by the person responsible for the outcome**. That
person doesn't have to do all the work, but they're accountable for
the plan being accurate and up to date. The owner's name goes at the
top of each plan.

## When to create a new plan

Create a new plan when:

1. The work spans **multiple milestones** and multiple people / agents
2. The work has **dependencies** that need explicit sequencing
3. The work benefits from **parallelism** — multiple workstreams can
   run simultaneously if coordinated
4. The work is **risky enough** that you want a written rollback path
5. The work crosses **system boundaries** (e.g. Valor + external APIs,
   Valor + customer deployment)

Don't create a plan for:

- Single commits or PRs — a commit message is enough
- Work one person can finish in an afternoon
- Exploratory spikes — use a scratch branch and a `NOTES.md` instead

## Archiving

When a plan is fully complete and the system it describes is running
in production, **don't delete the plan**. Move it to `docs/plans/archive/`
and link it from the runbook for that system. The plan becomes the
historical record of how the system was built.
