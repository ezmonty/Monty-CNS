# Phase 0 — Human Operator Guide

This extracts the human-only tasks from the Valor GitHub Integration plan.
Complete these in order. The full plan is at `docs/plans/valor-github-integration.md`.

## Prerequisites

- [ ] Admin access to the Remedy Reconstruction GitHub org
- [ ] SSH/Tailscale access to the self-hosted rack
- [ ] HashiCorp Vault installed (or ready to install) on the rack
- [ ] Tailscale network set up between rack and GitHub egress IPs
- [ ] Full-disk encryption verified on the workstation (`fdesetup status` on macOS)

## Step 1: Register the GitHub App (vgi-0.A.1 through 0.A.5)

1. Go to `https://github.com/organizations/remedy-reconstruction/settings/apps/new`
2. Name: `valor-bot`
3. Set permissions: **Contents: Read**, **Pull requests: Read and Write**, **Metadata: Read**
4. Subscribe to events: **pull_request**
5. Generate a private key -- this downloads a `.pem` file.
   **DO NOT close this terminal session. The key must reach Vault before this session ends.**
6. Note the **App ID** (integer shown on the app settings page).
7. Generate a webhook secret:
   ```bash
   openssl rand -base64 32
   ```
   Copy the output. This is your `WEBHOOK_SECRET`.
8. Install the app on the test repo `remedy/valor-bot-test-sandbox`.
   Note the **Installation ID** from the URL after installation.
9. You should now have four values recorded (do NOT put them in git or a notes app):
   - `app_id` (integer)
   - `webhook_secret` (the base64 string from step 7)
   - `installation_id` (integer)
   - `.pem` file path (in `~/Downloads/`)

## Step 2: Set up Vault and transfer secrets (vgi-0.B.1 through 0.B.5)

1. Install Vault on the rack behind the Tailscale network
   (follow `docs/self-hosting.md` for the Tailscale pattern).
2. Initialize Vault with Shamir 3-of-5 key shares.
   Store unseal keys in the compromise playbook locations.
3. Transfer all four secrets to Vault in one command:
   ```bash
   vault kv put secret/valor/github-app \
     private_key=@~/Downloads/valor-bot.*.private-key.pem \
     app_id=<APP_ID> \
     webhook_secret=<WEBHOOK_SECRET> \
     installation_id=<INSTALLATION_ID>
   ```
4. Immediately shred the local `.pem`:
   ```bash
   shred -u ~/Downloads/valor-bot.*.private-key.pem 2>/dev/null \
     || rm -f ~/Downloads/valor-bot.*.private-key.pem
   ```
5. Verify the `.pem` is gone:
   ```bash
   find ~/ -name '*.pem' 2>/dev/null | grep -i valor
   # MUST return empty. If not, delete whatever was found.
   ```
6. Create a Vault policy `valor-gh-reader` with read-only access to
   `secret/valor/github-app/*` and issue a token for the Valor worker process.

## Step 3: Verify (hand off to code agent)

1. Run the phase-0 checklist script:
   ```bash
   bash docs/plans/phase-0-checklist.sh
   ```
   All checks must pass before proceeding.
2. The remaining phase-0 tasks (0.C webhook receiver, 0.D end-to-end verification)
   are code tasks handled by the development agent. Your human-operator work is done
   once Steps 1-2 are complete and the checklist passes.

## What NOT to do

- Do NOT store the `.pem` on USB, email it, or put it in git.
- Do NOT use the production App for testing -- use the sandbox repo only.
- Do NOT proceed to phase 1 until the checklist script passes.
- Do NOT share Vault unseal keys via chat or email -- use the compromise playbook locations.
