# Secrets setup — sops + age walkthrough

Step-by-step for wiring `Monty-CNS-Secrets` into `Monty-CNS` on each of
your machines. First-time setup takes ~5 minutes per machine after the
first one.

If you haven't decided on a secrets backend yet, read `docs/secrets.md`
first for the rationale. This doc is the execution guide for the
**recommended** path (sops + age).

## Prerequisites

- `Monty-CNS` cloned and `bootstrap.sh` run at least once on the target
  machine.
- The private `Monty-CNS-Secrets` repo created and **confirmed private**
  on your git host.
- Push access to both repos from this machine.

## First machine: seed the secrets repo

Do this **once** on whichever machine you're most comfortable with.

### 1. Install `sops` and `age`

```bash
# macOS
brew install sops age

# Debian/Ubuntu
sudo apt install age
curl -LO https://github.com/getsops/sops/releases/latest/download/sops-v3.8.1.linux.amd64
sudo install sops-v3.8.1.linux.amd64 /usr/local/bin/sops
rm sops-v3.8.1.linux.amd64

# Arch
sudo pacman -S sops age

# Fedora
sudo dnf install sops age

# Verify
sops --version
age --version
```

### 2. Generate this machine's age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Print the public key — you'll paste it into .sops.yaml in a moment
grep '^# public key:' ~/.config/sops/age/keys.txt
# → # public key: age1abc...xyz
```

**Save that `age1...` line.** It's the public half of the machine's key.
The private half stays at `~/.config/sops/age/keys.txt` and never leaves
this box.

### 3. Seed `Monty-CNS-Secrets` from the scaffold

Monty-CNS ships a ready-to-push scaffold at `scaffold/secrets-repo/`. Copy
it into your private repo:

```bash
# Clone the (empty) private secrets repo
mkdir -p ~/src
git clone git@github.com:ezmonty/Monty-CNS-Secrets.git ~/src/Monty-CNS-Secrets
cd ~/src/Monty-CNS-Secrets

# Copy the scaffold files from Monty-CNS
cp -r ~/src/Monty-CNS/scaffold/secrets-repo/. .

# Quick sanity: the .sops.yaml is a template with placeholder keys
cat .sops.yaml
```

### 4. Replace the placeholder recipients with your real public key

Open `.sops.yaml` and **delete the `age1REPLACE_ME_...` placeholder lines**.
Replace them with the public key from step 2. For now, this is the only
recipient — we'll add more machines later.

```yaml
creation_rules:
  - path_regex: '\.sops\.(ya?ml|json|env|toml|ini)$'
    age: >-
      age1abc...xyz   # laptop (or whatever hostname)

  - path_regex: '\.sops\.[a-zA-Z0-9]+$'
    age: >-
      age1abc...xyz
```

You can add a trailing comment with the hostname to keep track of which
key is which.

### 5. Create the first encrypted env bundle

```bash
# Option A: start from the example
mv env.sops.yaml.example env.sops.yaml
sops -e -i env.sops.yaml  # encrypts in place with the recipients in .sops.yaml

# Option B: start empty, let sops create it interactively
rm env.sops.yaml.example  # don't need the example
sops env.sops.yaml         # opens $EDITOR; save to create the encrypted file
```

Either way, verify the file is now encrypted:

```bash
cat env.sops.yaml  # should show ENC[AES256_GCM,...] gibberish, not plaintext
```

### 6. Commit + push

```bash
git add .
git commit -m "seed secrets repo with laptop as first recipient"
git push -u origin main
```

### 7. Start a new Claude Code session to test the decrypt loop

The CNS `SessionStart` hook will run `10-decrypt-sops.sh`, which pulls
the secrets repo, decrypts `env.sops.yaml`, and appends the values to
`$CLAUDE_ENV_FILE`. Check the log:

```bash
tail -30 ~/.claude/logs/session-start.log
```

You should see lines like:

```
[decrypt-sops] loaded env.sops.yaml into CLAUDE_ENV_FILE
```

Inside the session, env vars from the bundle are now available to any
MCP subprocess Claude Code spawns. Verify with:

```bash
# From inside Claude Code, run:
env | grep -E 'ANTHROPIC|GITHUB_MCP|BRAVE'
```

If the vars are missing, check the log for errors.

## Subsequent machines: add as a recipient

Each additional machine takes ~3 minutes.

### 1. Install sops + age (same as step 1 above)

### 2. Generate a new machine-local age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
grep '^# public key:' ~/.config/sops/age/keys.txt
# → copy this age1... public key
```

### 3. Add the new public key on a machine that already has access

