# MCP servers — portable config

This directory holds **declarative** MCP server definitions that should be
available on every machine. Each tracked server is a JSON file under
`servers/` describing how to install it, how to launch it, and which
secrets (if any) it needs. No plaintext secrets — the values come from
`Monty-CNS-Secrets` via the `SessionStart` hook + `10-decrypt-sops.sh`
drop-in.

## Layout

```
claude/mcp/
├── README.md              # this file
├── install-servers.sh     # reads servers/*.json and runs `claude mcp add`
├── keys/                  # runtime-decrypted file secrets (gitignored, 0600)
└── servers/
    ├── github.json        # GitHub API — needs GITHUB_PERSONAL_ACCESS_TOKEN
    ├── filesystem.json    # Sandboxed fs access to specific dirs — no secrets
    └── fetch.json         # HTTP fetch / markdown conversion — no secrets
```

## Install flow

On a machine that already has `Monty-CNS` bootstrapped and `claude` CLI on
PATH:

```bash
cd ~/.claude/mcp
./install-servers.sh --dry-run    # preview
./install-servers.sh              # install all tracked servers at user scope
./install-servers.sh github       # install just one
./install-servers.sh --list       # list tracked + registered status
```

The script:

1. Iterates every `servers/*.json`.
2. Checks `claude mcp list` — skips servers already registered.
3. Runs `claude mcp add --scope user --name <N> --json <config>` for each
   missing one, with a fallback to the decomposed-args form for older
   `claude` CLI versions.
4. Reminds you of any `secrets_required` vars that need to be in
   `env.sops.yaml` before the server will actually work.

## JSON shape

Each file in `servers/` follows this shape:

```json
{
  "name": "<server-name>",
  "description": "<one-line description>",
  "scope": "user",
  "upstream": "<link to the server's docs/repo>",
  "install": {
    "command": "<how to install — npm / pip / etc.>",
    "args": ["..."],
    "alt_install": "<optional second path>"
  },
  "config": {
    "command": "<how to launch>",
    "args": ["..."],
    "env": {
      "OPTIONAL_OVERRIDE": "static-value"
    }
  },
  "secrets_required": [
    {
      "env": "ENV_VAR_NAME",
      "description": "What it is and how to get it",
      "store_in": "env.sops.yaml"
    }
  ],
  "notes": [
    "freeform notes, gotchas, safety reminders"
  ]
}
```

Only `name`, `description`, and `config` are strictly required. Everything
else is best-effort documentation.

## Secret flow, end-to-end

```
Monty-CNS-Secrets/env.sops.yaml      (encrypted)
        │
        ├─ SessionStart hook
        │    └─ 10-decrypt-sops.sh
        │         └─ decrypts → $CLAUDE_ENV_FILE
        │
        └─> Claude Code session inherits the env
                 │
                 └─> spawns MCP server subprocess
                       (inherits env by default — no translation needed)
```

**Important:** store each secret in `env.sops.yaml` under **the exact
variable name the MCP server expects**. For example:

```yaml
# env.sops.yaml (inside Monty-CNS-Secrets, encrypted)
ANTHROPIC_API_KEY: sk-ant-...
GITHUB_PERSONAL_ACCESS_TOKEN: ghp_...   # NOT "GITHUB_MCP_TOKEN"
BRAVE_SEARCH_API_KEY: ...
```

That way the MCP server config doesn't need any `env:` translation —
the subprocess just reads the inherited var directly.

## Adding a new server

1. Find the server's package name and docs. Official Anthropic servers
   live at [github.com/modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers).
2. Create `servers/<name>.json` with the shape above.
3. If it needs a secret, add the env var to `Monty-CNS-Secrets/env.sops.yaml`
   (`sops env.sops.yaml`), commit + push.
4. Commit + push Monty-CNS.
5. On each machine: `cd ~/.claude/mcp && ./install-servers.sh`
6. Start a new Claude Code session — the server is now registered and its
   secret is in the session env.

## File-based secrets (rare)

Some servers need an actual file on disk (service account JSON, SSH key,
TLS cert). Put those in `Monty-CNS-Secrets/mcp/<name>.sops.<ext>`; the
drop-in decrypts them into `~/.claude/mcp/keys/<name>.<ext>` at 0600. The
server config then references the plaintext path:

```json
"env": {
  "GOOGLE_APPLICATION_CREDENTIALS": "~/.claude/mcp/keys/service-account.json"
}
```

`~/.claude/mcp/keys/` is gitignored.

## What does NOT belong here

- **Plaintext secrets, tokens, keys.** Ever. Not even "temporarily".
- **Per-machine runtime state** — sqlite caches, node_modules, sockets,
  PID files. `.gitignore` blocks these; if you see one, something is
  misconfigured.
- **Project-scoped MCP servers** — those go in the project's own
  `.mcp.json`. Anything tracked here should be useful to every project.
