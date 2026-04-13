# Where data lives — a decision tree

When you're about to store, move, or commit something, walk this tree
before you `git add` it.

## The tree

```
┌────────────────────────────────────────────────────────────────┐
│  What kind of thing are you about to store?                    │
└────────────────────────────────────────────────────────────────┘
                           │
          ┌────────────────┴────────────────┐
          │                                 │
          ▼                                 ▼
    Customer data /                  Your own data /
    regulated records?               operational config?
          │                                 │
          ▼                                 ▼
  ┌─────────────────┐             ┌──────────────────┐
  │ 🔴 RESTRICTED   │             │ Does it contain  │
  │                 │             │ credentials?     │
  │ NOT in CNS.     │             └──────────────────┘
  │ NOT in git.     │                     │
  │                 │              ┌──────┴──────┐
  │ Use:            │              │             │
  │ - Production DB │              ▼             ▼
  │ - Real secrets  │             Yes           No
  │   manager       │              │             │
  │ - See           │              ▼             ▼
  │   valor-scope   │      ┌──────────────┐  ┌──────────────┐
  └─────────────────┘      │ 🟠 CONFID.   │  │ 🟡 INTERNAL  │
                           │              │  │              │
                           │ Encrypt with │  │ Commit to    │
                           │ sops+age     │  │ private git  │
                           │ in           │  │ as-is        │
                           │ Monty-CNS-   │  │              │
                           │ Secrets      │  │ (Monty-CNS)  │
                           │              │  │              │
                           │ OR           │  │              │
                           │ OS keychain  │  │ Do NOT put   │
                           │              │  │ secrets here │
                           └──────────────┘  └──────────────┘
```

## Table form

| What you have | Class | Where it goes | How |
|---|---|---|---|
| An API key (yours) | 🟠 | `Monty-CNS-Secrets/env.sops.yaml` | `sops env.sops.yaml`, add key, commit, push |
| A service account JSON (yours) | 🟠 | `Monty-CNS-Secrets/mcp/*.sops.json` | `sops mcp/service.sops.json`, paste JSON, save |
| A new skill you wrote | 🟡 | `Monty-CNS/claude/skills/<name>/` | Plain markdown, commit |
| A new slash command | 🟡 | `Monty-CNS/claude/commands/<name>.md` | Plain markdown, commit |
| A hook script | 🟡 | `Monty-CNS/claude/hooks/` | Plain bash, commit (never hardcode secrets) |
| Personal notes | 🟡 | `~/NOTES.md` or `$CLAUDE_PROJECT_DIR/NOTES.md` | `/note` command (not tracked in CNS) |
| Someone else's personal info | 🔴 | Not in CNS. Production DB or purpose-built store | Get security review first |
| A customer's tax return | 🔴 | Not in CNS. See valor-scope | Same |
| A broker API key that moves real money | 🔴 | Real secrets manager (Vault, AWS SM, 1P Business) | Not here. Rotation and audit matter more than convenience |
| An SSH key for a production server | 🔴 | SSH agent + hardware key (YubiKey) or a bastion + ephemeral-credential flow | Not in CNS |
| A personal SSH key | 🟠 | `~/.ssh/id_*` (local, 0600, FDE-protected) | Optionally back up as `sops mcp/ssh-personal.sops.key` |
| `.env` file for a dev project | 🟠 | `sops .env.sops` in the project repo, NOT here | Per-project secrets are project-scoped |
| Infrastructure IaC (Terraform) | 🟡 (code) + 🟠 (state) | Code in git, state in a dedicated backend (S3 + KMS, etc.) | Terraform state often contains credentials — never commit state files |

## The hard rules

1. **Git is forever.** Anything committed, even to a private repo, is effectively permanent and assumed to be recoverable by future attackers. Don't commit a secret thinking "I'll remove it later" — the remove doesn't work.
2. **Ciphertext today may be plaintext tomorrow.** Encryption algorithms age. Keys leak. If the consequences of a future decryption are unacceptable, do not commit ciphertext of that data. sops+age is fine for operational secrets precisely because those secrets will be rotated before the ciphertext becomes interesting.
3. **Restricted data belongs in a database, not a repo.** Databases have row-level access controls, audit logs, backup encryption, retention policies, replication, and can be purged on request. Git has none of those.
4. **One secret per variable.** Don't pack multiple secrets into one string, one JSON blob, one token. Rotation is easier when the unit of rotation is small.
5. **Narrowest scope possible.** A GitHub PAT with access to one repo is safer than one with access to all your repos. An API key with "read only" is safer than "read-write".
6. **Log the process, not the secret.** Logs can say "decrypted 5 vars from env.sops.yaml into CLAUDE_ENV_FILE" but not what the vars are.

## "What about..."

### ...temporary scratch files?

Fine in `/tmp` or `~/scratch` (gitignored). Shred or let `tmpfs` clear them. Don't commit.

### ...a debug dump with secrets in it?

Encrypt the dump as confidential or delete it. Never commit a raw debug dump.

### ...an SSH private key that's a dev convenience?

Local disk only, `~/.ssh/id_*`, 0600, behind FDE. If you must sync across machines, add it as `Monty-CNS-Secrets/mcp/ssh-<name>.sops.key`. But consider using per-machine keys instead so rotation = delete one line from `.sops.yaml` and re-key.

### ...a TLS certificate (not the private key)?

Public cert is 🟢 Public. Private key is 🟠 Confidential. Store them separately.

### ...metrics or telemetry containing user IDs?

If user IDs are traceable to individuals → 🔴. Hash them first, or don't log them at all. If they're opaque internal IDs with no PII mapping → 🟡.

### ...error reports I want to share with a vendor?

Redact secrets before sending. Redact PII if it's in scope. Assume anything you email is forever.

## Git-as-vault — is this even a legitimate pattern?

**Yes, for the right data.** sops-in-git is used in production by major teams — Grafana Labs, Shopify, Mozilla (who wrote sops), and countless others. [`kubernetes-sigs/sealed-secrets`](https://github.com/bitnami-labs/sealed-secrets) is an entire Kubernetes ecosystem built on the same idea. git-crypt, Ansible Vault, and ejson are variations on the theme. **As long as what you commit is ciphertext and the key lives elsewhere, the pattern is sound.**

**The limit of the pattern:** it works for operational secrets (a small number of values that all authorized users need, rotated on a schedule or on event). It does not work for:
- High-cardinality data (many records, per-user values) — databases handle this
- Mutable data where history must not leak (git history IS the leak if retention rules require deletion)
- Data subject to "right to deletion" under GDPR/CCPA — git can't forget
- Regulated records requiring signed audit trails of access

**Git is a vault for config. A database is a vault for data.** Different tools, different jobs.
