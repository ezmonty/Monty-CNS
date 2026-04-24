---
type: decision
status: active
created: 2026-04-18
tags: [decision, infrastructure, postgres, hosting]
confidence: 4
access: private
truth_layer: working
role_mode: owner
persona_mix: [owner, strategist]
origin_type: ai-assisted
review_due: 2026-06-18
---
# Decision — Infrastructure: Oracle Free Tier VM as Primary Host

## Context

We were evaluating where to run Postgres for Monty-Ledger. Options
considered: Neon.tech (serverless Postgres), Supabase, fly.io,
local Docker, and the user's existing infrastructure.

## What we already have

The user has an **Oracle Cloud Free Tier VM** running 24/7:
- 4 cores (ARM Ampere A1)
- Always-on, no idle shutdown
- This is where Monty-CNS currently runs
- Free forever (Oracle's permanent free tier, not a trial)

## Options evaluated

| Option | Cost | Pros | Cons |
|--------|------|------|------|
| **Oracle VM (existing)** | $0 | Already running, you control it, 4 cores, 24/7, Postgres can run alongside everything else | Single point of failure, no managed backups |
| Neon.tech | $0 (free tier) | Serverless, managed, auto-scaling | 500MB limit, cold starts, another vendor dependency |
| Supabase | $0 (free tier) | Managed Postgres + auth + REST | Pauses after 1 week inactive, 500MB |
| fly.io | ~$0-5/mo | Managed, global | Not free forever, needs flyctl |
| Local Docker | $0 | Full control | Not accessible from other machines |

## Chosen path

**Oracle VM.** It's already running, it's free, it's persistent,
and adding Postgres is one command:

```bash
# On the Oracle VM
sudo apt install postgresql postgresql-contrib
sudo -u postgres createdb ledger
sudo -u postgres psql -d ledger -f schema.sql
sudo -u postgres psql -d ledger -f seed.sql
```

Then set LEDGER_DATABASE_URL in sops secrets pointing to the VM's
Tailscale IP (when Tailscale is set up) or public IP with proper
auth.

## What runs on the Oracle VM

Current:
- Monty-CNS (git remote / hosting)

Planned:
- PostgreSQL 16 (Monty-Ledger vault index)
- Monty-Ledger MCP server (optional — could run locally and connect remotely)
- Future: Forgejo (when migrating off GitHub as primary)

## Future: the rack

When the self-hosted rack ships (~2 months), services migrate
from Oracle VM to rack. The Oracle VM becomes the off-site
backup / secondary. The Tailscale mesh connects both.

```
NOW:
  Oracle VM (4-core ARM) ← Postgres, git hosting
  ↕ internet
  Your machines (laptop, desk, work, home)

FUTURE:
  Rack (GPU + NAS + battery) ← primary for everything
  ↕ Tailscale mesh
  Oracle VM ← backup, off-site replica
  ↕ Tailscale mesh
  Your machines
```

## Why not Neon/Supabase

- Another account, another vendor, another thing to manage
- Free tiers have limits (500MB, cold starts, inactivity pauses)
- You already have a 24/7 VM with 4 cores doing nothing
- "Use what you have" beats "sign up for something new"
