#!/usr/bin/env bash
# SessionStart hook for Monty-CNS.
#
# Wired in via ~/.claude/settings.json. Runs at the start of every Claude
# Code session. Uses async mode so network work doesn't block startup.
#
# What it does, in order:
#   1. Fast-forward pulls the dotfiles repo (offline-tolerant, 10s timeout).
#   2. Reconciles ~/.claude symlinks via bootstrap.sh.
#   3. Loads ~/.claude/.env.local into $CLAUDE_ENV_FILE so the session
#      (and any MCP servers it spawns) sees those vars.
#   4. Runs any drop-in scripts at ~/.claude/hooks/session-start.d/*.sh.
#      This is where you plug in secret decryption (sops/age, pass, etc.).
#
# Non-goals: this hook does NOT touch .credentials.json (OAuth tokens are
# machine-local) and does NOT fail the session if anything goes wrong —
# everything non-critical is logged to ~/.claude/logs/session-start.log.

set -euo pipefail

# 1. Tell Claude Code we're async — everything after this runs in the background.
printf '%s\n' '{"async": true, "asyncTimeout": 120000}'

# 2. Drain stdin (the hook input JSON) so Claude Code's pipe closes cleanly.
input="$(cat || true)"
source_kind="$(printf '%s' "$input" | jq -r '.source // "startup"' 2>/dev/null || echo startup)"

# 3. Only do heavy work on a fresh startup, not resume/clear/compact.
if [[ "$source_kind" != "startup" ]]; then
  exit 0
fi

# 4. Resolve the repo root by following our own symlink back to the repo.
#    readlink -f is GNU-only; macOS ships BSD readlink without -f.
#    Use python3 (always available on macOS) as the portable fallback.
hook_src="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null \
  || python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${BASH_SOURCE[0]}" 2>/dev/null \
  || echo "${BASH_SOURCE[0]}")"
repo_root="$(cd "$(dirname "$hook_src")/../.." && pwd)"

claude_home="${CLAUDE_HOME:-$HOME/.claude}"
log="$claude_home/logs/session-start.log"
mkdir -p "$(dirname "$log")"

# 5. Fork the real work into the background and detach stdio so Claude Code's
#    hook pipe closes immediately.
(
  exec >> "$log" 2>&1
  printf '\n=== %s session-start (source=%s) ===\n' "$(date -Is)" "$source_kind"
  printf 'repo_root=%s\n' "$repo_root"

  # 5a. Pull latest dotfiles — short timeout, never hard-fails.
  if git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
    if timeout 10s git -C "$repo_root" fetch --quiet origin; then
      branch="$(git -C "$repo_root" branch --show-current || true)"
      if [[ -n "$branch" ]] && git -C "$repo_root" rev-parse --verify --quiet "origin/$branch" >/dev/null; then
        git -C "$repo_root" merge --ff-only "origin/$branch" \
          || echo "ff-only merge failed (local diverged from origin/$branch)"
      fi
    else
      echo "fetch failed or offline — skipping pull"
    fi
  else
    echo "repo_root is not a git repo — skipping pull"
  fi

  # 5b. Reconcile symlinks.
  if [[ -x "$repo_root/bootstrap.sh" ]]; then
    "$repo_root/bootstrap.sh" || echo "bootstrap.sh failed"
  fi

  # 5c. Load ~/.claude/.env.local into $CLAUDE_ENV_FILE so MCP servers
  #     and subsequent tool calls inherit the vars. .env.local is gitignored
  #     and is where decrypted secrets land.
  env_local="$claude_home/.env.local"
  if [[ -n "${CLAUDE_ENV_FILE:-}" && -f "$env_local" ]]; then
    echo "loading $env_local into CLAUDE_ENV_FILE"
    # Accept KEY=value lines, skip comments/blanks, export them.
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      printf 'export %s\n' "$line" >> "$CLAUDE_ENV_FILE"
    done < "$env_local"
  fi

  # 5d. Run drop-in extensions. Each is a standalone concern.
  #     Typical plugins: decrypt-sops.sh, refresh-mcp-tokens.sh, etc.
  dropdir="$claude_home/hooks/session-start.d"
  if [[ -d "$dropdir" ]]; then
    for f in "$dropdir"/*.sh; do
      [[ -f "$f" && -x "$f" ]] || continue
      echo "run $f"
      "$f" || echo "drop-in $f failed (non-fatal)"
    done
  fi

  echo "=== done $(date -Is) ==="
) </dev/null >/dev/null 2>&1 &
disown || true

exit 0
