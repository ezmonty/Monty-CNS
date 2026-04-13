# Monty-CNS

Private dotfiles for `~/.claude` — Claude Code settings, hooks, agents,
commands, skills, and MCP server configs — synced across every machine
(laptop, desk, work, home) via git + symlinks.

## Layout

```
Monty-CNS/
├── bootstrap.sh        # symlink installer (idempotent, backs up conflicts)
├── claude/             # mirrors ~/.claude — only tracked, portable files
│   ├── settings.json
│   ├── stop-hook-git-check.sh
│   ├── hooks/
│   │   ├── session-start.sh     # pulls repo + bootstrap + loads env each session
│   │   └── session-start.d/     # drop-in plugins (secret decryption, etc.)
│   ├── agents/
│   ├── commands/
│   └── mcp/            # MCP server definitions (no secrets)
├── docs/
│   ├── self-hosting.md # running your own git remote on your rack
│   └── secrets.md      # sops/age + drop-in flow for secrets
└── .gitignore          # blocks secrets, sessions, runtime state
```

## Install on a new machine

```bash
git clone <your-remote>:ezmonty/Monty-CNS.git ~/src/Monty-CNS
cd ~/src/Monty-CNS
./bootstrap.sh --dry-run   # preview
./bootstrap.sh             # create the symlinks under ~/.claude
```

Pre-existing files at conflicting paths are moved to
`~/.claude/backups/<timestamp>/`, never deleted.

## Update

```bash
cd ~/src/Monty-CNS && git pull && ./bootstrap.sh
```

## Uninstall

```bash
./bootstrap.sh --unlink
```

## Adding new tracked files

1. Drop the file under `claude/<path>` in this repo.
2. Commit and push.
3. On every other machine, `git pull && ./bootstrap.sh`.

Bootstrap currently symlinks **top-level entries** in `claude/` (files and
dirs) into `~/.claude`. If you need a directory to hold a mix of tracked and
untracked files on the live machine, track individual leaf files instead of
the whole directory — see `docs/self-hosting.md` for details.

## Self-hosting the remote

See `docs/self-hosting.md` for three options (plain SSH git, Forgejo/Gitea,
Tailscale-fronted) — all small enough to run on a one-box rack.

## What's never committed

- `.credentials.json`, `.env*`, SSH/GPG keys
- `projects/`, `sessions/`, `todos/`, `statsig/`, `shell-snapshots/`,
  `session-env/`, `backups/`, `.claude.json`
- MCP runtime state (sqlite, sockets, `node_modules`)

Config, yes. State, no. Secrets, never.
