# GitHub authentication — the authoritative reference

This doc is the decision-and-implementation reference for every GitHub
authentication choice in the Monty-CNS + Valor ecosystem. Read this
before writing any code that touches the GitHub API or git pushes to a
private repo.

**Position:** every GitHub authentication method solves a subset of the
problem. Pick the one that matches the actor doing the authentication
(see `actor-model.md`) — the answer changes depending on whether you're
a human typing at a laptop, a server running 24/7, or an AI agent
making contextual decisions.

## The six authentication methods, ranked by use case fit

| Method | What it is | Who authenticates | Token lifetime | Best for |
|---|---|---|---|---|
| **Fine-grained PAT** | Personal Access Token scoped to specific repos and permissions | A specific human | 7 days – 1 year (user-set, 90 days recommended) | Personal dev tools (CNS), interactive use by one human |
| **Classic PAT** | Legacy PAT with broad scopes | A specific human | Up to "no expiration" | **Avoid.** GitHub is phasing these out. No reason to use one in 2026. |
| **SSH key** | Asymmetric keypair stored on the user's machine + registered to their GitHub account | A specific human, via ssh-agent | Until explicitly revoked | Humans who prefer SSH, ops hosts running cron jobs with a dedicated account |
| **OAuth App** | Third-party app acts as a specific user after OAuth consent flow | A human, via browser redirect to "allow access" | 8 hours (auto-refresh) | A web UI where users log in with GitHub and the app acts on their behalf |
| **GitHub App** | App has its own identity, installed per-repo or per-org, uses JWT → installation token exchange | The app itself (not a human) | Installation tokens = 1 hour, auto-regenerated | Production automation, CI/CD, bots, webhook handlers, any server-side integration |
| **Device Flow** | User types a code into github.com to grant a headless device access | A human, with no browser on the target device | 8 hours (auto-refresh) | CLI tools on machines without a browser (Raspberry Pi, Docker containers, SSH sessions) |

## Decision tree

```
Who or what is calling the GitHub API?
│
├─ A human, interactively (me typing at a laptop)
│   │
│   ├─ I'm on my laptop with a browser
│   │   │
│   │   ├─ I want one tool per machine with narrow scopes → Fine-grained PAT
│   │   ├─ I want silent auth forever, will manage SSH keys → SSH key
│   │   └─ I want the easiest browser-based flow and I'm OK with a CLI dependency → gh auth login (which uses a Device Flow under the hood)
│   │
│   └─ I'm on a headless device (Pi, container, SSH session)
│       │
│       └─ Device Flow (via gh auth login --web or the raw device-flow API)
│
├─ A human, through a web app I built
│   │
│   └─ OAuth App (the user clicks "Sign in with GitHub", grants consent,
│      your app holds a per-user access token and can act on their behalf
│      within the scopes they granted)
│
└─ A machine / automation / AI agent with its own identity
    │
    ├─ I control which repos it can touch (e.g. "bot on these 3 repos")
    │   │
    │   └─ GitHub App, installed on the specific repos, with the
    │      minimum permissions the workflow needs
    │
    └─ I need a different identity for each machine in a fleet
        │
        └─ GitHub App with multiple installations, one per fleet member,
           plus per-installation installation tokens
```

**One-sentence summary:** humans get PATs or SSH keys; web apps get OAuth Apps; servers and AI agents get GitHub Apps.

## Deep dive: GitHub Apps

Because GitHub Apps are the right choice for Valor's production needs,
they get the longest section. This is the architecture, the auth flow,
the Python code to implement it, the webhook plumbing, the rate-limit
considerations, and the key storage guidance.

### Architecture

```
┌───────────────────────────────────────────────────────────┐
│  github.com/apps/valor-bot  (one-time registration)       │
│                                                           │
│  - App ID: 123456                                         │
│  - Private key (PEM): downloaded once, stored securely    │
│  - Webhook URL: https://api.valor.example.com/gh-hook     │
│  - Webhook secret: HMAC key for signature verification    │
│  - Permissions: Contents R/W, PRs R/W, Issues R/W,        │
│                 Checks W, Metadata R                      │
│  - Events subscribed: push, pull_request, issue_comment,  │
│                       check_run, check_suite, release     │
└──────────────────┬────────────────────────────────────────┘
                   │
           Installed on specific repos:
                   │
      ezmonty/valor2.0, remedy/cons-os, …
                   │
                   ▼
┌───────────────────────────────────────────────────────────┐
│  Valor production server (FastAPI + Celery + Redis)      │
│                                                           │
│  Startup:                                                 │
│    - Fetches private key from AWS Secrets Manager         │
│    - Holds in memory for the process lifetime             │
│                                                           │
│  Every time it needs to call the GitHub API:              │
│    1. Sign JWT with private key (10 min expiry)           │
│    2. Exchange JWT for installation token (1 hr expiry)   │
│    3. Cache installation token in Redis until expiry     │
│    4. Use cached token, throw away after expiry           │
│                                                           │
│  Incoming webhooks:                                       │
│    1. Verify X-Hub-Signature-256 HMAC                     │
│    2. Check X-GitHub-Delivery ID for idempotency         │
│    3. Enqueue event to Celery for async processing       │
│    4. Return 200 within webhook delivery timeout         │
└───────────────────────────────────────────────────────────┘
```

