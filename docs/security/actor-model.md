# Actor model — human, AI, bot, service

Every action in a system is performed by an **actor**. Good security
design starts with naming the actors, mapping each to an identity
system, and defining what each is allowed to do. Bad security design
treats "the user" as a single concept and fails the moment an AI agent,
a CI job, or a scheduled task needs to do something.

This doc defines the actor taxonomy used by Monty-CNS and Valor. Every
authentication decision, every audit log entry, every authorization
check should reference one of these actor types.

## The core principle: every action has exactly one attributable actor

No action in the system is performed by "the system" or "the process"
or "the user" as an abstraction. Every action has:

1. A **specific actor type** (one of the five below)
2. A **specific identity** within that type (a named human, a named bot, a named service)
3. A **specific reason** it's allowed to perform this action (a role, a permission, a grant)
4. A **timestamp and context** that makes the action reconstructable after the fact

When an audit log says *"user X did Y at time Z"*, that statement should
be literally true — not "something that ran as user X's effective
identity". This distinction matters most when humans and AI agents
share credentials, which is the single most common failure mode in
modern automation.

## The five actor types

### 1. 🧑 Human end-user

**Definition:** a natural person who is a customer, client, or end-user
of a Valor application. They typically don't have engineering access —
they use the product through a web UI, mobile app, or public API.

**Examples:**

- A Remedy Reconstruction project manager viewing a project dashboard
- A construction foreman submitting a daily log via the mobile field app
- A client signing an advisory agreement through a portal
- An end customer receiving a statement

**Identity system:**

- **Primary:** application-level user account (email + password, SSO via Okta/Azure/Google Workspace, or passkey)
- **MFA:** required for any account that can view or modify financial data
- **Session:** short-lived (web session cookies with reasonable TTLs, refreshed on activity)

**Authentication:**

- Login flow in the application
- Session tokens, not long-lived credentials
- Session tokens are **not** valid for backend API calls outside the application's frontend — they're scoped to the UI layer

**Authorization:**

- Role-based access control (RBAC) at the application level
- Row-level security at the database level (a user sees only their own data)
- Roles are defined by the application domain: "PM", "Foreman", "Office Admin", "Client", etc.

**Audit:**

- Every read and write of customer data attributed to the specific user
- IP address, user agent, and session ID logged
- Retention per the governing framework (SOX: 7 years, GLBA: 5 years typical, check your specifics)

**Allowed to touch:**

- Their own data
- Data shared with them by another user with permission to share
- Aggregate/anonymized data (subject to product design)

**NOT allowed to touch:**

- Other customers' data
- System configuration
- Other users' credentials
- Infrastructure

### 2. 🧑‍💻 Human operator

**Definition:** a developer, administrator, or operations engineer who
builds, maintains, and runs the Valor system itself. They have
engineering access: repositories, CI systems, production deployments,
databases (through bastions).

**Examples:**

- You, the developer working on Valor
- A future hired engineer
- An operations contractor maintaining the production database
- A security auditor with temporary read access

**Identity system:**

- **Primary:** corporate identity provider (Google Workspace, Okta, Azure AD, 1Password Teams)
- **MFA:** mandatory for every operator account, no exceptions
- **Hardware token:** encouraged for privileged operators (YubiKey for sudo, GitHub access)

**Authentication:**

- SSO into every tool (GitHub via SSO, AWS via SSO, databases via bastion + SSO)
- **Never** shared credentials
- **Never** long-lived credentials that can be copied to a laptop (use short-lived SSO session tokens or just-in-time access grants)

**Authorization:**

- Principle of least privilege: default deny, add permissions per role
- Just-in-time elevation for destructive operations (e.g. "make me admin for 15 minutes to run this migration")
- Per-environment separation: dev access ≠ staging access ≠ prod access
- Approval workflows for prod access requests

**Audit:**

- Every privileged command logged (bastion command history, AWS CloudTrail, GitHub audit log)
- Anomaly detection on unusual patterns (logins from new locations, bulk exports, etc.)
- Quarterly access review: every operator's permissions reviewed and trimmed

**Allowed to touch:**

- Code repositories (with branch protections and required reviews)
- Infrastructure (with approval gates for prod changes)
- Dev/staging databases freely
- Prod databases through audited bastion, only when necessary, only with break-glass justification

**NOT allowed to touch:**

- Customer data casually (every prod query logged and justifiable)
- Production credentials directly (they flow through IAM, not through files)
- Other operators' accounts
- Their own audit logs (tamper-proof)

