# Skills library

Portable, cross-project Claude Code skills. Each skill lives in its own
directory as `<skill-name>/SKILL.md`, following the standard `SKILL.md`
convention: YAML frontmatter + markdown body. That same format works across
Claude Code, Cursor, Gemini CLI, Codex CLI, and Antigravity, so anything
committed here is reusable beyond Claude Code if you ever want it.

## Philosophy

- **Generic by default.** Anything in this directory should be useful in any
  project. If you find yourself writing "Valor 2.0" or a concrete
  `pytest tests/smoke_*.py` command, it belongs in the project's own
  `.claude/skills/`, not here.
- **Cascade:** project-level skills override user-level ones with the same
  name. Keep that in mind when naming — a generic `test-writer` here is a
  fallback for projects that don't define their own.
- **One concern per skill.** If a skill is trying to do two things, split it.

## What's currently here (round 2 from valor2.0 migration)

| Skill | What it does |
|---|---|
| `code-style/` | General naming, structure, and anti-patterns across Python, TypeScript, Go, Rust |
| `error-helper/` | Systematic error triage — read traceback, classify, gather context, first-aid, verify |
| `explore-codebase/` | Deep multi-file investigation using the Explore subagent (forked context) |
| `git-guide/` | Common git workflows, conflict resolution, safety rules, branch conventions |
| `h-scale/` | Capability Honesty Scale (H1-H5) — rate readiness across methodology, data, testing, docs |
| `perf-audit/` | Backend + frontend performance audit checklist |
| `test-writer/` | Detect the project's test framework, pick the right layer, write tests that cover edges |

## Adding a new skill

1. Create `claude/skills/<name>/SKILL.md`.
2. Frontmatter must include `name` and `description` at minimum. Optional:
   `context` (e.g. `fork`), `agent` (e.g. `Explore`), `user_invocable`.
3. Write the body so it works with zero project-specific context — if the
   skill needs to know the test command, it should detect it, not hardcode
   it.
4. Commit + push. Every machine picks it up on next session via the
   `SessionStart` hook.

## Community skill collections worth mining

Instead of writing every skill from scratch, pull from these curated
libraries. Review before adopting — quality varies.

- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) — curated list of Claude Code skills, resources, tools
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — 232+ skills across engineering, marketing, product, compliance, C-level
- [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) — 1,400+ installable skills with a bundle installer CLI
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — 1,000+ agent skills compatible across CC, Codex, Gemini CLI, Cursor
- [BehiSecc/awesome-claude-skills](https://github.com/BehiSecc/awesome-claude-skills) — simpler curated list
- [Anthropic Claude Code skills docs](https://code.claude.com/docs/en/skills) — official `SKILL.md` format and conventions

**Workflow for adopting an external skill:**

1. Clone the source repo to `/tmp`, read the `SKILL.md` end-to-end.
2. Check its license — most are MIT / Apache-2 but verify.
3. Copy into `claude/skills/<name>/` and attribute the source in the
   frontmatter or a trailing comment.
4. Review for safety: does it run shell commands, fetch URLs, touch files?
   Anything dangerous should be obvious before it fires.
5. Commit with a message that names the upstream source so future you
   can trace it back.

## Skills not hoisted from valor2.0 (deliberately)

These stay project-specific in `valor2.0/.claude/skills/` — see
`docs/migration-valor2.md` for the full verdicts:

- `agent-patterns/`, `api-conventions/`, `onboarding/`, `agent-review.md` —
  describe Valor-specific agent architecture
- `python-patterns/`, `react-patterns/`, `docker-guide/` — tied to Valor's
  specific tech choices and compose file
- `end-of-day.md` — hardcodes Valor directory structure
