# Monty-CNS-Secrets

Private companion repo to [Monty-CNS](https://github.com/ezmonty/Monty-CNS).
Holds **encrypted** secrets (API keys, OAuth tokens, MCP server env values)
that the CNS dotfiles pull in at session start.

> **Private, always.** This repo must be private even though everything in
> it is encrypted at rest. Defense in depth: if an `age` private key is ever
> compromised, a private repo is one more door the attacker needs.

## How it fits with Monty-CNS

```
Monty-CNS                      Monty-CNS-Secrets (this repo)
    │                                    │
    │  claude/hooks/session-start.sh     │  env.sops.yaml  (encrypted)
    │    └─ runs each session-start.d/   │  mcp/*.sops.*   (encrypted)
    │       drop-in                      │  .sops.yaml     (recipient list)
    │                                    │
    └─> 10-decrypt-sops.sh ──pull──> this repo
            │
            └─ sops -d env.sops.yaml
                    │
                    ├─> $CLAUDE_ENV_FILE (env vars for this session)
                    └─> ~/.claude/mcp/keys/ (file-based secrets, 0600)
```

## One-time setup (per machine)

Copy this block into a fresh shell on the machine:

```bash
# 1. Install tools (per-OS — examples)
brew install sops age                    # macOS
# or: sudo apt install age age-keygen && curl -LO https://github.com/getsops/sops/releases/latest/download/sops-v3.8.1.linux.amd64 && sudo install sops-v3.8.1.linux.amd64 /usr/local/bin/sops

# 2. Generate this machine's age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Note the public key — you'll paste it into .sops.yaml in a moment
grep '^# public key:' ~/.config/sops/age/keys.txt

# 4. Clone this repo
mkdir -p ~/src
git clone git@github.com:ezmonty/Monty-CNS-Secrets.git ~/src/Monty-CNS-Secrets
cd ~/src/Monty-CNS-Secrets

# 5. Add this machine as a recipient in .sops.yaml
#    (edit the file — append your age1... public key to the age: list)
$EDITOR .sops.yaml

# 6. Re-key every encrypted file for the new recipient
sops updatekeys env.sops.yaml
# repeat for each file in mcp/ if any

# 7. Commit + push
git commit -am "add $(hostname) as sops recipient"
git push
```

That's it — the next time you start a Claude Code session on this machine,
the CNS `10-decrypt-sops.sh` drop-in decrypts `env.sops.yaml` and injects
every variable into `$CLAUDE_ENV_FILE`.

## Adding / editing secrets

```bash
cd ~/src/Monty-CNS-Secrets

# Edit the env bundle — opens your $EDITOR with plaintext, re-encrypts on save
sops env.sops.yaml

# Add a file-based secret (e.g. an MCP server key file)
sops mcp/my-service.sops.key

# Commit + push
git commit -am "rotate my-service key"
git push
```

Every machine picks up the new value on the next session start.

## Adding / removing machines

**Add:** the new machine runs the one-time setup above. After step 5 appends
its public key and step 6 re-keys the files, any machine can commit + push.

**Remove (machine compromised):**

```bash
# Remove the line for the compromised machine from .sops.yaml
$EDITOR .sops.yaml

# Re-key every encrypted file — this re-encrypts without the old recipient
sops updatekeys env.sops.yaml
# repeat for each encrypted file

# Rotate the actual secret values too (the compromised key could have read the old ones)
sops env.sops.yaml   # replace values
git commit -am "rotate secrets after <hostname> compromise"
git push
```

Then rotate the upstream API keys / tokens with their providers.

## Layout

```
Monty-CNS-Secrets/
├── .sops.yaml          # recipient list (who can decrypt what)
├── .gitignore          # blocks any plaintext from sneaking in
├── README.md           # you are here
├── env.sops.yaml       # flat map of env vars for Claude + MCP
└── mcp/                # optional — file-based secrets per MCP server
    ├── .gitkeep
    └── <name>.sops.<ext>
```

## Safety

- **Never commit plaintext.** The `.gitignore` blocks common mistake files
  (`.env`, `*.key`, `*.pem`, `credentials.*`, `secrets.*`). If you ever
  `sops -d` to a temp file, delete it immediately — do not commit it.
- **Never share your age private key.** Each machine generates its own.
- **Keep a recovery key offline.** Generate one extra age key, add it as a
  recipient, and store the private half somewhere safe (USB, printed, safe
  deposit box). If all your machines are lost at once, this gets you back in.
- **Audit the history periodically** — `git log --all --full-history --source`
  to confirm no plaintext ever leaked.

## Troubleshooting

**"failed to decrypt" on a new machine**
→ The file wasn't re-keyed for that machine. Run `sops updatekeys <file>`
on a machine that already had access.

**Drop-in says "sops not installed, skipping"**
→ Install sops and age, then start a new session.

**Drop-in says "$SECRETS_REPO not cloned"**
→ Clone this repo to `~/src/Monty-CNS-Secrets` (or set `$SECRETS_REPO`).

**Values aren't showing up in the Claude session**
→ Check `~/.claude/logs/session-start.log` for errors. The drop-in logs
each step.
