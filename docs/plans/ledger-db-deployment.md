# Ledger Database Deployment Plan

**For:** A Claude Code agent running on a terminal with SSH access to `valor-vm`
**Goal:** Get Monty-Ledger's Postgres database live on the Oracle VM, wire it
into sops secrets, and verify the full stack works end-to-end.

**Prerequisites the agent MUST verify before starting:**
- `ssh valor-vm` works (test with `ssh valor-vm 'hostname'`)
- sops + age are installed locally (`command -v sops && command -v age`)
- `~/src/Monty-CNS-Secrets` exists and is decryptable
- `~/src/Monty-CNS` is cloned and on `main`

---

## Phase 1: Deploy Ledger Database on VM (parallel-safe)

Run these on the VM via SSH. All are idempotent — safe to re-run.

### 1A. Clone CNS on the VM (if not already there)
```bash
ssh valor-vm '
  if [ ! -d ~/src/Monty-CNS ]; then
    mkdir -p ~/src
    git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS
  else
    cd ~/src/Monty-CNS && git pull --quiet
  fi
  echo "CNS at $(git -C ~/src/Monty-CNS rev-parse --short HEAD)"
'
```

### 1B. Create the ledger database
```bash
ssh valor-vm '
  if sudo -u postgres psql -lqt | grep -qw ledger; then
    echo "Database ledger already exists"
  else
    sudo -u postgres createdb ledger -O valor
    echo "Created database ledger"
  fi
'
```

### 1C. Apply schema + views
```bash
ssh valor-vm '
  sudo -u postgres psql -d ledger -f ~/src/Monty-CNS/monty-ledger/db/schema.sql
  sudo -u postgres psql -d ledger -f ~/src/Monty-CNS/monty-ledger/db/seed.sql
'
```

### 1D. Install Python deps
```bash
ssh valor-vm '
  python3 -c "import frontmatter" 2>/dev/null || pip3 install --quiet python-frontmatter
  python3 -c "import psycopg2" 2>/dev/null || pip3 install --quiet psycopg2-binary
  echo "Python deps OK"
'
```

### 1E. Sync vault to Postgres
```bash
ssh valor-vm '
  LEDGER_DATABASE_URL="postgresql://valor:valor_pass@localhost:5432/ledger" \
    python3 ~/src/Monty-CNS/monty-ledger/scripts/sync_to_postgres.py ~/src/Monty-CNS/monty-ledger/
'
```
**Expected output:** `Synced NN notes, skipped 0, total NN files`

### 1F. Configure Postgres for remote connections
The VM's Postgres currently only accepts local connections. To allow
Claude Code sessions on other machines to query via the MCP server:

```bash
ssh valor-vm '
  PG_HBA="/etc/postgresql/*/main/pg_hba.conf"
  PG_CONF="/etc/postgresql/*/main/postgresql.conf"

  # Allow password auth from any IP (the VM firewall + OCI security list restrict actual access)
  if ! grep -q "host.*all.*all.*0.0.0.0/0" $PG_HBA 2>/dev/null; then
    echo "host all all 0.0.0.0/0 scram-sha-256" | sudo tee -a $PG_HBA
    echo "Added remote auth rule"
  fi

  # Listen on all interfaces (not just localhost)
  if ! grep -q "listen_addresses.*\*" $PG_CONF 2>/dev/null; then
    sudo sed -i "s/#listen_addresses = .*/listen_addresses = '\*'/" $PG_CONF
    echo "Set listen_addresses = *"
  fi

  sudo systemctl reload postgresql
  echo "Postgres reloaded"
'
```

### 1G. Open OCI firewall for port 5432
The Oracle Cloud security list must allow TCP 5432 inbound.
Check if already open:

```bash
ssh valor-vm 'sudo iptables -L -n | grep 5432 || echo "No iptables rule for 5432"'
```

If not open, add the iptables rule on the VM:
```bash
ssh valor-vm 'sudo iptables -I INPUT -p tcp --dport 5432 -j ACCEPT'
```

**NOTE:** The OCI VCN Security List also needs a rule allowing
TCP 5432 from 0.0.0.0/0 (or your specific IPs). This must be
done in the OCI console or via `oci` CLI:
```bash
# Run from Oracle Cloud Shell or any machine with oci CLI configured
# The agent should check if this rule already exists first
oci network security-list update \
  --security-list-id <OCID> \
  --ingress-security-rules '[... existing rules + new TCP 5432 rule ...]'
```
If the agent cannot access OCI CLI, flag this as a manual step for the user.

---

## Phase 2: Wire into Sops Secrets (on local machine)

### 2A. Add LEDGER_DATABASE_URL to sops secrets
```bash
cd ~/src/Monty-CNS-Secrets

# Edit the encrypted env file
sops env.sops.yaml

# Add this line:
# LEDGER_DATABASE_URL: "postgresql://valor:valor_pass@147.224.59.11:5432/ledger"

# Save and exit. sops re-encrypts automatically.
```