### 3. 🤖 AI agent

**Definition:** a large language model or agentic system that makes
contextual decisions, generates code or content, and takes actions on
behalf of a human operator or end-user. The key distinction from a
"service/bot" is that AI agents make **non-deterministic decisions**
based on natural language input, whereas services follow deterministic
code paths.

**Examples:**

- Claude Code running on a human operator's laptop (helping them write code)
- Claude Code running in Claude Code on the web (same, remote context)
- A Valor-embedded agent that helps a Remedy project manager summarize field reports
- An automation agent that triages incoming support tickets
- A code review bot that's actually an LLM evaluating PRs
- Any `/agent` or `Task` subagent spawned within a Claude Code session

**Identity system:**

- **Primary:** the AI agent is **not** its own identity — it acts on behalf of a specific human or service. The identity it uses for authentication is derived from who or what spawned it.
- When Claude Code runs on your laptop, it acts as **you** (human operator). Its API key, git credentials, and file system access are all yours.
- When an AI agent is embedded in Valor and a customer triggers it, it should act as the **customer** (human end-user) for reads, and as a **dedicated service account** for any writes that aren't directly authorized by the customer.

**Authentication:**

- **Inheriting from a human:** the agent uses the human's credentials (with the human's consent and with audit). This is what Claude Code does today.
- **Inheriting from a service account:** a dedicated GitHub App installation, Valor API service account, or similar — used when the agent is a backend component, not a human tool.
- **Never:** sharing one agent credential across multiple humans. If two operators both use Claude Code, they each have their own Anthropic key, their own GitHub PAT, their own environment. No shared identity.

**Authorization:**

- **Strictly narrower than the human it's acting on behalf of.** The human can read 10,000 files; the agent is scoped to the current project. The human can push to any branch; the agent is blocked from `main` and must go through PR.
- **Read vs write asymmetry:** reads can be broad, writes should be narrow and logged. An agent that can read the whole repo should not be able to `git push --force`.
- **Destructive operation guardrails:** the `PreToolUse` hooks in CNS block `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`, etc. from Bash. This is the model for any AI agent: enumerate the destructive operations, block them, require explicit human confirmation to proceed.

**Audit:**

- Every tool call the agent makes, logged with:
  - Which human or service account it was acting for
  - Which tool was invoked
  - What arguments were passed
  - What the result was
  - Whether the action was successful or blocked by a hook
- Session transcripts retained for a reasonable window so you can reconstruct "what did the agent actually do and why"

**Allowed to touch:**

- Whatever the human or service it's acting for is allowed to touch, **minus** destructive operations, **minus** credential material, **minus** anything explicitly blocked by hooks.

**NOT allowed to touch:**

- Its own credentials (an agent should not be able to read the API key it's using)
- Other users' data (the acting human's scope is the hard limit)
- Tools that could self-exfiltrate (e.g., an AI agent should never be able to POST its own API key to a remote endpoint under normal operation)

### Key nuance: when AI acts as a human operator

This is the most important actor-model insight for Claude Code.

When you type `claude` on your laptop, Claude Code starts with your
identity: your shell env, your SSH keys, your `~/.config/gh` token,
your AWS credentials, everything. From the OS's perspective, Claude
Code is you.

That's **usually right** — you want Claude to be able to edit files,
run tests, commit, push, etc. using the same permissions you have.

That's **sometimes wrong** — you don't want Claude to be able to:

- Push to `main` without a PR
- Run `git reset --hard` on uncommitted work
- `rm -rf` anywhere sensitive
- Exfiltrate credentials
- Run arbitrary shell commands you haven't reviewed

The solution is **hooks** (`PreToolUse`, `Stop`, etc.) that intercept
tool calls and enforce guardrails. CNS's `settings.json` ships with two
universal `PreToolUse` hooks exactly for this reason:

1. Block writes to `.env`, `*.key`, `*.pem`, `credentials`, `secrets` paths
2. Block `rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE` in Bash

These are the bare-minimum guardrails when AI is acting as a human
operator. Extend them per project: if a project has its own destructive
commands, add them to the project's `.claude/settings.json`.

**The philosophical point:** AI agents should inherit the human's
permissions **minus a published list of dangerous operations**, never
the full set. Every dangerous operation the agent can't do is an
operation that requires explicit human confirmation to proceed. That
friction is the point.

### 4. 🤖 Service / bot

