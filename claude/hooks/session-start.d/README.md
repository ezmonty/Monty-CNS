# session-start.d — drop-in plugins

The `session-start.sh` hook runs every executable `*.sh` in this directory
(alphabetically) after pulling the repo and running `bootstrap.sh`. Use this
for anything that shouldn't live in the main hook because it's host-specific,
secret-handling, or optional.

Conventions:

- Each script is a single concern. Prefix with a number if order matters:
  `10-decrypt-sops.sh`, `20-refresh-mcp-tokens.sh`.
- Exit non-zero on failure; the main hook logs and continues.
- Write any secrets to `~/.claude/.env.local` (for env vars — already loaded
  into `$CLAUDE_ENV_FILE` by the main hook *before* drop-ins run, so if you
  want your vars visible this session, write them directly to
  `$CLAUDE_ENV_FILE` inside your drop-in) or to the specific file a tool
  expects.
- `$CLAUDE_ENV_FILE`, `$CLAUDE_PROJECT_DIR`, `$CLAUDE_CODE_REMOTE` are
  available — see `claude/skills/session-start-hook/SKILL.md`.

Example stubs for the two common secret stores:

## `10-decrypt-sops.sh` (age + sops)

```bash
#!/usr/bin/env bash
set -euo pipefail

secrets_repo="$HOME/src/Monty-CNS-secrets"
[[ -d "$secrets_repo" ]] || exit 0

# Pull encrypted secrets (non-fatal if offline).
timeout 10s git -C "$secrets_repo" pull --ff-only --quiet || true

# Decrypt the env bundle directly into the session's env file.
if [[ -f "$secrets_repo/env.sops.yaml" && -n "${CLAUDE_ENV_FILE:-}" ]]; then
  sops -d "$secrets_repo/env.sops.yaml" |
    jq -r 'to_entries[] | "export \(.key)=\(.value|@sh)"' \
    >> "$CLAUDE_ENV_FILE"
fi
```

## `10-load-pass.sh` (password-store)

```bash
#!/usr/bin/env bash
set -euo pipefail

command -v pass >/dev/null || exit 0
[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0

for entry in claude/anthropic-api-key claude/mcp/github-token; do
  var="$(basename "$entry" | tr 'a-z-' 'A-Z_')"
  value="$(pass show "$entry" 2>/dev/null || true)"
  [[ -n "$value" ]] && printf 'export %s=%q\n' "$var" "$value" >> "$CLAUDE_ENV_FILE"
done
```

Drop either file in, `chmod +x` it, and it runs on next session start. Neither
is tracked by default — they're your per-host choice.