### 2B. Verify decrypt works
```bash
sops -d env.sops.yaml | grep LEDGER_DATABASE_URL
```
**Expected:** the connection string in plaintext.

### 2C. Commit and push secrets
```bash
cd ~/src/Monty-CNS-Secrets
git add env.sops.yaml
git commit -m "feat: add LEDGER_DATABASE_URL for Monty-Ledger vault"
git push
```

---

## Phase 3: Verify End-to-End (on local machine)

### 3A. Start a fresh Claude Code session
The SessionStart hook should:
1. Pull CNS repo
2. Decrypt sops secrets (including LEDGER_DATABASE_URL)
3. Load LEDGER_DATABASE_URL into $CLAUDE_ENV_FILE
4. The 20-vault-context.sh drop-in sets VAULT_ROOT

### 3B. Test the MCP server locally
```bash
cd ~/src/Monty-CNS/monty-ledger/mcp-server
npm install  # first time only

# Test the initialize handshake
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}\n' \
  | npx tsx src/index.ts 2>/dev/null
```
**Expected:** JSON response with `"name":"monty-ledger"`.

### 3C. Test a real query
```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}\n{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list_profiles","arguments":{}}}\n' \
  | npx tsx src/index.ts 2>/dev/null | tail -1 | python3 -m json.tool | head -20
```
**Expected:** JSON array with ~10 profile notes.

### 3D. Test /learn end-to-end
In a Claude Code session, run:
```
/learn "Ledger database is live on the Oracle VM"
```
**Expected:** Note created in vault inbox + Postgres row.

### 3E. Verify on the VM
```bash
ssh valor-vm 'sudo -u postgres psql -d ledger -c "SELECT path, type, origin_type FROM notes WHERE path LIKE '\''00_Inbox/%'\'' ORDER BY created_at DESC LIMIT 5;"'
```
**Expected:** The /learn note appears with origin_type=ai-proposed.

---

## Phase 4: Register the MCP Server (on local machine)

### 4A. Install the MCP server with Claude Code
```bash
claude mcp add ledger \
  --command npx \
  --args tsx "$(echo ~/src/Monty-CNS/monty-ledger/mcp-server/src/index.ts)" \
  --env LEDGER_DATABASE_URL="$(sops -d ~/src/Monty-CNS-Secrets/env.sops.yaml | grep LEDGER_DATABASE_URL | cut -d: -f2- | tr -d ' "')" \
  --env LEDGER_VAULT_ROOT="$(echo ~/src/Monty-CNS/monty-ledger)"
```

Or use the install-servers.sh script which reads ledger.json:
```bash
~/.claude/mcp/install-servers.sh
```

### 4B. Verify MCP registration
```bash
claude mcp list | grep ledger
```
**Expected:** ledger server listed.

---

## Verification Checklist

Run after all phases. Every line must pass.

```bash
echo "=== VM checks ==="
ssh valor-vm 'sudo -u postgres psql -d ledger -t -c "SELECT count(*) FROM notes;"'
# Expected: 90+ notes

ssh valor-vm 'sudo -u postgres psql -d ledger -t -c "SELECT count(*) FROM tags;"'
# Expected: 60+ tags

ssh valor-vm 'sudo systemctl is-active postgresql'
# Expected: active

echo "=== Local checks ==="
sops -d ~/src/Monty-CNS-Secrets/env.sops.yaml | grep -c LEDGER_DATABASE_URL
# Expected: 1

echo "=== Remote Postgres connectivity ==="
psql "postgresql://valor:valor_pass@147.224.59.11:5432/ledger" -c "SELECT 1;"
# Expected: 1 (if firewall is open)
# If this fails: OCI security list needs TCP 5432 rule

echo "=== MCP server ==="
claude mcp list 2>/dev/null | grep -c ledger
# Expected: 1
```

---

## Rollback

If anything goes wrong:

```bash
# Drop the database (no data loss — markdown files are the source of truth)
ssh valor-vm 'sudo -u postgres dropdb ledger'

# Remove from sops
cd ~/src/Monty-CNS-Secrets && sops env.sops.yaml
# Delete the LEDGER_DATABASE_URL line, save

# Unregister MCP
claude mcp remove ledger
```

---

## What This Unlocks

After this plan completes:
- /learn, /vault, /brief, /foreman, /research all query live Postgres
- Knowledge persists across sessions and machines
- Valor agents can query the same database (Phase 4 of Ledger plan)
- The MCP server's 7 tools are fully operational
- Every machine with sops access gets vault queries automatically

## Security Notes

- The connection string contains a password (valor_pass). It's stored
  encrypted in sops, never in plaintext in git.
- Remote Postgres access should be restricted by OCI security list
  to known IPs (your machines), not 0.0.0.0/0 in production.
- Consider Tailscale for private network access when the rack ships.
- The LEDGER_ACCESS_CEILING env var defaults to "private" — agents
  can't read secret/hidden notes without explicit elevation.
