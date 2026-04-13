# Valor scope — what CNS is NOT for

This document exists because the question will come up repeatedly: *"Can
we use CNS to hide/encrypt customer data for Valor?"* The answer is
**no, and here's why, in detail, so the answer stays firm when someone
(including future-you) tries to cut corners.**

## The one-line answer

**CNS is for developer operational config and revocable secrets. Valor's
customer financial data is Restricted-class and requires its own
purpose-built architecture.**

## What Valor will handle (as described)

When Valor matures, it will touch:

- **Accounting data** — general ledger, journals, transaction history
- **Brokerage data** — positions, orders, trade history, account balances
- **Banking data** — account numbers, routing numbers, ACH transfer records, wire instructions
- **Client PII** — names, SSNs, addresses, DOBs, tax IDs
- **Tax records** — 1099s, W-2s, K-1s, filings
- **Authorization records** — signed advisory agreements, ACH authorizations, durable POAs

Every one of these is **Restricted** under our `classification.md` model.
Every one of these has **regulatory frameworks** attached.

## Frameworks that apply (non-exhaustive)

Depending on Valor's exact scope and customers, at least some of these
apply. Get a compliance professional to map the specifics — this list is
what to expect, not a definitive scoping.

| Framework | Applies when | Key requirements |
|---|---|---|
| **SOX (Sarbanes-Oxley)** | Public company financial reporting | Internal controls, audit trails, segregation of duties, document retention |
| **GLBA (Gramm-Leach-Bliley)** | Financial institution handling consumer financial info | Safeguards Rule (written security program), Privacy Rule (disclosure notices), Pretexting rules |
| **FINRA 17a-4** | Broker-dealers | **6-year retention** of records in **non-rewritable, non-erasable** format (WORM). Specific formats required. Git explicitly does not qualify. |
| **Reg S-P** | Broker-dealers privacy | Customer notice requirements, opt-out, safeguards |
| **SEC Advisers Act / Reg S-P** | Registered Investment Advisers | Custody rule, compliance program, Form ADV disclosures |
| **IRS Pub 1075** | Handling federal tax information | Specific access controls, audit logging, physical security, sanitization |
| **PCI DSS** | Card data (unlikely in Valor but possible for fees) | 12 requirements, annual audits if merchant level 1-2, tokenization strongly recommended |
| **State breach notification laws** (all 50 US states) | Any PII leak affecting state residents | Notification timelines (varies), regulator reporting, potentially cyber insurance trigger |
| **NY SHIELD Act** | Any entity holding NY resident data | Reasonable safeguards, breach notification, specific to NY residents |
| **CA CCPA / CPRA** | California resident data | Right to deletion (incompatible with git history), data inventory, consumer disclosures |
| **GDPR** | Any EU resident data | Right to erasure, data minimization, DPO requirements, 72-hour breach notification |

**If Valor touches any of this data and is anything other than your own
personal records, you need a compliance professional involved.** This
repo's docs cannot replace that review.

## Why CNS's sops+age pattern is the wrong tool for this

sops+age in git works beautifully for:

- ✅ A small number of values (10s to maybe 100s)
- ✅ All authorized users need the same values
- ✅ Values rotate on a schedule or on-demand
- ✅ You control the git host and the recipients
- ✅ Operational secrets whose compromise triggers a quick rotation, not a legal process

It breaks down for regulated customer data:

- ❌ **Cardinality.** You can't put millions of customer records in flat YAML files and commit them.
- ❌ **Retention.** FINRA 17a-4 requires non-rewritable storage — git's entire model is rewritable history. GDPR requires erasure — git never forgets.
- ❌ **Access control granularity.** sops gives "can decrypt yes/no". Regulated data needs per-record, per-field, per-user, time-limited, audit-logged access.
- ❌ **Audit logs.** Git's commit log is not an audit log of who read what, when. Compliance needs precise, tamper-evident read logs.
- ❌ **Incident response.** A git leak of encrypted customer data is still a reportable incident under most breach laws. "But it's encrypted" is not a defense; you're required to report based on potential exposure.
- ❌ **Algorithmic longevity.** AES-256 is fine today. In 20 years under quantum attack? Unknown. Ciphertext of customer data in git 20 years from now might be plaintext in a world you don't control.
- ❌ **Key management lifecycle.** Regulated environments require specific key rotation schedules, dual control for rotations, HSM-backed storage, formal key ceremony procedures. sops+age is a single-user convenience tool.
- ❌ **Legal discoverability.** Git history is evidence. A subpoena compelling you to produce customer data discovered through git commits is a different legal posture than producing it through a database access log.

## What Valor should use instead

This is out of scope for CNS, but for orientation — a reasonable
production architecture for the data types above looks roughly like:

### Application data (customer records, transactions, positions)

