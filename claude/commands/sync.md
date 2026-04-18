---
description: Sync Monty-Ledger vault markdown files to Postgres.
---

# /sync — Vault-to-Postgres sync

## Steps

1. **Detect vault location:**
   Check `$PWD/monty-ledger/` first, then `~/src/Monty-Ledger/`. Use whichever exists.
   If neither exists, report "No vault found" and stop.

2. **Check prerequisites:**
   If `LEDGER_DATABASE_URL` is not set, warn:
   > "LEDGER_DATABASE_URL is not set. Run `./activate-secrets.sh` or check your sops secrets."
   Stop.

3. **Run sync:**
   ```bash
   python3 <vault>/scripts/sync_to_postgres.py <vault>/
   ```

4. **Report results:**
   Parse output for synced/skipped/error counts and display a summary line.
   If the script exits non-zero, show the error output.
