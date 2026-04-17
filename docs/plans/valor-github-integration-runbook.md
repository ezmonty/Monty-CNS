# Valor GitHub Integration — Operational Runbook

This is the single source of truth for operating the Valor GitHub App
integration. It is expanded incrementally as each phase ships. Skeleton
created during phase 0; consolidated and validated in phase 9.

See `docs/plans/valor-github-integration.md` for the full implementation
plan and task IDs referenced throughout.

---

## System overview

> Expanded in phase 4. Architecture diagram from vgi-4.1 goes here.

---

## Deploy procedure

> Expanded in phases 7.A, 7.B, and 8.A. Covers staging deploy, production
> secrets file encryption, Tailscale endpoint cutover, and canary rollout steps.

---

## Rollback procedure

> Expanded in phase 8.D. Documents the exact commands:
>
> 1. Set `GITHUB_INTEGRATION_ENABLED_REPOS=""` (empty) to disable.
> 2. Redeploy worker with previous known-good image.
> 3. Verify webhook receiver returns 200 (passthrough, no processing).
>
> Target: rollback completes in under 2 minutes.

---

## Rotation procedures

### App private key rotation

> Expanded in phase 9. Includes cache-invalidation steps for every layer
> that caches the credential (installation token in-memory cache
> via `invalidate_installation_token(installation_id)`). Quarterly
> rotation drill validates that `github:installation_token:*` key counts
> drop to zero after rotation.

### Webhook secret rotation (dual-secret window)

**(C5 amendment — vgi-9.A.1.a)**

Naive rotation (swap secret in secrets file, redeploy worker) drops every
in-flight delivery signed with the old secret — a self-inflicted outage
every rotation. Use the six-step dual-secret window instead:

1. **Generate v2 secret.** Create `webhook_secret_v2` (32 bytes, base64)
   and add it to `secrets/valor-github-app.sops.yaml` alongside the
   existing `webhook_secret` (which is now treated as v1):
   ```
   NEW_SECRET=$(openssl rand -base64 32)
   sops --set '["webhook_secret_v2"] "'"$NEW_SECRET"'"' secrets/valor-github-app.sops.yaml
   ```

2. **Deploy dual-secret worker.** Deploy worker config that reads BOTH
   `webhook_secret_v1` and `webhook_secret_v2` from the secrets file.
   `signature.verify` tries v2 first, falls back to v1 — both return
   "valid." Log which version matched at `info` level.
   Metric: `webhook_signature_version{version="v1|v2"}`.

3. **Update GitHub App webhook secret.** In Settings > GitHub App >
   Webhook > Secret, set the secret to the v2 value. New deliveries are
   now signed with v2; in-flight deliveries still arrive signed with v1
   and are accepted by the dual-secret verifier.

4. **Wait 24 hours.** Watch
   `webhook_signature_version{version="v1"}` drop to zero. If any v1
   deliveries are still arriving after 24h, investigate (likely a paused
   delivery being retried) before proceeding.

5. **Deploy v2-only worker.** Deploy worker config that reads ONLY
   `webhook_secret_v2`. `signature.verify` reverts to single-secret mode.

6. **Clean up secrets file.** Remove v1 and rename v2 back to the canonical name:
   ```bash
   # Edit via sops to remove v1 and rename v2 → webhook_secret
   sops secrets/valor-github-app.sops.yaml
   # (manually remove webhook_secret_v1, rename webhook_secret_v2 to webhook_secret)
   ```
   The next rotation starts from a clean state.

**Test requirement:** Before the first production rotation, test
dual-secret mode with three request types:

- Request signed with v1 — accepted (v1 match logged).
- Request signed with v2 — accepted (v2 match logged).
- Request signed with an unknown third secret — rejected (403).

All three assertions must pass before the dual-secret verifier is
considered ready.

### Age key rotation

> Expanded in phase 9. Covers age key re-generation procedure and updating
> the recipient list in `.sops.yaml` for all authorized machines.

---

## Common incidents

> Populated from dogfood lesson 5.6 and production experience. Every
> procedure below will have an "If ... fails" subsection per the plan's
> recovery-path requirement (vgi-9.A.2).

| Symptom | Likely cause | Fix | Escalation |
|---------|-------------|-----|------------|
| _TBD_   | _TBD_       | _TBD_ | _TBD_   |

---

## Escalation paths

> Expanded in phase 9.B. Defines PagerDuty integration, escalation tiers,
> and response-time expectations per severity level.

---

## On-call rotation

> Expanded in phase 9.B. Includes weekly handoff protocol with
> "known issues" carryover, documented here per vgi-9.B.4.

---

## Phase 0 — operator quickref

The minimum an operator needs to get started right now.

### App registration

1. Go to the Remedy org settings on GitHub.
2. Create a new GitHub App named `valor-bot`.
3. Set permissions:
   - **Contents:** Read
   - **Pull Requests:** Read + Write
   - **Metadata:** Read
4. Subscribe to the `pull_request` event.
5. Note the `app_id` — record it in the worklog.

### Private key storage

1. Download the `.pem` private key from the GitHub App settings page.
2. Encrypt it with sops immediately:
   ```
   sops --set '["private_key"] "'"$(cat ~/Downloads/valor-bot.*.private-key.pem)"'"' \
     secrets/valor-github-app.sops.yaml
   sops --set '["app_id"] "<APP_ID>"' secrets/valor-github-app.sops.yaml
   ```
3. Shred the local copy:
   ```
   shred -u ~/Downloads/valor-bot.*.private-key.pem
   ```
4. Verify no copies remain on disk:
   ```
   find ~/ -name '*.pem' 2>/dev/null | grep -i valor
   ```
   This **must** return empty. If any copy is found, shred it and
   re-verify. Phase 0 is not complete until the `.pem` exists only
   inside the sops-encrypted secrets file (C4 amendment — see exit criteria in the plan).

### Age recipients

Ensure `.sops.yaml` lists age recipients for all machines that need to decrypt.
