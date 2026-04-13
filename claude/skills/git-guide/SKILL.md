---
name: git-guide
description: Help with git operations — commits, branches, merges, rebases, resolving conflicts, recovering from mistakes. Use when the user asks about git, has merge conflicts, or needs help with version control.
---

# Git Guide

Help the user with git operations. Adjust explanations for someone who may be new to git.

## Common Workflows

### Starting new work

```bash
git checkout main
git pull --ff-only origin main
git checkout -b feature/descriptive-name
```

### Saving your work

```bash
git add <specific-files>        # Stage specific files (preferred over git add .)
git commit -m "Short description of what changed"
git push -u origin feature/descriptive-name
```

### Syncing with main

```bash
git fetch origin main
git rebase origin/main          # Linear history
# or: git merge origin/main     # Preserves branching — pick per team convention
```

### Undoing mistakes

- **Undo last commit (keep changes):** `git reset --soft HEAD~1`
- **Unstage a file:** `git restore --staged <file>`
- **Discard local changes to a file:** `git restore <file>`
- **See what changed:** `git diff` (unstaged) or `git diff --cached` (staged)
- **Find a lost commit:** `git reflog` shows HEAD history even after reset

## Merge Conflict Resolution

When conflicts occur:

1. Read the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
2. Understand **both** versions before choosing — don't reflexively accept "theirs" or "ours".
3. After resolving, run the project's tests or smoke checks before committing.
4. If you're deep in a bad merge, `git merge --abort` backs out cleanly.

## Safety Rules

- Never force-push to `main` / `master` / `trunk`.
- Never use `--no-verify` to bypass hooks — fix the root cause instead.
- Always check `git status` before committing.
- Prefer staging specific files over `git add .` to avoid pulling in junk.
- Before any destructive op (`reset --hard`, `clean -fd`, branch delete), run the non-destructive version first to preview.

## Branch Naming Conventions

Common patterns (pick one per repo and stick to it):

- `feature/short-description` — new functionality
- `fix/issue-123-short-description` — bug fixes
- `refactor/area-name` — structural changes with no behavior change
- `chore/deps-update` — housekeeping
- `docs/topic` — documentation-only changes
