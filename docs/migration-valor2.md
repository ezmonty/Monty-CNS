# Migration log: valor2.0 → Monty-CNS

First consolidation pass, mining `ezmonty/valor2.0` for Claude config that
belongs at the user level rather than in the project repo. Source audited at
commit HEAD of `main` on the date of this commit.

## What moved

### Commands (16 files)

All of `.claude/global-commands/*.md` was copied verbatim into
`Monty-CNS/claude/commands/`:

```
commit, debug, deps, docs, explain, explore, feature, fix-issue, migrate,
pr, pre-commit, refactor, review, security-audit, tdd, write-tests
```

These were already designed as portable (zero Valor references — verified
with `grep`) and the existence of the `global-commands/` directory in
valor2.0 was an explicit signal that this was the intended user-level split.
They're now available as slash commands (`/commit`, `/pr`, etc.) on every
machine that runs `bootstrap.sh`.

### Settings — two universal PreToolUse hooks

Merged from `.claude/global-commands/settings.template.json`:

1. **Protect secret-like files on Edit/Write.** Blocks writes to paths
   matching `.env .env.local .env.production credentials secrets .pem .key`.
2. **Block destructive Bash commands.** Rejects `git push --force`,
   `git reset --hard`, `rm -rf`, and `DROP TABLE` unless explicitly
   authorized.

Both cascade to every project from `~/.claude/settings.json`. Projects can
add stricter hooks on top but these are the universal floor.

## What did NOT move, and why

### `.claude/commands/*` (22 project-specialized files) — stay in valor2.0

Diffed against `global-commands/` siblings: the project versions hardcode
Valor-specific paths and commands (`pytest tests/smoke_*.py -v`,
`cd ui/construction-console && npm run lint`, "Valor 2.0 conventions",
concrete examples like `feat: add weather delay tracking to ConstructionOS`).
Keeping them in valor2.0 is correct — Claude Code resolves slash commands
from the project's `.claude/commands/` *before* the user-level fallback, so
inside valor2.0 you still get the specialized versions automatically.

Project-only commands (no generic counterpart): `canon-check`, `lint`,
`new-agent`, `scaffold-component`, `smoke`, `start`.

### `.claude/settings.json` (valor2.0) — stays

Keeps a `PostToolUse` `py_compile` hook (runs `python3 -m py_compile` on
every `.py` write) and a `PostCompact` hook that reminds Claude of Valor's
V2 envelope format and reads from `NOTES.md`. Both are project-specific:

- `py_compile` would be wasteful and noisy in non-Python projects.
- `PostCompact` reminder hardcodes Valor concepts and a `/workspaces/`
  path.

The user-level hooks and the project hooks compose cleanly — Claude Code
runs both.

### `.claude/skills/*` (17 items) — **nothing hoisted this pass**

Every skill had Valor-coupled frontmatter, hardcoded paths, or
project-specific examples. Broken down:

| Skill | Verdict | Reason |
|---|---|---|
| `agent-patterns/` | Stay | 10+ Valor refs, describes Valor agent structure |
| `api-conventions/` | Stay | 7 refs, describes V2 envelope / `/ask` / `/health` |
| `onboarding/` | Stay | 14 refs, literally onboards to Valor |
| `agent-review.md` | Stay | Reviews Valor agents, imports `agents.{AgentName}` |
| `end-of-day.md` | Stay (for now) | Hardcodes `agents/ core/` paths |
| `python-patterns/` | Stay (for now) | Generic concept but paths pin to Valor |
| `react-patterns/` | Stay (for now) | Uses valor2.0 component examples |
| `docker-guide/` | Stay (for now) | References valor2.0 compose file |
| `h-scale.md` | Stay (for now) | Generic framework but tied to Valor canon |
| `git-guide/` | **Rewrite → hoist** | Title says "Git Guide for Valor 2.0" but content is generic git |
| `test-writer/` | **Rewrite → hoist** | Concept is generic, `paths: tests/**/*.py` is project-pinned |
| `code-style/` | **Rewrite → hoist** | Concept is generic, `paths` field pins it to Valor dirs |
| `error-helper/` | **Rewrite → hoist** | Generic triage, branded as "Error Diagnosis — Valor 2.0" |
| `perf-audit/` | **Rewrite → hoist** | Generic perf checks, branded as Valor |
| `explore-codebase/` | **Rewrite → hoist** | Proper frontmatter but mentions `agents, core, configs, tests` dirs |
| `note/` (actually a slash command) | **Rewrite → hoist as command** | Hardcodes `/workspaces/valor2.0/NOTES.md` |
| `note-review/` (actually a slash command) | **Rewrite → hoist as command** | Same hardcoded path |

**Round 2 is not automatic**: each "rewrite → hoist" candidate needs its
description/paths/examples de-branded before it can be shared across
projects. That's a judgment call per file, not a copy-paste.

Recommended approach:
1. Copy the file into `Monty-CNS/claude/skills/<name>/SKILL.md`.
2. Strip `Valor 2.0` from titles and descriptions.
3. Remove or generalize any `paths:` frontmatter that pins it to one
   project.
4. Replace concrete directory references with environment-agnostic
   phrasing or `$CLAUDE_PROJECT_DIR` where applicable.
5. If the skill uses `/workspaces/valor2.0/NOTES.md`, switch to
   `${CLAUDE_PROJECT_DIR:-$HOME}/NOTES.md` or just `$HOME/NOTES.md`
   depending on whether notes are per-project or global.

### `CLAUDE.md`, `AGENTS.md` — stay in valor2.0

Both are project canon / operating law:
- `CLAUDE.md` documents the Valor stack, architecture, commands, mandatory
  read order, and hard rules.
- `AGENTS.md` is "Valor2.0 Codex Operating Law" — references canonical docs
  under `docs/m2codex/`.

Neither belongs at user level. Any *generic* coding principles in there
(e.g. "proof-first workflow", "draft-first for irreversible actions") could
eventually be distilled into a user-level `~/.claude/CLAUDE.md`, but that's
a manual extraction, not a migration.

### `CLAUDE_FULL_REPO_AUDIT.md` — boilerplate, ignore

Contains literal `[briefly describe key functionalities]` placeholders. Not
a real audit. You can delete or fill it in — orthogonal to dotfiles.

## Suggested follow-ups for valor2.0 (not done from here)

These are decisions for you on the valor2.0 side:

1. **Delete `.claude/global-commands/` from valor2.0** — it's now
   redundant with `Monty-CNS/claude/commands/` and having two copies is a
   drift risk. If you prefer to keep it as documentation of "this project's
   baseline", add a note at the top pointing at Monty-CNS as the source of
   truth.
2. **Optionally delete the two universal hooks from
   `.claude/settings.json`** — they're now cascading from user level, so
   having them in both places means every edit fires the check twice (not
   broken, just noisy in logs).
3. **Fill in or remove `CLAUDE_FULL_REPO_AUDIT.md`.**

## Provenance

- Audited: `https://github.com/ezmonty/valor2.0` (public, main branch)
- Files touched in this pass:
  - `claude/commands/*.md` — 16 new files
  - `claude/settings.json` — 2 new `PreToolUse` entries
  - `docs/migration-valor2.md` — this log
