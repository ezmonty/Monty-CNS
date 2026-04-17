#!/usr/bin/env bash
# SessionStart drop-in: decrypt sops-encrypted secrets into the session.
#
# Runs automatically from session-start.sh if executable. No-ops cleanly when:
#   - the Monty-CNS-Secrets repo isn't cloned,
#   - sops / age aren't installed,
#   - no age key is present,
#   - $CLAUDE_ENV_FILE isn't set (i.e. we're not inside a Claude Code session).
#
# Expected layout (see docs/secrets-setup.md to set it up):
#   ~/src/Monty-CNS-Secrets/
#     ├── .sops.yaml         # recipient list
#     ├── env.sops.yaml      # env vars: { KEY: value, ... }
#     └── mcp/*.sops.*       # optional per-MCP-server secret files
#
# Override the repo location with $SECRETS_REPO.

set -euo pipefail
umask 077

SECRETS_REPO="${SECRETS_REPO:-$HOME/src/Monty-CNS-Secrets}"
AGE_KEY="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

log() { printf '[decrypt-sops] %s\n' "$*" >&2; }

# 1. Preconditions — every "no-op, not a failure" exits 0.
[[ -n "${CLAUDE_ENV_FILE:-}" ]]   || { log "no CLAUDE_ENV_FILE set, skipping"; exit 0; }
[[ -d "$SECRETS_REPO" ]]          || { log "$SECRETS_REPO not cloned, skipping"; exit 0; }
command -v sops >/dev/null 2>&1   || { log "sops not installed, skipping"; exit 0; }
command -v age  >/dev/null 2>&1   || { log "age not installed, skipping"; exit 0; }
[[ -r "$AGE_KEY" ]]               || { log "age key $AGE_KEY not readable, skipping"; exit 0; }

export SOPS_AGE_KEY_FILE="$AGE_KEY"

# 2. Pull latest encrypted secrets, short timeout, offline-tolerant.
if git -C "$SECRETS_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  if ! timeout 10s git -C "$SECRETS_REPO" pull --ff-only --quiet 2>/dev/null; then
    log "pull failed or offline — using local ciphertext"
  fi
fi

# 3. Decrypt env.sops.yaml (the main env bundle) into $CLAUDE_ENV_FILE.
#    Expected shape: a flat YAML map of KEY: value pairs.
env_file="$SECRETS_REPO/env.sops.yaml"
if [[ -f "$env_file" ]]; then
  if plain="$(sops -d "$env_file" 2>/dev/null)"; then
    # Convert YAML to export lines. Use yq if available, else a minimal parser.
    if command -v yq >/dev/null 2>&1; then
      printf '%s' "$plain" | yq -r 'to_entries[] | "export \(.key)=" + (.value | @sh)' \
        >> "$CLAUDE_ENV_FILE"
    else
      # Minimal YAML flat-map parser: KEY: value (no nesting, no lists, no anchors).
      printf '%s\n' "$plain" | awk '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        /^[A-Za-z_][A-Za-z0-9_]*:/ {
          key = $1; sub(":", "", key)
          sub(/^[^:]*:[[:space:]]*/, "", $0)
          gsub(/^"|"$/, "", $0)
          gsub(/^'\''|'\''$/, "", $0)
          gsub(/'\''/, "'\''\\'\'\\''\'\'''\'", $0)
          printf "export %s='\''%s'\''\n", key, $0
        }
      ' >> "$CLAUDE_ENV_FILE"
    fi
    log "loaded $(basename "$env_file") into CLAUDE_ENV_FILE"
  else
    log "failed to decrypt $env_file (wrong recipient? missing key?)"
  fi
fi

# 4. Decrypt file-based secrets into ~/.claude/mcp/keys/ (0600).
#    Any file under secrets/mcp/ whose name ends in .sops.<ext> gets
#    decrypted to ~/.claude/mcp/keys/<name>.<ext> minus the .sops. part.
keys_dir="${CLAUDE_HOME:-$HOME/.claude}/mcp/keys"
if [[ -d "$SECRETS_REPO/mcp" ]]; then
  mkdir -p "$keys_dir"
  chmod 700 "$keys_dir"
  shopt -s nullglob
  for enc in "$SECRETS_REPO/mcp"/*.sops.*; do
    name="$(basename "$enc")"
    # foo.sops.key → foo.key
    out_name="${name/.sops./.}"
    out="$keys_dir/$out_name"
    if sops -d "$enc" > "$out.tmp" 2>/dev/null; then
      chmod 600 "$out.tmp"
      mv "$out.tmp" "$out"
      log "decrypted $name → $out"
    else
      rm -f "$out.tmp"
      log "failed to decrypt $name"
    fi
  done
  shopt -u nullglob
fi

exit 0
