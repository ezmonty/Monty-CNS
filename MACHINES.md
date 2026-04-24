# Machines & services

Single source of truth for machines in the fleet and the services running on
them. If you're a Claude session looking for "where do I run X" or "how do I
reach Y", check here first.

---

## `valor-vm` — Oracle Cloud A1 (Always-Free)

**Role:** 24/7 host for Valor 2.0 (full stack). Also usable as a sandbox for
tests — this is where E2E, integration, and soak tests should run because it
has the real Postgres + the full agent fleet.

| Field | Value |
|---|---|
| Public IP | **147.224.59.11** (RESERVED — permanent) |
| Region / AD | `us-sanjose-1` / AD-1 |
| OS | Ubuntu 22.04 LTS aarch64 |
| Shape | VM.Standard.A1.Flex — 4 OCPU / 24 GB RAM |
| Disk | 100 GB boot, 95 GB free |
| User | `ubuntu` (passwordless sudo) |
| SSH | `ssh valor-vm` (config entry wired; private key at `~/.ssh/valor_vm.key`) |
| Repo checkout | `/home/ubuntu/valor2.0` — **real git checkout**, remote `github.com/ezmonty/valor2.0`, branch `main`. `git pull` / `git push` work. |
| `.env` | `/home/ubuntu/valor2.0/.env` — chmod 600, **not tracked** (gitignored) |

### Services (systemd, auto-start on reboot)

| Unit | Port | Purpose |
|---|---|---|
| `valor-montycore.service` | 8090 | MontyCore API (FastAPI) — agent registry + `/ask` |
| `valor-agents.service` | 8091 | AgentLauncher — spawns the 53-agent fleet on 8100–8500+ |
| `nginx.service` | 80 | Serves the UI `dist/` + proxies `/api/console/*`→:8353 and `/health /ask /agents`→:8090, injecting the `x-api-key` header server-side |
| `postgresql.service` | 5432 | `valor_db` owned by user `valor` (pw `valor_pass` for local connections) |

### Public endpoints

- UI: http://147.224.59.11/
- Health: http://147.224.59.11/health
- Projects API (through nginx auth injection): http://147.224.59.11/api/console/projects
- Direct MontyCore (no auth injection; needs `x-api-key` header): http://147.224.59.11:8090/

### Common commands (run on the VM)

```bash
# tail logs
journalctl -fu valor-montycore
journalctl -fu valor-agents
tail -f ~/valor2.0/logs/*.log

# restart after code change
sudo systemctl restart valor-montycore valor-agents

# pull latest, rebuild frontend, restart
cd ~/valor2.0 && git pull && \
  source .venv/bin/activate && \
  pip install -q -r requirements.txt && \
  (cd ui/construction-console && npm ci --silent && npm run build) && \
  sudo systemctl restart valor-montycore valor-agents && \
  sudo systemctl reload nginx

# run tests
cd ~/valor2.0 && source .venv/bin/activate && pytest tests/smoke_*.py

# check all service health
sudo systemctl is-active valor-montycore valor-agents nginx postgresql
curl -s http://localhost/health
```

### Deploying from a remote Claude (workflow)

From any machine where `ssh valor-vm` works:

```bash
ssh valor-vm
cd ~/valor2.0
git checkout -b my-branch
# ... edit ...
git push origin my-branch        # opens PR via gh if you want
sudo systemctl restart valor-montycore valor-agents    # to test locally on VM
```

Or push from your laptop and pull on the VM:

```bash
# laptop
cd ~/src/valor2.0 && git push

# VM
ssh valor-vm 'cd ~/valor2.0 && git pull && sudo systemctl restart valor-montycore valor-agents'
```

---

## Oracle Cloud Shell — `bcdusa_llc`

Not a real machine; an ephemeral managed container in the OCI console. Useful
as an `oci`-authenticated launchpad (delegation token, no setup needed), but
**don't** install long-running services here — it sleeps after ~20 min idle
and wipes after ~6 months of no use.

- `$HOME` persists (~5 GB, 6-month TTL)
- No `sudo`, no `systemd`
- `oci` CLI pre-authed as the logged-in user (can manage compute, IPs, DBs, storage, VCNs)
- `gh` installed userland at `~/.local/bin/gh`, web-authenticated

---

## Adding a new machine to the fleet

Any machine running Claude Code can become a full recipient of CNS + CNS-Secrets
(getting the `valor-vm` SSH key and all env vars) in ~60 seconds.

```bash
# on the NEW machine
git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS
cd ~/src/Monty-CNS && ./install.sh           # symlinks, hooks, skills
./rekey-new-machine.sh                        # generates age key, prints pubkey + command to run elsewhere

# on a CURRENT recipient (e.g. Work laptop)
cd ~/src/Monty-CNS && git pull
./rekey-add-recipient.sh <pubkey> <label>     # re-encrypts vault, commits, pushes

# back on the NEW machine
./rekey-new-machine.sh --finish               # pulls secrets, verifies decryption
```

From then on, every Claude Code session on the new machine has the VM SSH
key + all shared env vars auto-loaded via the SessionStart hook.

---

## Known security debt

- **Rotate pending (2026-04-24):** Groq / Anthropic / GitHub PAT keys were
  pasted into a Claude conversation transcript — treat as exposed.
- **Leaked keys in git history:**
  - `ezmonty/valor2.0` — `ssh-key-2026-04-19 (7).key` (stale, unused)
  - `ezmonty/Monty-CNS-Secrets` — `ssh-key-2026-04-19 (6).key`
  - Both need `git filter-repo` + force-push to excise.
- **VM git remote has PAT embedded** in `/home/ubuntu/valor2.0/.git/config`.
  Fine-ish (VM is access-controlled), but swap to `gh auth` credential
  helper when convenient.
