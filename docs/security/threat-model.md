# Threat model

What this system protects, from whom, and what it explicitly does not
defend against. Being honest about the threat model is the first step in
avoiding both under- and over-engineering.

## Assets (what we protect)

### In-scope for CNS

| Asset | What it is | Rotation cost if compromised |
|---|---|---|
| **API keys** (Anthropic, OpenAI, GitHub PAT, etc.) | Tokens for paid services | 30 seconds — rotate in the provider dashboard |
| **OAuth refresh tokens** | Long-lived access grants | Minutes — re-auth per service |
| **MCP server credentials** | Auth for tools Claude Code spawns | 30 seconds — same as API keys |
| **Personal dev env config** | Settings, commands, skills, hooks | Not really secret — but still worth keeping private |
| **Personal notes / captures** | `NOTES.md`, working notebook | Embarrassing if leaked; not financially damaging |

### Out-of-scope for CNS

These are **not** handled by this repo and require separate infrastructure:

| Asset | Where it belongs | Why not here |
|---|---|---|
| **Customer PII** (names, SSNs, DOBs, addresses) | Production database with encryption-at-rest, TLS in-transit, access logs, backup retention | Git history is forever; sops doesn't satisfy regulatory controls |
| **Financial records** (balances, transactions, tax data) | Same — production database with full auditing | Regulated under SOX / GLBA / FINRA 17a-4 — requires strict retention + access controls CNS can't provide |
| **Banking / brokerage API credentials** that act on customer accounts | A real secret manager (AWS Secrets Manager, HashiCorp Vault, 1P Business) with per-access audit logging | Higher blast radius — a leak can move real money |
| **Signing keys** (code signing, JWT signing, webhook signatures) | Hardware-backed keystore (YubiKey, HSM, cloud KMS) | Key material should never be on a general-purpose filesystem |
| **Auth session cookies / user sessions** | Application-layer session store (Redis, DB), never in git | Ephemeral by nature |

**Rule of thumb:** if the thing being protected is *customer data* or *regulated records*, CNS is the wrong place. See `valor-scope.md`.

## Adversaries (who we defend against)

In rough order of likelihood:

1. **Accidental commit of plaintext to git history.** The most common real-world credential leak. CNS defends via `.gitignore` + sops + pre-commit-friendly patterns.
2. **Curious coworker or passerby** looking at your screen. Defended via: secrets are ciphertext on disk and only in process memory at decrypt time.
3. **Lost or stolen laptop with the disk powered off.** Defended via full-disk encryption (FileVault / LUKS / BitLocker) — **this is doing the heavy lifting**, not sops.
4. **Lost or stolen laptop with the disk running and session unlocked.** Partially defended: an attacker with a running unlocked session can read your git repo, read `~/.config/sops/age/keys.txt`, decrypt, and exfiltrate. Mitigation: auto-lock, short screen-lock timers, FileVault-at-rest is the last line.
5. **Malware with user-level access.** Same as #4 — if the attacker is running code as you, game over for any user-accessible credentials.
6. **Malware with root.** Defense-in-depth fails here. Mitigation: don't run untrusted code as root, keep the OS patched, use SIP / SELinux / AppArmor.
7. **Physical attacker with cold-boot access** (RAM dump of a powered-on machine). Very unlikely in practice; mitigated by keeping the machine off when not in use.

## Adversaries we do NOT defend against

Be honest about these so we're not lying to ourselves:

- **Nation-state attackers with targeted interest in you.** If you're being specifically targeted by a well-funded adversary, CNS is not a defense. That's a different engagement and a different budget.
- **Supply-chain attacks on the tools themselves.** If `sops`, `age`, `git`, or Claude Code itself is backdoored, nothing in this repo stops it. Mitigation: pin known-good versions, verify checksums, watch for CVEs.
- **Legal process.** A subpoena compelling you to hand over the age private key bypasses all of this. Not something engineering can solve.
- **User error** beyond what automation can prevent. If you paste an API key into a public Slack channel, no amount of encryption helps.

## What "good enough" means for CNS

CNS's target threat model is **single-user personal dev environment for revocable API tokens**. Security bar:

1. **Plaintext secrets never enter git history.** Enforced by sops + `.gitignore`.
2. **Secrets on disk are encrypted at rest** (the sops ciphertext files and the age private key are both behind FDE).
3. **Decryption requires authentication** (logging into your machine = the access control).
4. **Compromise is detectable and recoverable quickly.** Billing alerts catch abuse, rotation is fast.
5. **No plaintext leaks into logs, shell history, or editor swap files.**

If those five are true, CNS is doing its job. Going harder than that (KMS, 1Password, YubiKey) is either a different threat model or an aesthetic choice.

## When to upgrade beyond CNS

Move to a proper secrets manager (AWS Secrets Manager, HashiCorp Vault, 1Password Business, GCP Secret Manager, Azure Key Vault) when any of these become true:

- **Multiple humans** share access to the same secrets and you need per-user audit logs
- **Automated systems** (CI/CD, production services) need to pull secrets — humans shouldn't be on the hot path
- **Secrets control real money or customer data** — the blast radius of a compromise goes from "$50 of API quota" to "a phone call from your lawyer"
- **Regulatory framework requires** specific controls (PCI, HIPAA, SOC 2 Type II, FINRA)
- **Key rotation needs to be automated** at a schedule or on an event — sops's manual flow becomes operationally expensive

For Valor specifically, when it starts touching real brokerage, banking, or accounting data for anyone other than you personally: **stop using CNS for those secrets**. Put production credentials in a real secret manager with proper IAM.
