# Monty-CNS Quickstart

## 30 seconds — bare minimum

```bash
git clone <repo-url> ~/src/Monty-CNS
cd ~/src/Monty-CNS
./install.sh
```

Say **yes** to symlinks. You can skip secrets and MCP server setup for now.
Claude Code works immediately after this step — commands, skills, and hooks are active.

## 5 minutes — full setup

1. **Activate secrets** (API keys, tokens):
   ```bash
   ./activate-secrets.sh
   ```
   This decrypts sops-encrypted env vars into your session. Requires `sops` and `age` installed with a valid key at `~/.config/sops/age/keys.txt`.

2. **Install MCP servers** (web search, vault memory):
   ```bash
   ~/.claude/mcp/install-servers.sh
   ```
   Registers github, filesystem, fetch, memory, brave-search, and ledger MCP
   servers with Claude Code. Requires `claude` CLI to be installed.
   Now you have API keys, web search, and vault-backed knowledge available.

## First session — try these

| Command        | What it does                                      |
|----------------|---------------------------------------------------|
| `/foreman`     | Status rollup — shows what's active and healthy   |
| `/learn`       | Capture a finding into the vault                  |
| `/brief`       | Generate a cross-session handoff document         |
| `/healthcheck` | Diagnose problems if something feels wrong        |
| `/vault inbox` | See what's waiting in the vault inbox             |

If something is not working, run `/healthcheck` first. It checks secrets, MCP connectivity,
vault access, and reports what is missing.