### The JWT → installation token exchange, step by step

1. **Generate a JWT** signed with the app's RSA private key.
   - `iss`: the app ID (integer)
   - `iat`: the current time, minus 60 seconds (clock skew tolerance)
   - `exp`: the current time plus 10 minutes (GitHub enforces ≤10 min)
   - Algorithm: `RS256`
2. **POST the JWT** to `https://api.github.com/app/installations/<installation_id>/access_tokens` with `Authorization: Bearer <jwt>`.
3. **Receive an installation token** with a 1-hour expiry and the permissions scoped to that installation.
4. **Use the installation token** as a bearer token for subsequent API calls: `Authorization: token <installation_token>`.
5. **Cache the installation token** keyed by installation ID, with a TTL slightly shorter than the server's reported expiry (e.g. 55 minutes for a 60-minute token) to avoid using expired tokens due to clock drift.
6. **On expiry**, regenerate the JWT, re-exchange, cache the new installation token.

### Python reference implementation (GitHubKit)

**SDK choice:** **GitHubKit** is the 2026-recommended Python SDK for new
GitHub App integrations. It's type-safe (generated from GitHub's official
OpenAPI schema, so the types are always up-to-date), supports REST +
GraphQL + webhooks + sync + async in one package, and has native
GitHub App authentication built in. Latest version at time of writing:
0.15.2 (April 2026).

Alternatives:
- **PyGithub** — widely used, mature, but doesn't cover every endpoint
  and is less ergonomic for App-style auth. Fine for existing integrations,
  not the default for new ones.
- **octokit.py** — thin wrapper, less maintained. Don't pick this for
  new work.

**Install:**

```bash
pip install 'githubkit[auth-app]'
```

**Auth flow:**

```python
import time
import jwt
from pathlib import Path
from githubkit import GitHub
from githubkit.auth import AppInstallationAuthStrategy

# Load private key (see "Private key storage" section below)
private_key = Path("/run/secrets/github-app.pem").read_text()
app_id = 123456
installation_id = 9876543

# Option A: let GitHubKit manage the JWT and installation token lifecycle
auth = AppInstallationAuthStrategy(
    app_id=app_id,
    private_key=private_key,
    installation_id=installation_id,
)
gh = GitHub(auth=auth)

# Every call auto-refreshes the installation token when it expires
repo = gh.rest.repos.get("ezmonty", "valor2.0")
print(repo.parsed_data.full_name)
```

If you want **manual control** of the JWT signing (e.g. for a worker pool
that shares a single installation token across processes via Redis):

```python
# Option B: manual JWT + installation token, cache in Redis
def mint_jwt(private_key: str, app_id: int) -> str:
    now = int(time.time())
    payload = {
        "iss": app_id,
        "iat": now - 60,      # 60s clock skew tolerance
        "exp": now + 600,     # 10 minutes max
    }
    return jwt.encode(payload, private_key, algorithm="RS256")

async def get_installation_token(app_id: int, installation_id: int, private_key: str, redis) -> str:
    key = f"github:installation_token:{installation_id}"
    cached = await redis.get(key)
    if cached:
        return cached.decode()

    app_jwt = mint_jwt(private_key, app_id)
    app_gh = GitHub(auth=app_jwt)
    resp = await app_gh.rest.apps.async_create_installation_access_token(
        installation_id=installation_id
    )
    token = resp.parsed_data.token
    # Cache with TTL 55 minutes (slightly less than the 1 hour expiry)
    await redis.setex(key, 55 * 60, token)
    return token
```

### Webhook handling (FastAPI)

GitHub sends every event your app subscribes to as an HTTP POST to your
webhook URL, with:

- `X-GitHub-Event` — the event type (`push`, `pull_request`, `check_run`, …)
- `X-GitHub-Delivery` — a unique UUID per delivery (use for idempotency)
- `X-Hub-Signature-256` — HMAC SHA256 of the request body, computed with
  the webhook secret you configured when registering the app
- JSON body with the event payload

**Signature verification must happen on the raw body before parsing.** If
you let FastAPI parse the JSON first and then re-serialize it for HMAC,
you'll get a different byte sequence and the signature will fail to
verify.

