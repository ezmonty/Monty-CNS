#!/usr/bin/env bash
# SessionStart drop-in: detect vault and load pod context into $CLAUDE_ENV_FILE.
# No-ops silently if vault not found (Principle 4: degrade, don't break).

set -euo pipefail

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0

# 1. Detect project name from git remote or PWD basename.
project=""
if remote="$(git remote get-url origin 2>/dev/null)"; then
  project="$(basename "$remote" .git)"
else
  project="$(basename "$PWD")"
fi
project="$(printf '%s' "$project" | tr '[:upper:]' '[:lower:]')"

# 2. Locate the vault.
vault=""
if [[ -d "$PWD/monty-ledger" ]]; then
  vault="$PWD/monty-ledger"
elif [[ -d "$HOME/src/Monty-Ledger" ]]; then
  vault="$HOME/src/Monty-Ledger"
fi

[[ -n "$vault" ]] || exit 0

# 3. Write vault root so other tools can find it.
printf 'export VAULT_ROOT="%s"\n' "$vault" >> "$CLAUDE_ENV_FILE"

# 4. Try to find a matching pod for the current project.
pods_dir="$vault/13_Pods"
if [[ -d "$pods_dir" ]]; then
  pod_file="$(grep -ril "$project" "$pods_dir"/*.md 2>/dev/null | head -n1 || true)"
  if [[ -n "$pod_file" ]]; then
    printf 'export VAULT_POD="%s"\n' "$pod_file" >> "$CLAUDE_ENV_FILE"
  fi
fi

exit 0
