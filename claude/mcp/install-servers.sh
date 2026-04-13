#!/usr/bin/env bash
# install-servers.sh — install tracked MCP servers at user scope.
#
# Reads every JSON file in claude/mcp/servers/ and runs `claude mcp add`
# for each. Safe to re-run: skips servers that are already registered.
#
# Usage:
#   ./install-servers.sh                # install all
#   ./install-servers.sh github fetch   # install only the named ones
#   ./install-servers.sh --list         # list tracked + registered
#   ./install-servers.sh --dry-run      # show what would be added

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_DIR="$HERE/servers"

DRY_RUN=0
LIST=0
FILTER=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --list)    LIST=1 ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) FILTER+=("$arg") ;;
  esac
done

if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not found on PATH — install Claude Code first" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: 'jq' not found — install it first (brew/apt/pacman install jq)" >&2
  exit 1
fi

# Get the list of already-registered MCP servers from claude mcp list
# (output format varies across Claude Code versions, so be tolerant).
registered() {
  claude mcp list 2>/dev/null | awk '
    /^[a-zA-Z0-9_-]+/ { print $1 }
  ' | sort -u
}

already="$(registered || true)"

say()  { printf '%s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then say "DRY: $*"; else eval "$@"; fi; }

install_one() {
  local json="$1"
  local name
  name="$(jq -r '.name' "$json")"

  # Filter
  if [[ ${#FILTER[@]} -gt 0 ]]; then
    local keep=0
    for f in "${FILTER[@]}"; do
      [[ "$f" == "$name" ]] && keep=1 && break
    done
    [[ $keep -eq 0 ]] && return 0
  fi

  if printf '%s\n' "$already" | grep -Fxq "$name"; then
    say "  ok    $name already registered"
    return 0
  fi

  local scope
  scope="$(jq -r '.scope // "user"' "$json")"

  # Build the claude mcp add invocation from the JSON config block.
  # We pass the config as --json so we don't have to reconstruct it.
  local config
  config="$(jq -c '.config' "$json")"

  say "  add   $name (scope=$scope)"

  if [[ $DRY_RUN -eq 1 ]]; then
    say "    DRY: claude mcp add --scope $scope --name $name --json '$config'"
    return 0
  fi

  # claude mcp add syntax varies — try the JSON form first, fall back.
  if ! claude mcp add --scope "$scope" --name "$name" --json "$config" 2>/dev/null; then
    # Fallback: decompose the config and pass positional/flag args.
    local cmd args_json env_json
    cmd="$(jq -r '.config.command' "$json")"
    args_json="$(jq -c '.config.args // []' "$json")"
    env_json="$(jq -c '.config.env // {}' "$json")"

    # Build args as -- separated positional args
    local -a cli_args=(mcp add --scope "$scope" "$name" "$cmd")
    while read -r arg; do
      cli_args+=("$arg")
    done < <(jq -r '.config.args // [] | .[]' "$json")

    claude "${cli_args[@]}"
  fi

  say "        → registered"
}

list_mode() {
  printf '%-20s  %-12s  %-10s  %s\n' "NAME" "REGISTERED" "SECRETS" "DESCRIPTION"
  printf '%-20s  %-12s  %-10s  %s\n' "----" "----------" "-------" "-----------"
  for json in "$SERVERS_DIR"/*.json; do
    [[ -f "$json" ]] || continue
    local name reg secrets desc
    name="$(jq -r '.name' "$json")"
    desc="$(jq -r '.description' "$json" | head -c 60)"
    if printf '%s\n' "$already" | grep -Fxq "$name"; then
      reg="yes"
    else
      reg="no"
    fi
    secrets="$(jq -r '.secrets_required | length' "$json")"
    printf '%-20s  %-12s  %-10s  %s\n' "$name" "$reg" "$secrets" "$desc"
  done
}

if [[ $LIST -eq 1 ]]; then
  list_mode
  exit 0
fi

say "Installing MCP servers from $SERVERS_DIR"
say

for json in "$SERVERS_DIR"/*.json; do
  [[ -f "$json" ]] || continue
  install_one "$json"
done

say
say "Done. Verify with: claude mcp list"

# Remind about secrets if any tracked server needs them
for json in "$SERVERS_DIR"/*.json; do
  [[ -f "$json" ]] || continue
  if [[ "$(jq -r '.secrets_required | length' "$json")" -gt 0 ]]; then
    name="$(jq -r '.name' "$json")"
    say
    say "Note: '$name' requires the following env vars to be set before running:"
    jq -r '.secrets_required[] | "  - \(.env) (\(.description))"' "$json"
    say
    say "Put them in Monty-CNS-Secrets env.sops.yaml. They'll flow into the session"
    say "via the SessionStart hook + 10-decrypt-sops.sh drop-in."
  fi
done
