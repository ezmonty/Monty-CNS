---
description: Re-run the Monty-CNS installer from inside a Claude Code session — pulls the dotfiles repo, syncs symlinks, optionally activates secrets, and installs MCP servers. Use this when you want to re-sync after a config change without leaving the chat.
---

# /newmachine

Re-run the Monty-CNS installer to (re-)set up `~/.claude` on the current
machine. This is the inside-session equivalent of running
`~/src/Monty-CNS/install.sh` from the terminal — same script, same flags,
same idempotent behavior.

## When to use

- **You changed a tracked file in the repo** on another machine, pushed
  it, and want this machine to pick up the change without restarting your
  Claude Code session. (Note: the SessionStart hook already does this on
  every new session — `/newmachine` is for "right now" syncs.)
- **You want to re-run a single phase**. Pass `--bootstrap-only`,
  `--secrets-only`, or `--mcp-only` and only that phase fires.
- **Bootstrap left something in a weird state** and you want to verify by
  running the installer's `--status` checks.

## What it does NOT do

- It does NOT clone the repo. If `~/src/Monty-CNS` doesn't exist, this
  command tells you to run the one-liner from the terminal first. (Slash
  commands run inside a Claude Code session, which means CNS is already
  installed enough to have THIS slash command available.)
- It does NOT replace the curl/git-clone one-liner for setting up a
  brand-new machine — see the README for that.

## Steps

### 1. Locate the repo

The Monty-CNS repo is at `${MONTY_CNS_DIR:-$HOME/src/Monty-CNS}`. Verify:

```bash
test -d "${MONTY_CNS_DIR:-$HOME/src/Monty-CNS}/.git" \
  && echo "found" \
  || echo "NOT FOUND — run the one-liner from the README first"
```

If not found, stop and tell the user how to set it up:

```bash
git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh
```

### 2. Run the installer

If found, invoke the installer with the appropriate scope based on `$ARGUMENTS`:

| Argument | Action |
|---|---|
| (empty) | Full install (bootstrap + secrets + MCP) — interactive |
| `--bootstrap-only` | Only run `bootstrap.sh` |
| `--secrets-only` | Only run `activate-secrets.sh` |
| `--mcp-only` | Only run `~/.claude/mcp/install-servers.sh` |
| `--status` | Just report state (bootstrap dry-run + activate-secrets --status + install-servers --list) |
| `--yes` | Pass through to all sub-scripts for unattended re-sync |

### 3. Report what happened

Show the user:
- What phase(s) ran
- Any warnings or skipped phases (e.g. `claude` CLI missing → MCP phase skipped)
- A pointer to `~/.claude/logs/session-start.log` for the SessionStart hook trail

## Behavior rules

- **Idempotent.** Run it twice in a row, it should be a no-op the second time.
- **Never destructive.** All three sub-scripts back up conflicts to
  `~/.claude/backups/<timestamp>/` rather than overwriting.
- **Read-only by default in `--status` mode.** No file changes.
- **Honors `MONTY_CNS_DIR`** if the user has cloned somewhere other than `~/src/Monty-CNS`.

## Example invocations

```
/newmachine                     # full re-sync, interactive
/newmachine --status            # just tell me what's installed
/newmachine --bootstrap-only    # I just edited a tracked file, re-link
/newmachine --yes               # unattended, full re-sync
```