**Definition:** a deterministic, code-driven automation that runs
without human-in-the-loop. CI/CD jobs, scheduled workers, webhook
handlers, background workers, sync daemons. Unlike AI agents, services
follow fixed code paths — they do the same thing in the same way every
time they run.

**Examples:**

- The Valor CI pipeline (GitHub Actions running tests, building
  artifacts, deploying on merge)
- Valor's webhook handler listening for GitHub events
- A nightly Celery job that generates daily project reports
- A cron job that rotates PATs
- The `SessionStart` hook in CNS that pulls the repo and decrypts secrets
- Any `systemd` service, containerized daemon, or long-running worker

**Identity system:**

- **Primary:** a dedicated service account or GitHub App installation
- **Credential:** short-lived, auto-rotated (OIDC federation where possible, or a secret manager with rotation policies)
- **Never:** a human's credentials. Services get their own identity.

**Authentication:**

- **GitHub integration:** GitHub App with per-service installation
- **Cloud integration:** IAM role assumed by the service, with short-lived STS tokens
- **Database access:** dedicated DB user with minimum permissions, password rotated via secret manager
- **Inter-service:** mutual TLS or signed JWTs, not API keys
- **OIDC federation** wherever the cloud provider supports it (GitHub Actions → AWS via OIDC, no long-lived AWS keys)

**Authorization:**

- Per-service IAM policies, scoped to exactly what the service does
- **No blanket admin access.** A backup job needs read on certain tables; it doesn't need write on anything.
- Changes to service permissions require a PR and review

**Audit:**

- Every API call attributed to the service account (CloudTrail, GitHub audit log, application logs)
- Unusual patterns alert: a service that normally makes 1000 calls/day should trigger alerts at 10000/day
- Service accounts have **ownership** — a specific team or person is responsible for reviewing their audit trail

**Allowed to touch:**

- Exactly and only what their IAM policy permits
- A dedicated scope within the data they operate on (a reporting job reads all projects; an email sender only touches the email queue)

**NOT allowed to touch:**

- Other services' credentials
- Human-only resources (operator consoles, interactive shells)
- Anything outside their declared policy

### Important: bots are not agents

A bot runs the same code every time. If it has a bug, the bug is
deterministic and reviewable. You can trace every line of code the bot
runs and say "this is exactly what it did" without ambiguity.

An agent uses an LLM to decide what to do. Its behavior is
non-deterministic, context-dependent, and influenced by the prompt in
ways that aren't fully predictable. You can enumerate its tools but not
the sequence of tool calls it will make.

**The auth implications:**

- A **bot** can have a broader permission set because its behavior is
  provably constrained by its code.
- An **agent** needs narrower permissions because its behavior is not
  provably constrained — you have to rely on hooks and runtime
  enforcement rather than code review.

### 5. 🌐 External integration (third-party system)

**Definition:** another system outside your trust boundary that your
system integrates with. They authenticate to you (or you authenticate
to them) via a well-defined protocol, typically OAuth 2, mTLS, or
signed webhooks.

**Examples:**

