# Data classification

Every piece of data we handle falls into one of four classes. Which class
something is in determines **where it can live, who can touch it, and what
happens if it leaks**.

This is the standard four-tier model used across corporate security,
adapted to a personal + small-business context.

## The four classes

### 🟢 Public

**Definition:** information that is intentionally or incidentally visible
to the outside world. Leak has zero consequence.

**Examples:**
- `Monty-CNS` repo structure (once you decide to publish it)
- Open-source skill/command markdown files
- Public documentation
- Release notes
- The fact that Valor exists

**Where it can live:** anywhere — public git, website, docs site, README.

**Handling:** no special treatment.

---

### 🟡 Internal

**Definition:** information that isn't meant for the outside world but is
fine for anyone on the team / trusted circle to see. Leak is mildly
awkward but not harmful.

**Examples:**
- Private `Monty-CNS` dotfiles (your personal config, no secrets)
- Internal architecture notes
- `NOTES.md` captures from `/note`
- Migration logs (`docs/migration-valor2.md`)
- Project roadmaps
- Build configurations

**Where it can live:**
- Private git repo ✅
- Internal wiki ✅
- Not: public git, pastebins, third-party chat services without NDA

**Handling:**
- Repo visibility: private
- No special encryption required beyond disk encryption + access control
- OK to log
- OK in commit messages

---

### 🟠 Confidential

**Definition:** credentials, tokens, keys, personal information, or
business data where a leak causes real damage (financial, reputational,
or regulatory). Must be encrypted at rest, access-controlled, and tracked.

**Examples:**
- API keys (Anthropic, OpenAI, GitHub PAT, vendor tokens)
- OAuth refresh tokens
- MCP server credentials
- Database credentials for dev environments
- Personal SSH keys
- 1Password recovery kits / kdbx files
- Tax IDs (your own)

**Where it can live:**
- **Encrypted in a private git repo** (sops+age pattern) ✅ — this is what CNS does
- Dedicated secret manager (1P, Vault, Secrets Manager) ✅
- OS keychain (macOS Keychain, libsecret, Windows Credential Manager) ✅
- **Never in plaintext in git history**
- **Never in logs, shell history, or chat**
- **Never in screenshots shared publicly**

**Handling:**
- Encrypted at rest (sops or KMS)
- Encrypted in transit (TLS everywhere)
- Rotate on a schedule (monthly for high-value, on-demand for everything else)
- Rotate immediately on suspected compromise
- Scope tokens narrowly — never issue a PAT with `repo` scope when `public_repo` will do
- Billing alerts on any spendable API

---

### 🔴 Restricted

**Definition:** data whose leak triggers legal obligations (breach
notification, regulatory reporting, contractual penalties). Customer PII,
financial records, medical data, anything under a named compliance
framework.

**Examples:**
- Customer names + SSNs
- Customer bank account numbers / routing numbers
- Account balances, positions, transaction history
- Tax records belonging to someone other than yourself
- Health records (HIPAA)
- Card data (PCI-DSS)
- European resident data (GDPR)
- Broker-dealer transaction records (FINRA 17a-4 — 6-year retention)
- Client trust account data

**Where it can live:**
- A **production database** with:
  - Encryption at rest (AES-256 via AWS RDS / Postgres TDE / similar)
  - Encryption in transit (TLS 1.2+)
  - Row-level access control
  - Full audit log (every read and write, per user, retained)
  - Automated backups, encrypted, tested restore procedure
  - Appropriate retention policy (some frameworks require deletion after N years, others require **retention** for N years)
  - Data residency appropriate to the jurisdiction
- A **purpose-built vault** for secrets related to restricted data (HashiCorp Vault, AWS Secrets Manager, cloud KMS)

**Where it cannot live:**
- **Git, under any circumstances.** Not encrypted, not private, not "it's fine, we're a small team". Git history is forever and regulators do not care that sops was used. Ciphertext today can be plaintext tomorrow if the key leaks or the algorithm is broken.
- Developer laptops, except for minimal samples under explicit sampling policies
- Chat tools
- Email
- Unencrypted backups
- Shared cloud storage without access controls

**Handling:**
- All the Confidential rules, **plus**:
- Formal access-request process with logged approvals
- Regular access reviews (quarterly minimum)
- Security professional review of the architecture
- Penetration testing
- Compliance audits appropriate to the framework
- Incident response plan with legal on the distribution list
- Cyber insurance
- Data Processing Agreements (DPAs) with any vendor touching the data

**If you find yourself about to put Restricted data somewhere: stop, and ask a security professional first.**

## Mapping CNS components to classes

| Thing | Class | Where it lives |
|---|---|---|
| Monty-CNS repo itself (code + docs) | 🟡 Internal | Private git |
| `claude/settings.json`, hooks, commands, skills | 🟡 Internal | Private git (tracked) |
| `claude/mcp/servers/*.json` | 🟡 Internal | Private git (tracked, no secrets inside) |
| `Monty-CNS-Secrets/env.sops.yaml` (ciphertext) | 🟠 Confidential | Private git (encrypted blob only) |
| `~/.config/sops/age/keys.txt` (the age private key) | 🟠 Confidential | Local disk, 0600, behind FDE |
| `$CLAUDE_ENV_FILE` contents at session start | 🟠 Confidential | Process memory only, ephemeral |
| `~/.claude/logs/session-start.log` | 🟡 Internal | Local disk (logs describe the process, NOT the decrypted values) |
| Anything customer-facing in Valor | 🔴 Restricted | **NOT in CNS. Separate infrastructure, see valor-scope.md** |

## When in doubt

Ask:

1. If this leaked publicly tomorrow, what's the worst thing that happens?
2. Is anyone **other than me** affected if this leaks?
3. Am I legally obligated to protect it?

- (1) "nothing" → 🟢 Public
- (1) "mildly embarrassing, no one hurt" → 🟡 Internal
- (1) "I lose money or get hacked" AND (2) "just me" → 🟠 Confidential
- (2) "yes, other people" OR (3) "yes" → 🔴 Restricted

**Anything 🔴 leaves CNS and goes into its own purpose-built architecture.**
