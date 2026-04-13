# Migration log: valor2.0 → Monty-CNS

Cross-repo consolidation. Audited `ezmonty/valor2.0` (public, main branch).
Two passes so far:

- **Round 1:** commands + settings hooks (mechanical copy).
- **Round 2:** skills that were *generic concepts* buried under Valor
  branding — rewritten from scratch with the branding and hardcoded
  paths stripped out.

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

### Round 2: skills rewrites (7 hoisted, 10 still project-scoped)

After round 1 shipped, the skills were revisited. The ones whose *concept*
was generic but whose *branding* was Valor-specific got rewritten from
scratch — same structure, same checklists, no project names or hardcoded
paths. Rewriting (not copying) was important because the old versions had
`paths:` frontmatter pinning them to valor2.0 dirs, Valor-specific examples
in code blocks, and `V2 envelope` / `pytest tests/smoke_*` commands peppered
throughout.

Hoisted in round 2:

| Skill | Source | Changes |
|---|---|---|
| `code-style/` | `valor2.0/.claude/skills/code-style/SKILL.md` | Dropped `paths:` field, removed Valor examples, added Go + Rust sections, rewrote Python/TS examples with generic names |
| `error-helper/` | `valor2.0/.claude/skills/error-helper/SKILL.md` | Stripped MontyCore port numbers, generalized pattern table, added SSL / EACCES rows, added "measurement first" principle |
| `explore-codebase/` | `valor2.0/.claude/skills/explore-codebase/SKILL.md` | Kept `context: fork` / `agent: Explore`, generalized "agents, core, configs" references to "routing tables, config files, module indices", added disambiguation rule |
| `git-guide/` | `valor2.0/.claude/skills/git-guide/SKILL.md` | Removed "for Valor 2.0" title, removed Valor branch convention section, added `git reflog` recovery, `merge --abort`, project-agnostic branch naming |
| `h-scale/` | `valor2.0/.claude/skills/h-scale.md` | Kept the full framework verbatim, dropped the Valor-specific system breakdown ("Portfolio Analytics", "core/finance_db.py"), dropped `docs/m2codex` references, added general "when to use" section |
| `perf-audit/` | `valor2.0/.claude/skills/perf-audit/SKILL.md` | Removed Valor port/agent refs, added DB-specific section, added "measurement first" principle with tool suggestions |
| `test-writer/` | `valor2.0/.claude/skills/test-writer/SKILL.md` | Dropped `paths: tests/**/*.py`, replaced V2 envelope template with framework-detection flow, added TypeScript Vitest/Jest example, added layer-choice table |

Also hoisted (as commands, not skills — they were actually slash commands
living under `skills/`):

| Command | Source | Changes |
|---|---|---|
| `/note` | `valor2.0/.claude/skills/note/SKILL.md` | Path resolution switched from `/workspaces/valor2.0/NOTES.md` to `$NOTES_FILE → ${CLAUDE_PROJECT_DIR:-$PWD}/NOTES.md → $HOME/NOTES.md`, added `#decision` and `#bug` tags, moved to `claude/commands/` with proper frontmatter |
| `/note-review` | `valor2.0/.claude/skills/note-review/SKILL.md` | Same path resolution change, added "offer to clean up" step, clarified non-destructive archive semantics |

### Round 2: skills still NOT hoisted

These describe Valor-specific architecture and would be noise in other
projects. They belong in `valor2.0/.claude/skills/`:

| Skill | Reason it stays |
|---|---|
| `agent-patterns/` | Describes Valor agent class/port structure, V2 envelope |
| `api-conventions/` | Describes V2 envelope, `/ask`, `/health`, `/run` endpoints |
| `onboarding/` | Onboards a new dev to valor2.0 specifically |
| `agent-review.md` | Reviews Valor agents via `import agents.{Name}` |
| `python-patterns/` | Python conventions tied to Valor module layout |
| `react-patterns/` | Mantine + Zustand patterns for valor2.0 console |
| `docker-guide/` | Walks the valor2.0 `docker-compose.yml` |
| `end-of-day.md` | Hardcodes `find agents/ core/` paths |

If any of these ever need a generic cousin (e.g. a `python-patterns` that
isn't Valor-specific), the pattern is the same as round 2: write a fresh
`claude/skills/<name>/SKILL.md` from scratch, don't copy.

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
