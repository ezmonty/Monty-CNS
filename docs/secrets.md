# Secrets: how they ride alongside Monty-CNS

> **Looking for the step-by-step install?** This doc is the **"why"** —
> rationale, backend comparison, and recommendation. The **"how"** is in
> [`docs/secrets-setup.md`](secrets-setup.md): install sops + age, generate
> machine keys, seed `Monty-CNS-Secrets` from the scaffold, add more machines,
> rotate, troubleshoot.

Short version: this repo carries **config**. A second private repo carries
**secrets** (encrypted). The `SessionStart` hook in `claude/hooks/session-start.sh`
is the glue that pulls both and lands the decrypted values where they need
to be at the start of every Claude Code session.

## Why two repos

- **Monty-CNS** (this repo) — public-ish-safe. `settings.json`, hooks,
  agent definitions, MCP server *structure*. If someone reads the commit log
  nothing leaks.
- **Monty-CNS-secrets** (separate private repo) — encrypted blobs only.
  API keys, OAuth tokens, MCP server env values, anything that would be a
  problem to leak. Encrypted at rest even inside your self-hosted git.

Two repos, not one, because:
1. You can share read access to dotfiles (e.g. with a collaborator or a CI
   runner) without granting access to secrets.
2. Encryption recipients change far less often than config — separating
   them keeps diffs clean.
3. If you ever publish Monty-CNS, nothing has to be scrubbed.

## How the two repos talk

Two paths exist at the same time:

**a) Env vars** (most secrets — API keys, tokens):
```
Monty-CNS-secrets/env.sops.yaml   (encrypted)
        │  decrypt via drop-in
        ▼
$CLAUDE_ENV_FILE                  (per-session, set by Claude Code)
        │  inherited by
        ▼
Claude Code + MCP server subprocesses
```
The drop-in script `~/.claude/hooks/session-start.d/10-decrypt-sops.sh`
runs after `bootstrap.sh`, decrypts, and appends `export FOO=bar` lines to
`$CLAUDE_ENV_FILE`. Anything spawned by Claude Code from that session on
sees the vars.

**b) Files** (things that must be a literal file at a literal path):
```
Monty-CNS-secrets/mcp/github-app.key.age   (encrypted)
        │  decrypt via drop-in
        ▼
~/.claude/mcp/keys/github-app.key          (gitignored, 0600)
```
The MCP server config references the plaintext path. The file never leaves
the machine and never enters git.

Do NOT try to sync `~/.claude/.credentials.json` (Claude Code's OAuth). It's
machine-scoped and short-lived — log in once per machine.

## Recommended tool: `sops` + `age`

Why `age` over GPG: simpler key format, no keyring rituals, good fit for
one-box self-hosting.

### One-time setup, per machine

```bash
# 1. Install (pick your package manager).
brew install sops age          # macOS
sudo apt install age && ...    # debian: sops from github release

# 2. Generate this machine's age key.
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Grab the public key and add it as a recipient in the secrets repo.
grep '^# public key:' ~/.config/sops/age/keys.txt
```

### One-time setup, in Monty-CNS-secrets

`.sops.yaml` at the repo root:

```yaml
creation_rules:
  - path_regex: \.sops\.ya?ml$
    age: >-
      age1laptop...,
      age1desk...,
      age1work...,
      age1home...
```

Then the first secret:

```bash
sops env.sops.yaml
# editor opens; write:
# ANTHROPIC_API_KEY: sk-ant-...
# GITHUB_MCP_TOKEN: ghp_...
```

Committing `env.sops.yaml` ships ciphertext only. Adding a new machine =
add its public key to `.sops.yaml`, run `sops updatekeys env.sops.yaml`,
commit, done.

### Wiring into Claude Code

Create `~/.claude/hooks/session-start.d/10-decrypt-sops.sh` on each machine
(see `claude/hooks/session-start.d/README.md` for the exact script). That's
the only glue. From that point:

- Edit a secret: `sops ~/src/Monty-CNS-secrets/env.sops.yaml`, commit, push.
- Pick it up on another machine: start a new Claude Code session. The hook
  pulls + decrypts automatically.

## Alternative: `pass` (password-store)

If you already live in `pass`, skip sops entirely:

- `pass` stores each secret as its own GPG-encrypted file in a private git
  repo.
- The `10-load-pass.sh` drop-in reads the entries you care about and
  appends them to `$CLAUDE_ENV_FILE`.
- Pro: dead simple if `pass` is already set up. Con: GPG key management is
  worse than `age`, and one secret per file.

## Alternative: OS keychain

macOS Keychain / libsecret / 1Password CLI. Best if you already depend on
one. The drop-in becomes a shell of `security find-generic-password …` or
`op read op://…` calls that write to `$CLAUDE_ENV_FILE`. No second repo
needed at all, but secrets don't sync via git — you enter them once per
machine.

## Decision grid

| You want…                                   | Use           |
|---------------------------------------------|---------------|
| Secrets synced via your rack's git, simple  | sops + age    |
| Already using `pass`                         | pass          |
| Already using 1Password / Bitwarden         | OS keychain   |
| Minimum setup, single machine               | `.env.local`  |

For a single-machine start, you can skip all of the above and hand-write
`~/.claude/.env.local`:

```
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_MCP_TOKEN=ghp_...
```

The `session-start.sh` hook loads it on its own. When you add a second
machine, graduate to sops.

## Safety checklist

- [ ] `~/.claude/.env.local` is gitignored (it is, in this repo).
- [ ] `~/.claude/.credentials.json` is gitignored (it is).
- [ ] Each machine has its own age key / SSH key. Never share private keys.
- [ ] Secrets repo is private and on your tailnet (or behind SSH-only).
- [ ] Git history for secrets only ever holds ciphertext — use `git-secrets`
      or a pre-commit hook if you're worried about mistakes.
