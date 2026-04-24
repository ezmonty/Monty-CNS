---
name: fleet-access
description: How to connect to and execute commands on fleet machines. Teaches Claude about SSH access, MontyCore HTTP fallback, and the MACHINES.md registry.
---

# Fleet Access

## When this applies

Any time you need to:
- Run a command on a remote machine (deploy, test, query DB, check logs)
- Interact with Postgres on the VM
- Restart services or check health
- Execute the Ledger DB deployment plan or similar

## How to connect

### Primary: SSH (terminal sessions)

On any CNS-installed machine, `ssh valor-vm` is pre-configured.
The SSH key comes from sops-decrypted secrets at session start.

```bash
ssh valor-vm 'command here'
```

For multi-line:
```bash
ssh valor-vm << 'REMOTE'
cd ~/valor2.0
git pull
sudo systemctl restart valor-montycore
REMOTE
```

### Fallback: MontyCore HTTP API (web sessions)

If SSH is unavailable (web sandbox, no key), the VM runs MontyCore
on port 8090 with a public HTTP endpoint:

```bash
curl -s -X POST http://147.224.59.11:8090/ask \
  -H "Content-Type: application/json" \
  -d '{"command":"shell","data":{"cmd":"hostname"}}'
```

Note: MontyCore may not have a shell command handler. If not,
this fallback is informational only — print the command for the
user to run manually.

### Last resort: print the command

If neither SSH nor HTTP reaches the VM, print:
"I can't reach valor-vm from this session. Run this manually:"

## Fleet registry

**Always check MACHINES.md first.** It has:
- Hostnames, IPs, SSH config names
- Services, ports, systemd units
- Deploy workflows, common commands
- Security notes

Location: `~/src/Monty-CNS/MACHINES.md` or repo root `MACHINES.md`

## Database access

The VM has Postgres on port 5432:
- `valor_db` — Valor's production database (user: valor, pw: valor_pass)
- `ledger` — Monty-Ledger vault index (same user, created by deployment plan)

```bash
ssh valor-vm 'sudo -u postgres psql -d ledger -c "SELECT count(*) FROM notes;"'
```

## Safety

- Never run destructive commands without user confirmation
- Never embed passwords in commands (they're in sops secrets)
- Prefer read-only DB queries unless explicitly asked for writes
- Check `sudo systemctl is-active` before restarting services