- **Database:** managed PostgreSQL (AWS RDS, Google Cloud SQL, Azure Database) with:
  - Encryption at rest (AES-256 via the cloud provider's KMS)
  - TLS 1.2+ for all connections
  - Row-level security for multi-tenant access
  - Audit logging via pgaudit or a dedicated event stream
  - Automated encrypted backups with tested restore procedure
  - Appropriate retention: **7+ years for broker-dealer records per 17a-4**
  - PITR (point-in-time recovery)
- **Application secrets:** AWS Secrets Manager / HashiCorp Vault / Google Secret Manager — not sops
- **Cached sensitive data:** Redis with TLS and ACLs, short TTLs

### Secrets that control that data

- **Production DB credentials:** AWS Secrets Manager with automatic rotation (Lambda-based) + IAM role-based access from application servers. **Not in git. Not in CNS.**
- **Broker API credentials:** same — dedicated secret manager, auto-rotated, accessed by application roles only
- **Signing keys (JWTs, webhooks):** HSM-backed or cloud KMS, key material never leaves the device
- **Encryption keys** (field-level encryption inside the DB): managed by cloud KMS with audit logging

### Access control

- **Humans** access production data only through a **bastion host + audit-logged query tool** (Teleport, strongDM, AWS Systems Manager Session Manager), never directly
- **Applications** access via IAM roles, not long-lived credentials
- **Principle of least privilege** enforced through RBAC — each service role has the minimum permissions it needs
- **Regular access review** — quarterly at minimum, more often for privileged roles

### Audit and monitoring

- **CloudTrail / Cloud Audit Logs** for infrastructure changes
- **Application-level access logs** for data reads and writes, retained per the governing framework
- **SIEM** (Splunk / Sumo / Datadog / self-hosted ELK) for log aggregation and anomaly detection
- **24/7 pageable on-call** for security incidents
- **Annual penetration test** (required for SOC 2, often for state regulators)
- **Incident response plan** reviewed at least annually

### Compliance artifacts

- **SOC 2 Type II** as a baseline for any SaaS handling financial data
- **Framework-specific audits** (PCI DSS if applicable, HIPAA if applicable)
- **Cyber insurance** with appropriate coverage for the expected volume of records × per-record cost
- **Data Processing Agreements** with every vendor touching the data
- **Privacy Policy + Terms of Service** reviewed by a lawyer familiar with the applicable frameworks
- **Written Information Security Program (WISP)** — required by some states (e.g. MA 201 CMR 17), good practice everywhere

## How to keep CNS and Valor separate without duplication

CNS and Valor can share engineering tooling, developer conventions, and
operational secret patterns. They **cannot** share the same vault for
different classes of data. Concrete guidance:

| Thing | CNS? | Valor? | Notes |
|---|---|---|---|
| Your personal ANTHROPIC_API_KEY | ✅ | ❌ | CNS pattern works for dev key |
| Valor production Anthropic key (if any) | ❌ | ✅ | Belongs in Valor's production secret manager |
| Valor dev DB credentials (local, synthetic data) | ✅ | ✅ | OK in CNS-style encrypted config for dev; different secret manager for prod |
| Valor production DB credentials | ❌ | ✅ | Never in CNS |
| Broker API credentials for demo/paper-trading account | Depends | ✅ | If it's your personal paper account, CNS is OK. If it acts on other users, production secret manager. |
| Broker API credentials for real trading | ❌ | ✅ | Never in CNS |
| Code (application source, infra config, CI pipelines) | ✅ | ✅ | Code in git is fine. Valor's code repo is separate from CNS. |
| Customer records | ❌ | ❌ (in git) | Only in the production database with proper controls |
| Tax records of you personally | 🟡 | ❌ | Your own tax data is arguably OK in CNS (Confidential); definitely not Valor customer data |

**Shared tooling, separate stores.** CNS is your personal laptop/dev
environment. Valor is a separate production system. The fact that CNS
teaches you patterns you'll use in Valor's dev workflow does not mean
Valor's production data should live in CNS.

## Red flags — stop if any of these are true

If during Valor development you catch yourself or a collaborator doing
any of these, stop and rethink:

- 🚩 "Let's just put the customer table schema in Monty-CNS-Secrets so it syncs" → **no**, use a proper database
- 🚩 "I'll commit a sample of real customer data for testing" → **no**, use synthetic data; real customer data never leaves production
- 🚩 "The sops file will have the production broker API key" → **no**, production credentials belong in a production secret manager with auto-rotation and audit logging
- 🚩 "We don't need a compliance review, we're small" → **you do**, the frameworks don't scale with company size
- 🚩 "Let's put customer SSNs in env vars for a batch job" → **no**, batch jobs pull from the database with audited queries
- 🚩 "This customer PDF is too big to store in the DB, let's commit it" → **no**, PDFs go in encrypted blob storage (S3 with SSE-KMS), metadata in the DB

## Escalation — when to get help

Get a qualified security / compliance professional involved when:

1. **Valor is about to touch any customer's financial data.** Before the first real customer, not after.
2. **You're designing the database schema** that will hold PII or financial records. Architecture review is cheap; rebuilding after a breach is catastrophic.
3. **You're integrating with a financial institution's API.** Most have their own compliance requirements you must pass.
4. **Any regulatory framework applies** (check the table at top of this doc).
5. **You've had a suspected compromise** involving data classified higher than Confidential. The compromise-playbook is for operational secrets; regulated-data incidents need a different response.
6. **You're writing a privacy policy or terms of service** for Valor. A template from the internet is not sufficient.
7. **You're buying cyber insurance.** The underwriters ask specific questions about your security posture.

This repo's docs are engineering hygiene. They are not compliance, legal
advice, or a substitute for professional review. When the stakes are
real, get the right people involved.
