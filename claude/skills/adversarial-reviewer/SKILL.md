---
name: adversarial-reviewer
description: Adversarial code review that breaks the self-review monoculture. Use when you want a genuinely critical review of recent changes, before merging a PR, or when you suspect the model is being too agreeable about code quality. Forces perspective shifts through hostile reviewer personas that catch blind spots the author's mental model shares with the reviewer.
license: MIT
---

<!--
Upstream: alirezarezvani/claude-skills — engineering-team/adversarial-reviewer/SKILL.md
Original author: ekreloff
Upstream license: MIT
Adapted for Monty-CNS: removed library-internal cross-references, otherwise
verbatim. See docs/migration-valor2.md and claude/skills/README.md for the
library's mining workflow.
-->

# Adversarial Code Reviewer

## Description

Adversarial code review skill that forces genuine perspective shifts through three hostile reviewer personas (Saboteur, New Hire, Security Auditor). Each persona MUST find at least one issue — no "LGTM" escapes. Findings are severity-classified and cross-promoted when caught by multiple personas.

## Features

- **Three adversarial personas** — Saboteur (production breaks), New Hire (maintainability), Security Auditor (OWASP-informed)
- **Mandatory findings** — Each persona must surface at least one issue, eliminating rubber-stamp reviews
- **Severity promotion** — Issues caught by 2+ personas are promoted one severity level
- **Self-review trap breaker** — Concrete techniques to overcome shared mental model blind spots
- **Structured verdicts** — BLOCK / CONCERNS / CLEAN with clear merge guidance

## Usage

```
/adversarial-review              # Review staged/unstaged changes
/adversarial-review --diff HEAD~3  # Review last 3 commits
/adversarial-review --file src/auth.ts  # Review a specific file
```

## Problem This Solves

When a model reviews code it wrote (or code it just read), it shares the same mental model, assumptions, and blind spots as the author. This produces "Looks good to me" reviews on code that a fresh human reviewer would flag immediately.

This skill forces a genuine perspective shift by requiring you to adopt adversarial personas — each with different priorities, different fears, and different definitions of "bad code."

## Review Workflow

### Step 1: Gather the Changes

Determine what to review based on invocation:

- **No arguments:** `git diff` (unstaged) + `git diff --cached` (staged). If both empty, `git diff HEAD~1`.
- **`--diff <ref>`:** `git diff <ref>`.
- **`--file <path>`:** Read the entire file. Review the full file, not just changes.

If no changes are found, stop and report: "Nothing to review."

### Step 2: Read the Full Context

For every file in the diff:

1. Read the **full file** (not just the changed lines) — bugs hide in how new code interacts with existing code.
2. Identify the **purpose** of the change: bug fix, new feature, refactor, config change, test.
3. Note any **project conventions** from `CLAUDE.md`, `.editorconfig`, linter configs, or existing patterns.

### Step 3: Run All Three Personas

Execute each persona sequentially. Each persona MUST produce at least one finding. If a persona finds nothing wrong, it has not looked hard enough — go back and look again.

**IMPORTANT:** Do not soften findings. Do not hedge. Do not say "this might be fine but..." — either it's a problem or it isn't. Be direct.

### Step 4: Deduplicate and Synthesize

After all three personas have reported:

1. Merge duplicate findings (same issue caught by multiple personas).
2. Promote findings caught by 2+ personas to the next severity level.
3. Produce the final structured output.

## The Three Personas

### Persona 1: The Saboteur

**Mindset:** "I am trying to break this code in production."

**Priorities:**

- Input that was never validated
- State that can become inconsistent
- Concurrent access without synchronization
- Error paths that swallow exceptions or return misleading results
- Assumptions about data format, size, or availability that could be violated
- Off-by-one errors, integer overflow, null/undefined dereferences
- Resource leaks (file handles, connections, subscriptions, listeners)

**Review Process:**

1. For each function/method changed, ask: "What is the worst input I could send this?"
2. For each external call, ask: "What if this fails, times out, or returns garbage?"
3. For each state mutation, ask: "What if this runs twice? Concurrently? Never?"
4. For each conditional, ask: "What if neither branch is correct?"

**You MUST find at least one issue.** If the code is genuinely bulletproof, note the most fragile assumption it relies on.

---

### Persona 2: The New Hire

**Mindset:** "I just joined this team. I need to understand and modify this code in 6 months with zero context from the original author."

**Priorities:**

- Names that don't communicate intent (what does `data` mean? what does `process()` do?)
- Logic that requires reading 3+ other files to understand
- Magic numbers, magic strings, unexplained constants
- Functions doing more than one thing (the name says X but it also does Y and Z)
- Missing type information that forces the reader to trace through call chains
- Inconsistency with surrounding code style or project conventions
- Tests that test implementation details instead of behavior
- Comments that describe *what* (redundant) instead of *why* (useful)

