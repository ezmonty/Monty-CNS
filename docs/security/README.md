# Security — index

This directory defines the security posture for the **Monty-CNS** system
(personal dotfiles, developer tooling, operational secrets) and documents
what this system is and is not appropriate for.

**Not legal or compliance advice.** These docs are engineering hygiene, not
a regulatory sign-off. If you're handling data that falls under SOX, GLBA,
PCI-DSS, FINRA 17a-4, HIPAA, GDPR, state breach-notification laws, or any
other regulated framework, get a qualified security / compliance
professional to review your production architecture. This repo's docs are
a starting point, not a finish line.

## Documents

| Doc | What it covers |
|---|---|
| [threat-model.md](threat-model.md) | Who we're defending against, what we're protecting, what we explicitly do not defend against |
| [classification.md](classification.md) | Data classification: Public / Internal / Confidential / Restricted — and which tools handle which class |
| [where-data-lives.md](where-data-lives.md) | Decision tree: does it go in git, a secret manager, a database, or a bank-grade vault? |
| [disk-encryption.md](disk-encryption.md) | Full-disk encryption setup per OS (FileVault / BitLocker / LUKS) — **mandatory** on any machine that runs CNS |
| [github-auth.md](github-auth.md) | Authoritative reference for every GitHub authentication decision — the six methods (PAT, SSH, OAuth App, GitHub App, Device Flow, CLI tokens), decision tree, GitHub App deep dive, Python/GitHubKit reference code, rate limits, private key storage |
| [actor-model.md](actor-model.md) | Five-actor taxonomy (human end-user, human operator, AI agent, service/bot, external integration), identity / auth / authz / audit per actor type, how AI agents inherit human permissions minus destructive operations, anti-patterns like shared credentials |
| [compromise-playbook.md](compromise-playbook.md) | Step-by-step incident response: laptop stolen, token leaked, key compromised |
| [valor-scope.md](valor-scope.md) | What this system is NOT for: customer data, regulated records, anything in Valor's database layer |

## One-sentence summaries

- **CNS is fine for:** developer dotfiles, API keys you rotate yourself, build-time config, personal notes
- **CNS is not fine for:** customer data, account balances, tax records, anything you legally have to retain or protect under a framework
- **Git-as-vault is a real pattern** used by production teams (sops, git-crypt, Sealed Secrets, Ansible Vault) — **for operational secrets**, not customer data
- **Customer financial data lives in a database**, not in git, encrypted or otherwise
- **FDE is mandatory** on any machine that touches these secrets. Cross-platform guidance in `disk-encryption.md`.
- **Humans get PATs, services get GitHub Apps** — see `github-auth.md` for the full decision framework
- **Every action has exactly one attributable actor** — see `actor-model.md` for the taxonomy
- **Compromise recovery is a process, not a technology** — the playbook is what matters

## Reading order for a new contributor

1. `threat-model.md` — understand what we're protecting
2. `classification.md` — understand what kind of data goes where
3. `actor-model.md` — understand who's doing the actions
4. `disk-encryption.md` — set up your own machine correctly
5. `github-auth.md` — understand the authentication options
6. `compromise-playbook.md` — know what to do if something goes wrong
7. `valor-scope.md` — know what this system is not for
8. `where-data-lives.md` — reference when designing new features