```python
import hmac
import hashlib
from fastapi import FastAPI, Request, HTTPException, BackgroundTasks

WEBHOOK_SECRET = "<loaded from secrets manager>"

app = FastAPI()

def verify_webhook_signature(body: bytes, signature_header: str) -> bool:
    if not signature_header or not signature_header.startswith("sha256="):
        return False
    expected = "sha256=" + hmac.new(
        WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256,
    ).hexdigest()
    # Constant-time comparison to prevent timing attacks
    return hmac.compare_digest(signature_header, expected)

@app.post("/gh-hook")
async def github_webhook(request: Request, background: BackgroundTasks):
    # CRITICAL: read the raw body first, before any JSON parsing
    body = await request.body()
    signature = request.headers.get("X-Hub-Signature-256", "")

    if not verify_webhook_signature(body, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")

    event_type = request.headers.get("X-GitHub-Event")
    delivery_id = request.headers.get("X-GitHub-Delivery")

    # Idempotency check — dedupe retries by delivery ID
    if await already_processed(delivery_id):
        return {"status": "duplicate", "delivery_id": delivery_id}

    # Enqueue for async processing — always return 200 fast
    background.add_task(enqueue_event, event_type, delivery_id, body)
    return {"status": "accepted", "delivery_id": delivery_id}
```

### Webhook deduplication

GitHub retries failed webhook deliveries for approximately 48 hours. If
your server responds with 5xx or times out, the same event comes back
with the same `X-GitHub-Delivery` ID. Deduplicate on that ID:

```python
async def already_processed(delivery_id: str) -> bool:
    # Redis with 7-day TTL covers GitHub's retry window with margin
    key = f"gh:delivery:{delivery_id}"
    # SETNX returns 1 if key was set, 0 if it already existed
    result = await redis.set(key, "processed", ex=7 * 86400, nx=True)
    return result is None  # None means key already existed
```

**Important:** only mark processed **after successful handling**, not on
receipt. If your handler crashes, let GitHub retry. This means the dedup
check happens twice — once on arrival (fast reject of already-processed
deliveries) and once after successful processing (persist the "processed"
mark).

### Rate limits for GitHub Apps

- **Baseline for installation tokens:** 5,000 requests per hour per
  installation
- **Scaling:** +50 requests per repo beyond 20 repos, +50 per member
  beyond 20 members, capped at 12,500 req/hr on github.com
- **GitHub Enterprise Cloud (GHEC):** 15,000 req/hr baseline
- **GraphQL:** separate limit, 5,000 points per hour (each query has a
  point cost computed from the selection set)
- **Secondary rate limits:** undocumented but real — very high burst
  traffic can trigger per-minute limits returning 403 with
  `x-ratelimit-remaining: 0` and no retry hint. Back off aggressively
  if you hit this.

**Handling 429 responses:**

```python
from githubkit.exception import RateLimitExceeded
import asyncio
import random

async def api_call_with_retry(fn, *args, **kwargs):
    for attempt in range(5):
        try:
            return await fn(*args, **kwargs)
        except RateLimitExceeded as e:
            retry_after = int(e.response.headers.get("Retry-After", 60))
            jitter = random.uniform(0, 5)
            await asyncio.sleep(retry_after + jitter)
    raise RuntimeError("Rate-limited 5 times in a row")
```

**Rate limit best practices:**

- Read `x-ratelimit-remaining` header on every response and log it as a
  metric. When it drops below 10% of the quota, fire an alert.
- For bulk operations, use the GraphQL API where possible — many REST
  calls become one GraphQL query, and the cost model favors batched
  operations.
- Cache aggressively. Many fields on `GET /repos/:owner/:repo` change
  rarely; re-fetch every 15 minutes at most.
- If you hit the limit frequently, consider splitting work across
  multiple GitHub Apps (each with its own installation = its own quota).

### Private key storage (the most important part)

The app's private key is the crown jewel. Anyone who has it can mint
valid JWTs, exchange them for installation tokens, and act as the app on
every repo it's installed on. **Treat it like a root credential.**

**Storage hierarchy, best to acceptable:**

1. **AWS Secrets Manager / GCP Secret Manager / Azure Key Vault**  
   Fetched once at process startup, cached in memory for the process
   lifetime. Rotation is handled by the secret manager's rotation
   features. Decryption is logged in CloudTrail.

2. **HashiCorp Vault with dynamic secrets**  
   Better than cloud secret managers if you need fine-grained leases,
   dynamic rotation, or multi-cloud. Supports the GitHub secrets engine
   for issuing short-lived tokens.

3. **Kubernetes secret** (if you run on K8s)  
   Acceptable if you have envelope encryption enabled at the etcd level
   and tight RBAC on who can `kubectl get secret`. Otherwise, pull from
   a real secret manager using external-secrets-operator.

4. **Environment variable** (set by your deployment platform)  
   Acceptable for CI/CD runners and small deployments. Risk: process
   memory dumps and error reports often include env vars — watch your
   logging configuration.

