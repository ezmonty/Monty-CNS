# Self-hosting Monty-CNS

Guide for running this dotfiles repo as a private remote on your own hardware
(rack at home, VPS, whatever). Every machine — laptop, desk, work, home —
`git pull`s from your remote, then runs `./bootstrap.sh` to materialise the
symlinks under `~/.claude`.

## Quickstart (per machine)

```bash
git clone git@your-host:ezmonty/Monty-CNS.git ~/src/Monty-CNS
cd ~/src/Monty-CNS
./bootstrap.sh --dry-run     # verify what will change
./bootstrap.sh               # install symlinks
```

To update later:

```bash
cd ~/src/Monty-CNS && git pull && ./bootstrap.sh
```

To back out:

```bash
./bootstrap.sh --unlink
```

Anything previously present in `~/.claude` that conflicted with a tracked
path was moved to `~/.claude/backups/<timestamp>/` — never deleted.

## What's tracked vs. machine-local

Tracked (lives in git):
- `claude/settings.json`
- `claude/stop-hook-git-check.sh`
- `claude/agents/`, `claude/commands/`, `claude/skills/`, `claude/mcp/`
  (populate as you go)

Machine-local (gitignored, see `.gitignore`):
- `.credentials.json`, `.env*`, any keys
- `projects/`, `sessions/`, `session-env/`, `todos/`, `statsig/`,
  `shell-snapshots/`, `backups/`, `.claude.json`
- MCP runtime state (sqlite caches, node_modules, sockets)

Rule of thumb: **config, yes; state, no; secrets, never.**

## Hosting options for your rack

All of these give you a private git remote over SSH. Pick one and go.

### 1. Plain `git` over SSH (zero services)

On the server:

```bash
sudo adduser --system --shell /usr/bin/git-shell git
sudo -u git mkdir -p /srv/git/monty-cns.git
sudo -u git git init --bare /srv/git/monty-cns.git
```

Add your SSH key to `~git/.ssh/authorized_keys`. Clone with:

```bash
git clone git@your-host:/srv/git/monty-cns.git
```

Good for: a single user, minimum moving parts. No web UI, no CI.

### 2. Forgejo / Gitea (recommended)

Small, fast, self-hosted GitHub-alike. Runs fine in a single container on a
modest box:

```yaml
# docker-compose.yml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:10
    restart: unless-stopped
    ports:
      - "2222:22"    # git over ssh
      - "3000:3000"  # web UI
    volumes:
      - ./data:/data
      - /etc/localtime:/etc/localtime:ro
```

Put it behind Caddy or nginx with a Let's Encrypt cert. Create a private repo
`ezmonty/monty-cns`, push to it, add a deploy key per machine.

Good for: web UI, issues, actions, multiple users, PR review workflow.

### 3. Tailscale + any of the above

Put the git host on your tailnet and never expose ports to the public
internet. `git clone git@monty.tail-xxxx.ts.net:ezmonty/monty-cns.git`. This
is the safest option for dotfiles that brush up against credentials paths.

## SSH key hygiene

Generate one ed25519 key **per machine**, not a shared key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_monty-cns -C "$(hostname)-monty-cns"
```

Add each public key as a deploy key on the repo (or to `~git/.ssh/authorized_keys`
for the plain-git option). If you lose a laptop, you revoke just that one key.

## Keeping machines in sync

Options, in order of cost/benefit:

1. **Manual** — `git pull && ./bootstrap.sh` when you sit down at a machine.
   Honest, simple, and the stop hook (`claude/stop-hook-git-check.sh`) already
   nags you about uncommitted changes during Claude sessions.
2. **Cron / systemd timer** — pull every N minutes:
   ```
   */15 * * * * cd ~/src/Monty-CNS && git pull --ff-only --quiet && ./bootstrap.sh >/dev/null
   ```
3. **Git hook on push** — on the server, a `post-receive` hook pings each
   machine (webhook, ntfy, whatever) to pull.

## Secrets that still need to roam

Some things (API keys, OAuth tokens) legitimately need to exist on multiple
machines but can't live in git. Options:

- **`pass`** (password-store) — a second private git repo, GPG-encrypted.
  Perfect for shared secrets across your own machines.
- **`age` + `sops`** — encrypt files in this repo with your machine keys, commit
  the ciphertext. Good for structured config like `.env` files.
- **OS keychain** — macOS Keychain, `libsecret`, or 1Password CLI; reference
  values from `settings.json` / MCP JSON via env vars.

Do **not** commit plaintext `~/.claude/.credentials.json`. The `.gitignore`
already blocks it; don't undo that.
