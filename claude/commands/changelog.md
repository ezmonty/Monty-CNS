---
description: Generate a changelog entry from git history (Keep a Changelog format) or lint commit messages for Conventional Commits format. Prompt-only — uses git log directly, no external scripts.
---

# /changelog

Generate or validate changelogs using only `git log` — no Python scripts, no external dependencies.

Target: `$ARGUMENTS` (subcommand + flags; see Usage)

## Usage

```
/changelog generate [--from <ref>] [--to <ref>] [--format markdown|json]
/changelog lint [--from <ref>] [--to <ref>] [--strict]
```

If `$ARGUMENTS` is empty, default to `generate --from <last-tag> --to HEAD` in markdown format.

## Subcommand: `generate`

Produce a Keep a Changelog-style section from the commits in the given range.

### Steps

1. **Resolve the range.**
   - `--from <ref>` / `--to <ref>` take precedence.
   - Otherwise use the output of `git describe --tags --abbrev=0` as `--from`, and `HEAD` as `--to`.
   - If there are no tags in the repo, fall back to the first commit (`git rev-list --max-parents=0 HEAD`).
   - If there are no commits in the range, report that and stop.

2. **Read the commits.**
   ```bash
   git log --pretty=format:'%H%x1f%s%x1f%b%x1e' --no-merges <from>..<to>
   ```
   Each record is `hash \x1f subject \x1f body \x1e`. Parse into a list.

3. **Categorize by conventional-commit prefix.**
   Map the subject prefix to a section heading:

   | Prefix | Section |
   |---|---|
   | `feat`, `feature` | Added |
   | `fix`, `bugfix` | Fixed |
   | `refactor`, `perf` | Changed |
   | `revert` | Reverted |
   | `deprecate` | Deprecated |
   | `remove` | Removed |
   | `docs` | Documentation |
   | `test`, `chore`, `build`, `ci`, `style` | *(omit from main changelog; list under "Internal" if user asks)* |
   | *(no prefix)* | Changed |

   Preserve any scope: `feat(auth): add SSO` becomes `**auth:** add SSO` under Added.

4. **Render Keep a Changelog markdown.**

   ```markdown
   ## [Unreleased] — YYYY-MM-DD

   ### Added
   - **scope:** subject (short-hash)

   ### Fixed
   - subject (short-hash)

   ### Changed
   - subject (short-hash)
   ```

   Use the short hash (first 7 chars) in parentheses at the end of each bullet so the entry is traceable.

5. **Handle breaking changes.**
   - Any commit whose subject contains `!` after the type (`feat!:` or `feat(scope)!:`), OR whose body contains a `BREAKING CHANGE:` line, goes into a dedicated `### Breaking` section **before** Added, and is prefixed with **BREAKING:** in bold.

6. **Output.**
   - `--format markdown` (default) → print the rendered section as a code block so the user can paste into `CHANGELOG.md`.
   - `--format json` → print `{"added": [...], "fixed": [...], "changed": [...], "breaking": [...], "removed": [...], "deprecated": [...], "reverted": [...], "documentation": [...]}` with each entry as `{hash, subject, scope, body}`.

## Subcommand: `lint`

Validate that commits in the given range follow Conventional Commits format.

### Rules

A commit is valid if its subject matches:

```
<type>(<scope>)?!?: <description>
```

Where:

- `<type>` is one of: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`, `deprecate`, `remove`
- `<scope>` (optional) is an identifier in parens, e.g. `(auth)`, `(api)`
- `!` (optional) flags a breaking change
- `:` followed by a space and a non-empty description

### Steps

1. Resolve the range (same as `generate`).
2. For each commit in the range, check the subject against the regex.
3. Report:
   ```
   ## Commit lint — <from>..<to>

   <N> commits total, <M> valid, <K> invalid

   Invalid commits:
   - <short-hash>  <subject>
     reason: <missing type | unknown type | missing colon | empty description | ...>
   ```
4. With `--strict`, also require:
   - Subject line ≤ 72 characters.
   - No trailing period in the subject.
   - Body wrapped at 72 characters per line (if present).

### Return code

- If invoked as part of a workflow (e.g. `pre-commit`), signal failure when any commit is invalid.

## Examples

```
/changelog generate
   → generates entries from the last tag to HEAD, markdown format

/changelog generate --from v2.0.0 --to v2.1.0
   → entries for that specific release

/changelog generate --format json
   → same data, machine-readable

/changelog lint --from main --to HEAD
   → validate every commit on the current branch

/changelog lint --from HEAD~5 --to HEAD --strict
   → strict check on the last 5 commits
```

## Rules

- **Never fabricate commits.** If there are none in the range, say so.
- **Never invent a tag.** If `git describe` finds nothing, fall back to first commit or ask.
- **Preserve scope.** `feat(auth):` stays visible in the changelog entry.
- **Omit noise by default** from generate (test/chore/build/ci/style), but include everything in lint.
- **Link hashes.** Short hashes let the user jump to the commit in any viewer.