- A bank sending transaction files via SFTP to Valor
- A broker API that Valor calls to place orders (where Valor is the
  client, bank is the server — the bank is the external integration
  from Valor's perspective)
- GitHub calling Valor's webhook endpoint
- Stripe calling Valor's payment webhook
- A customer's internal system pulling data from Valor's API

**Identity system:**

- **Outbound (Valor → them):** API keys, OAuth client credentials, or
  signed JWTs, stored in a secret manager
- **Inbound (them → Valor):** HMAC-signed webhook deliveries, mTLS with
  pinned certificates, or bearer tokens issued by Valor

**Authentication:**

- **Inbound:** verify every request. HMAC on webhooks. mTLS on
  dedicated connections. Bearer tokens must be validated server-side
  (not trust the client).
- **Outbound:** rotate credentials on the vendor's schedule, monitor
  for 401/403 responses, fail loudly if auth breaks.

**Authorization:**

- Each external integration has a declared scope: "this vendor can only
  write to the `incoming_transactions` table"
- Rate-limited per integration to prevent runaway calls
- Separate database users or IAM principals per integration

**Audit:**

- Every inbound request logged with the integration it came from
- Every outbound call logged with the credentials used
- Dedupe webhooks (see `github-auth.md`)

**Allowed to touch:**

- Exactly what the integration contract permits
- Usually limited to specific endpoints or specific tables

## Actor type × identity system matrix

| Actor type | Identity lives in | Credential type | Rotation cadence |
|---|---|---|---|
| Human end-user | Application user DB + SSO/passkey | Session token | Short session TTL, passive rotation |
| Human operator | Corporate IdP (Okta/Azure AD/Workspace) | SSO session + MFA | 8-12 hour session, hardware key for privileged actions |
| AI agent (acting for a human) | Inherited from the human | Human's credentials, filtered through hooks | Rotate when the human rotates |
| AI agent (acting for a service) | Dedicated service account | Service credentials | On schedule, like any service |
| Service / bot | Dedicated service account in IAM / GitHub App | OIDC-federated token or secret manager | Automated rotation, 1 hour – 30 day windows |
| External integration (inbound) | Webhook secret or mTLS cert in your secret manager | HMAC / mTLS / bearer token | Vendor-dictated, monitor for expiry |
| External integration (outbound) | Their credentials in your secret manager | API key / OAuth client | On vendor's schedule, automate where possible |

## Actor type × audit requirement matrix

| Actor type | Minimum audit fields | Retention |
|---|---|---|
| Human end-user | User ID, action, IP, user agent, session ID, timestamp | Per regulatory framework (5-7 years typical) |
| Human operator | Operator ID, action, source system, justification (for prod), timestamp | 3-7 years |
| AI agent | Acting identity, tool call, arguments, result, blocked hooks | 90 days – 1 year |
| Service / bot | Service name, action, resource ID, outcome | 90 days – 1 year |
| External integration | Integration ID, event type, delivery ID, signature verification result | 90 days – 1 year |

## Mapping actors to the GitHub auth choices

This is the intersection of `actor-model.md` and `github-auth.md`:

| Actor | GitHub auth method | Why |
|---|---|---|
| You typing at a laptop (human operator) | Fine-grained PAT or SSH key or `gh auth login` | Interactive, personal, narrowly scoped |
| A web app where users sign in with GitHub (human end-user via your app) | OAuth App | User-consented, per-user access |
| Claude Code running on your laptop (AI agent acting for you) | **Inherits** your PAT via the git credential helper, **plus** hooks that block destructive operations | AI agent scoped to a subset of what you can do |
| Valor production server running a webhook handler (service) | GitHub App installed on the target repos | Service identity, short-lived tokens, per-repo scope |
| Valor CI pipeline deploying to prod | GitHub App **or** GitHub OIDC federation to AWS | Whichever your cloud provider supports natively |
| A third-party vendor calling Valor's webhook | HMAC-signed delivery with a secret Valor chose | Your secret, your verification |

## The anti-pattern: "just share the credential"

The single biggest mistake in actor modeling is: "we'll just share the
same credential across all the cases that need GitHub access."

Example: a team where every developer, every CI job, every staging
deploy, and every production automation uses **the same** GitHub PAT
stored in a team shared drive.

Why it's bad:

1. **No audit separability.** You can't tell who did what — it's all
   one identity in the logs.
2. **No principle of least privilege.** The PAT has to have the union
   of all permissions anyone ever needs, so everyone gets admin.
3. **No revocation granularity.** A developer leaves → you have to
   rotate the shared PAT, update every service, and pray you didn't
   miss one.
4. **No rate limit fairness.** One runaway CI job exhausts the quota
   for the entire team.
5. **No compromise isolation.** A leak in any one place is a leak
   everywhere.
6. **Actor confusion.** Debugging "which agent did this" becomes
   impossible.

Every actor gets their own identity. Full stop. The cost of one extra
credential is always lower than the cost of the blast radius during a
compromise.

## Practical guidance for Valor

1. **Humans use SSO + MFA.** No shared logins.
2. **Developers' local Claude Code instances act as those developers** — their GitHub PATs, their Anthropic keys, their hooks. Nothing is shared.
3. **CI/CD uses GitHub Apps with OIDC federation to cloud providers.** No long-lived cloud keys.
4. **Valor's webhook handler is its own GitHub App installation.** Not a PAT. Not a service account that's also a developer's account.
5. **Customer-facing agents** (the ones embedded in the Valor product for end-user-facing AI features) have **dedicated service accounts** with narrow scopes per use case. Never use a developer's credential for a customer-facing agent.
6. **Every audit log shows the real actor.** If you see "user bot did X", either the actor model is wrong (bots aren't users) or the audit log is wrong (bot's name is "bot" and you can't tell which bot). Fix whichever it is.

## Cross-references

- `github-auth.md` — the auth implementation details per method
- `classification.md` — data classes per actor's access level
- `compromise-playbook.md` — rotation procedures per actor type
- `docs/plans/valor-github-integration.md` — the implementation plan using this actor model