This is the key insight: you can't add the recipient *from* the new
machine (it can't decrypt yet). Do it from one of the already-working
boxes (the seed machine from the first-machine setup).

On the **existing** machine:

```bash
cd ~/src/Monty-CNS-Secrets

# Edit .sops.yaml — append the new public key to every age: list
$EDITOR .sops.yaml

# Re-key every encrypted file with the updated recipient list
sops updatekeys env.sops.yaml
# repeat for any files in mcp/:
for f in mcp/*.sops.*; do [ -f "$f" ] && sops updatekeys "$f"; done

git commit -am "add <new-hostname> as sops recipient"
git push
```

### 4. On the new machine: clone, pull, verify

```bash
mkdir -p ~/src
git clone git@github.com:ezmonty/Monty-CNS-Secrets.git ~/src/Monty-CNS-Secrets

# Test the decrypt manually (doesn't require a Claude session)
cd ~/src/Monty-CNS-Secrets
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops -d env.sops.yaml
# → should print the plaintext YAML map
```

### 5. Start a Claude Code session and check the log

Same as step 7 in the first-machine setup.

## Adding / editing a secret

From any machine with access:

```bash
cd ~/src/Monty-CNS-Secrets
sops env.sops.yaml        # opens $EDITOR with plaintext; save re-encrypts
git commit -am "add STRIPE_API_KEY"
git push
```

Next session on any machine picks it up via the SessionStart hook.

## Adding a file-based secret (MCP server key)

Some MCP servers need an actual file at a specific path (e.g. a service
account JSON). Put it under `mcp/`:

```bash
cd ~/src/Monty-CNS-Secrets

# Create/edit the file via sops
sops mcp/github-app.sops.pem
# ... paste the private key, save ...

git commit -am "add github-app private key"
git push
```

The `10-decrypt-sops.sh` drop-in decrypts anything matching
`mcp/*.sops.*` into `~/.claude/mcp/keys/` with 0600 perms on each session
start. Reference the decrypted path from your MCP server config:

```json
{
  "github-app": {
    "command": "...",
    "env": {
      "GITHUB_APP_KEY_PATH": "~/.claude/mcp/keys/github-app.pem"
    }
  }
}
```

Note the decrypted name: `<name>.sops.<ext>` → `<name>.<ext>`.

## Rotating a compromised machine

If a machine is lost / stolen / compromised:

```bash
cd ~/src/Monty-CNS-Secrets

# 1. Remove the compromised machine's line from .sops.yaml
$EDITOR .sops.yaml

# 2. Re-key every encrypted file (re-encrypts without the old recipient)
sops updatekeys env.sops.yaml
for f in mcp/*.sops.*; do [ -f "$f" ] && sops updatekeys "$f"; done

# 3. Rotate the upstream secrets — the old key has already seen them,
#    so a lost laptop = those values are effectively public now.
sops env.sops.yaml
# ... replace every value with a freshly-rotated one ...

git commit -am "rotate secrets + remove <hostname> after loss"
git push

# 4. Also rotate the upstream tokens with their providers
#    (Anthropic dashboard, GitHub settings, etc.)
```

## Troubleshooting

### `failed to decrypt` / `no age key found`

The file wasn't re-keyed for this machine. Run `sops updatekeys env.sops.yaml`
on a machine that already has access.

### Drop-in logs `sops not installed, skipping`

Install `sops` and `age`, start a new session.

### Drop-in logs `$SECRETS_REPO not cloned`

Clone the secrets repo to `~/src/Monty-CNS-Secrets`, or set the
`$SECRETS_REPO` env var to wherever you cloned it.

### Decrypted values aren't showing up in the session

1. Check `~/.claude/logs/session-start.log` — the drop-in logs each step.
2. Confirm `$CLAUDE_ENV_FILE` is being set (should be by Claude Code on
   session start).
3. Try the drop-in manually:
   ```bash
   export CLAUDE_ENV_FILE=/tmp/fake-env
   ~/.claude/hooks/session-start.d/10-decrypt-sops.sh
   cat /tmp/fake-env
   ```

### I can't remember who has access

```bash
cd ~/src/Monty-CNS-Secrets
# Decrypt just to inspect the recipient list
sops -d env.sops.yaml > /dev/null  # confirms you have access
# View the encrypted file metadata (at the bottom of the YAML)
tail -20 env.sops.yaml
```

The `recipients:` list at the bottom of every encrypted file records
every public key that can decrypt it.

### I lost my age key

If you have a recovery key stored offline, use it to re-key every file
for a fresh machine key.

If you lost **every** age key and had no recovery: the ciphertext is
effectively lost. You'll need to delete every `*.sops.*` file, rotate
every upstream secret with its provider, regenerate a new key, and
re-seed from scratch.

**This is why the scaffold `.sops.yaml` includes a placeholder for a
recovery key.** Don't skip it.
