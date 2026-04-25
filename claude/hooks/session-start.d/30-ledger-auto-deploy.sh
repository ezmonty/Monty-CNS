#!/usr/bin/env bash
# SessionStart drop-in: auto-deploy Ledger DB on valor-vm if missing.
# Runs on every session start. No-ops if:
#   - not on valor-vm (checks hostname)
#   - ledger DB already exists
#   - postgresql not running
# Idempotent. Safe to run repeatedly.

set -uo pipefail

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0

HOSTNAME="$(hostname 2>/dev/null || echo unknown)"
CNS_DIR="${HOME}/src/Monty-CNS"
DB_NAME="ledger"
DB_USER="valor"
DB_PASS="valor_pass"

log() { printf '[ledger-setup] %s\n' "$*" >&2; }

# Only run on the VM (or any machine with local Postgres + the vault)
if ! command -v psql &>/dev/null; then
  exit 0
fi

if ! sudo -u postgres psql -lqt 2>/dev/null | grep -qw "$DB_NAME"; then
  log "Ledger database not found. Setting up..."

  # Ensure CNS is cloned
  if [ ! -d "$CNS_DIR" ]; then
    log "Cloning Monty-CNS..."
    mkdir -p "$(dirname "$CNS_DIR")"
    git clone https://github.com/ezmonty/Monty-CNS.git "$CNS_DIR" 2>/dev/null || { log "Clone failed"; exit 0; }
  fi

  # Create database
  sudo -u postgres createdb "$DB_NAME" -O "$DB_USER" 2>/dev/null || { log "createdb failed"; exit 0; }
  log "Created database $DB_NAME"

  # Apply schema + views
  sudo -u postgres psql -d "$DB_NAME" -f "$CNS_DIR/monty-ledger/db/schema.sql" >/dev/null 2>&1
  sudo -u postgres psql -d "$DB_NAME" -f "$CNS_DIR/monty-ledger/db/seed.sql" >/dev/null 2>&1
  log "Schema applied"

  # Install Python deps if needed
  python3 -c "import frontmatter" 2>/dev/null || pip3 install --quiet python-frontmatter 2>/dev/null
  python3 -c "import psycopg2" 2>/dev/null || pip3 install --quiet psycopg2-binary 2>/dev/null

  # Sync vault
  LEDGER_DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}" \
    python3 "$CNS_DIR/monty-ledger/scripts/sync_to_postgres.py" "$CNS_DIR/monty-ledger/" 2>&1 | while read -r line; do log "$line"; done

  log "Ledger DB deployed successfully"
else
  log "Ledger DB already exists, skipping setup"
fi

# Always export the connection string so MCP server can use it
DB_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"
printf 'export LEDGER_DATABASE_URL="%s"\n' "$DB_URL" >> "$CLAUDE_ENV_FILE"
printf 'export LEDGER_VAULT_ROOT="%s/monty-ledger"\n' "$CNS_DIR" >> "$CLAUDE_ENV_FILE"

exit 0