**Review Process:**

1. Read each changed function as if you've never seen the codebase. Can you understand it from name, parameters, and body alone?
2. Trace one code path end-to-end. How many files do you need to open?
3. Check: would a new contributor know where to add a similar feature?
4. Look for "the author knew something the reader won't" — implicit knowledge baked into the code.

**You MUST find at least one issue.** If the code is crystal clear, note the most likely point of confusion for a newcomer.

---

### Persona 3: The Security Auditor

**Mindset:** "This code will be attacked. My job is to find the vulnerability before an attacker does."

**OWASP-Informed Checklist:**

| Category | What to Look For |
|---|---|
| **Injection** | SQL, NoSQL, OS command, LDAP — any place user input reaches a query/command without parameterization |
| **Broken Auth** | Hardcoded credentials, missing auth checks on new endpoints, session tokens in URLs or logs |
| **Data Exposure** | Sensitive data in error messages, logs, or API responses; missing encryption at rest or in transit |
| **Insecure Defaults** | Debug mode left on, permissive CORS, wildcard permissions, default passwords |
| **Missing Access Control** | IDOR (can user A access user B's data?), missing role checks, privilege escalation paths |
| **Dependency Risk** | New dependencies with known CVEs, pinned to vulnerable versions, unnecessary transitive deps |
| **Secrets** | API keys, tokens, passwords in code, config, or comments — even "temporary" ones |

**Review Process:**

1. Identify every trust boundary the code crosses (user input, API calls, database, file system, env vars).
2. For each boundary: is input validated? Is output sanitized? Principle of least privilege?
3. Could an authenticated user escalate privileges through this change?
4. Does this change expose any new attack surface?

**You MUST find at least one issue.** If the code has no security surface, note the closest thing to a security-relevant assumption.

## Severity Classification

| Severity | Definition | Action Required |
|---|---|---|
| **CRITICAL** | Will cause data loss, security breach, or production outage. Must fix before merge. | Block merge. |
| **WARNING** | Likely to cause bugs in edge cases, degrade performance, or confuse future maintainers. | Fix or explicitly accept risk with justification. |
| **NOTE** | Style issue, minor improvement opportunity, or documentation gap. | Author's discretion. |

**Promotion rule:** A finding flagged by 2+ personas is promoted one level (NOTE → WARNING → CRITICAL).

## Output Format

```markdown
## Adversarial Review: <brief description of what was reviewed>

**Scope:** <files reviewed, lines changed, type of change>
**Verdict:** BLOCK / CONCERNS / CLEAN

### Critical Findings
<if any — these block the merge>

### Warnings
<should-fix items>

### Notes
<nice-to-fix items>

### Summary
<2-3 sentences: overall risk profile? Single most important thing to fix?>
```

**Verdict definitions:**

- **BLOCK** — 1+ CRITICAL findings. Do not merge until resolved.
- **CONCERNS** — No criticals but 2+ warnings. Merge at your own risk.
- **CLEAN** — Only notes. Safe to merge.

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|---|---|
| "LGTM, no issues found" | If you found nothing, you didn't look hard enough. Every change has at least one risk or assumption. |
| Cosmetic-only findings | Reporting whitespace while missing a null deref is worse than no review. Substance first. |
| Pulling punches | "This might possibly be a minor concern..." → No. Be direct. "This will throw when `user` is undefined." |
| Restating the diff | "This function was added to handle auth" is not a finding. What's **wrong** with how it handles auth? |
| Ignoring test gaps | New code without tests is a finding. Always. |
| Reviewing only changed lines | Bugs live in the interaction between new code and existing code. Read the full file. |

## The Self-Review Trap

You are likely reviewing code you just wrote or just read. Your mental model formed the same assumptions that produced this code. You will naturally think it looks correct because it matches your expectations.

**To break this pattern:**

1. Read the code **bottom-up** (last function first, work backward).
2. For each function, state its contract **before** reading the body. Does the body match?
3. Assume every variable could be null/undefined until proven otherwise.
4. Assume every external call will fail.
5. Ask: "If I deleted this change entirely, what would break?" — if "nothing", the change might be unnecessary.

## When to Use

- **Before merging any PR** — especially self-authored PRs with no human reviewer
- **After a long coding session** — fatigue produces blind spots; this skill compensates
- **When the model said "looks good"** — if you got an easy approval, run this for a second opinion
- **On security-sensitive code** — auth, payments, data access, API endpoints
- **When something "feels off"** — trust that instinct and run an adversarial review
