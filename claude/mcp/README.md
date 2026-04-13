# MCP servers

This directory holds **portable MCP configuration**: server definitions, prompt
bundles, and tool manifests you want shared across every machine.

## What goes here

- `servers/<name>.json` — one JSON file per MCP server you want tracked. Keep
  these *declarative*: command, args, env-var **names** (never values).
- `prompts/` — prompt snippets or system-prompt overrides used by your MCP
  clients.

## What does NOT go here

- Secrets, tokens, API keys. Reference them via env vars (`${MY_API_KEY}`) and
  keep the actual values in `~/.claude/.env.local` (gitignored) or your OS
  keychain.
- Per-machine sockets, PIDs, sqlite caches — see `.gitignore`.

## Wiring an MCP server into Claude Code

Claude Code picks up MCP servers from either:

1. `~/.claude.json` (user scope, managed by `claude mcp add …`), or
2. Project-level `.mcp.json` committed next to your code.

For portable setup, commit declarative JSON here and have each machine run
`claude mcp add --scope user --json "$(cat ~/.claude/mcp/servers/foo.json)"` in
the install step, or symlink/import into `~/.claude.json` from your bootstrap.
