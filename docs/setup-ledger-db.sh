#!/usr/bin/env bash
# setup-ledger-db.sh — Run this ONCE on the Oracle VM to set up
# the Monty-Ledger Postgres database alongside valor_db.
#
# Usage: ssh valor-vm 'bash -s' < docs/setup-ledger-db.sh
#    OR: ssh valor-vm, then: bash ~/src/Monty-CNS/docs/setup-ledger-db.sh

set -euo pipefail

CNS_DIR="${HOME}/src/Monty-CNS"
DB_NAME="ledger"
DB_USER="valor"

echo "=== Setting up Monty-Ledger database ==="

# 1. Ensure CNS repo is cloned
if [ ! -d "$CNS_DIR" ]; then
  echo "Cloning Monty-CNS..."
  git clone https://github.com/ezmonty/Monty-CNS.git "$CNS_DIR"
else
  echo "Monty-CNS already at $CNS_DIR"
  (cd "$CNS_DIR" && git pull --quiet)
fi

# 2. Create the database (skip if exists)
if sudo -u postgres psql -lqt | grep -qw "$DB_NAME"; then
  echo "Database '$DB_NAME' already exists"
else
  echo "Creating database '$DB_NAME'..."
  sudo -u postgres createdb "$DB_NAME" -O "$DB_USER"
fi

# 3. Apply schema + views
echo "Applying schema..."
sudo -u postgres psql -d "$DB_NAME" -f "$CNS_DIR/monty-ledger/db/schema.sql"
echo "Applying views..."
sudo -u postgres psql -d "$DB_NAME" -f "$CNS_DIR/monty-ledger/db/seed.sql"

# 4. Install Python deps if needed
if ! python3 -c "import frontmatter" 2>/dev/null; then
  echo "Installing python-frontmatter..."
  pip3 install --quiet python-frontmatter psycopg2-binary
fi

# 5. Sync vault to Postgres
echo "Syncing vault to Postgres..."
LEDGER_DATABASE_URL="postgresql://${DB_USER}:valor_pass@localhost:5432/${DB_NAME}" \
  python3 "$CNS_DIR/monty-ledger/scripts/sync_to_postgres.py" "$CNS_DIR/monty-ledger/"

# 6. Verify
echo ""
echo "=== Verification ==="
sudo -u postgres psql -d "$DB_NAME" -c "
  SELECT 'notes' AS table_name, count(*) FROM notes
  UNION ALL SELECT 'tags', count(*) FROM tags
  UNION ALL SELECT 'links', count(*) FROM links;
"

echo ""
echo "=== Connection string for sops secrets ==="
echo "LEDGER_DATABASE_URL=postgresql://${DB_USER}:valor_pass@147.224.59.11:5432/${DB_NAME}"
echo ""
echo "Done. Add that connection string to your sops-encrypted env.sops.yaml."