5. **Mounted file on tmpfs**  
   Acceptable if the mount is ephemeral and not persisted to disk. Much
   better than a file on normal disk storage.

**Never do:**

- Commit the `.pem` to git (yes, even "temporarily", yes, even "the repo is private")
- Store in a shared chat tool, even in a "secure" channel
- Paste it in an issue or PR comment
- Email it
- Pass it on the command line (visible in `ps aux` to other processes)

**FastAPI startup pattern** (AWS Secrets Manager example):

```python
from contextlib import asynccontextmanager
import boto3
import json
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # On startup: fetch the private key once, hold in memory
    sm = boto3.client("secretsmanager")
    secret = sm.get_secret_value(SecretId="prod/github-app/private-key")

    # The secret value should be the raw PEM, or a JSON blob with a key field
    try:
        payload = json.loads(secret["SecretString"])
        app.state.github_app_private_key = payload["private_key"]
    except json.JSONDecodeError:
        app.state.github_app_private_key = secret["SecretString"]

    app.state.github_app_id = int(payload.get("app_id", "123456"))
    app.state.github_app_webhook_secret = payload.get("webhook_secret")

    yield

    # On shutdown: no cleanup needed — memory is wiped with the process

app = FastAPI(lifespan=lifespan)
```

### Key rotation

GitHub lets you generate a second private key for the same app. Use this
for zero-downtime rotation:

1. Generate a new private key in github.com/apps/valor-bot/settings → "Generate a private key"
2. Upload the new key to your secret manager as `prod/github-app/private-key-v2`
3. Update your app to try v2 first, fall back to v1
4. Deploy
5. Delete v1 from github.com (which revokes it)
6. Remove v1 from the secret manager
7. Remove the fallback code

This is the same pattern as database password rotation — always have two
valid credentials during a transition, never zero.

## Migration path: PAT → GitHub App

If you start with a PAT-based integration and want to migrate to a
GitHub App (which you should as soon as you're running production
automation), here's the order of operations:

1. **Register the GitHub App** with the same permissions your PAT has been using
2. **Install it on the same repos** your PAT was being used for
3. **Dual-write phase:** update your code to support both auth methods behind a feature flag. Default to PAT, allow flipping to App.
4. **Test in staging** with the flag flipped to App
5. **Flip prod** behind the flag
6. **Verify** audit logs show the App as the actor on recent commits/comments/etc.
7. **Revoke the PAT** from github.com/settings/tokens
8. **Remove PAT-auth code** in a follow-up PR

The key insight: the GitHub App's installation token and a PAT can coexist
on the same repo. There's no lock-in during the transition.

## Octokit SDK landscape (2026)

| SDK | Language | GitHub App support | Webhook handling | Type safety | Recommended? |
|---|---|---|---|---|---|
| **GitHubKit** | Python | ✅ native, ergonomic | ✅ | ✅ (generated from OpenAPI) | **Yes** — default for new Python work |
| PyGithub | Python | ✅ supported | partial | type hints but not generated | Existing integrations |
| octokit.py | Python | basic | no | no | Don't use for new work |
| **@octokit/app** + **@octokit/webhooks** | JavaScript / TypeScript | ✅ native (official Octokit SDK) | ✅ dedicated package | ✅ | **Yes** — default for Node |
| octokit.rb | Ruby | ✅ | ✅ | N/A | **Yes** — default for Ruby |
| **go-github** | Go | ✅ | ✅ | ✅ (compile-time) | **Yes** — default for Go |
| octokit.net | .NET / C# | ✅ | ✅ | ✅ | **Yes** — default for .NET |

All are MIT or Apache-2 licensed. All track the GitHub API version. Pin
your SDK version in production to avoid breakage from silent upstream
changes, and update on a deliberate schedule.

## Revocation reference card

Bookmark these URLs — they're your compromise playbook entries:

- **PAT revocation:** https://github.com/settings/tokens
- **SSH key revocation:** https://github.com/settings/keys
- **OAuth App authorization revocation:** https://github.com/settings/connections/applications
- **GitHub App installation:** https://github.com/settings/installations (user-owned apps) or `https://github.com/organizations/<org>/settings/installations` (org-owned)
- **GitHub App private key regeneration:** https://github.com/settings/apps/<app-slug> → "Private keys" section
- **Active sessions (kills all cookies):** https://github.com/settings/sessions
- **Audit log:** https://github.com/settings/security-log (user) or org audit log (team)

## Cross-references

- `actor-model.md` — who's authenticating and why that determines the auth choice
- `compromise-playbook.md` — what to do when any of these credentials leak
- `docs/plans/valor-github-integration.md` — the implementation plan for Valor's GitHub App
- `claude/mcp/servers/github.json` — Monty-CNS's MCP server definition using a PAT (correct choice at user scope)
