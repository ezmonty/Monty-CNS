# Phase 0 — Human Operator Guide

This extracts the human-only tasks from the Valor GitHub Integration plan.
Complete these in order. The full plan is at `docs/plans/valor-github-integration.md`.

## Prerequisites

- [ ] Admin access to the Remedy Reconstruction GitHub org
- [ ] sops and age installed on the workstation (`sops --version`, `age --version`)
- [ ] Age keypair generated (`~/.config/sops/age/keys.txt` exists)
- [ ] Full-disk encryption verified on the workstation (`fdesetup status` on macOS)

## Step 1: Register the GitHub App (vgi-0.A.1 through 0.A.5)

1. Go to `https://github.com/organizations/remedy-reconstruction/settings/apps/new`
2. Name: `valor-bot`
3. Set permissions: **Contents: Read**, **Pull requests: Read and Write**, **Metadata: Read**
4. Subscribe to events: **pull_request**
5. Generate a private key -- this downloads a `.pem` file.
   **DO NOT close this terminal session. The key must be sops-encrypted before this session ends.**
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

## Step 2: Encrypt secrets with sops+age (vgi-0.B.1 through 0.B.5)

1. Create a plaintext secrets file:
   ```bash
   cat > /tmp/valor-github-app.yaml << SECRETS
   private_key: |
     $(cat ~/Downloads/valor-bot.*.private-key.pem)
   app_id: "<APP_ID>"
   webhook_secret: "<WEBHOOK_SECRET>"
   installation_id: "<INSTALLATION_ID>"
   SECRETS
   ```
2. Encrypt with sops:
   ```bash
   sops --encrypt /tmp/valor-github-app.yaml > secrets/valor-github-app.sops.yaml
   ```
3. Immediately shred all plaintext:
   ```bash
   shred -u ~/Downloads/valor-bot.*.private-key.pem 2>/dev/null \
     || rm -f ~/Downloads/valor-bot.*.private-key.pem
   shred -u /tmp/valor-github-app.yaml 2>/dev/null \
     || rm -f /tmp/valor-github-app.yaml
   ```
4. Verify the `.pem` is gone:
   ```bash
   find ~/ -name '*.pem' 2>/dev/null | grep -i valor
   # MUST return empty. If not, delete whatever was found.
   ```
5. Verify decryption works:
   ```bash
   sops --decrypt secrets/valor-github-app.sops.yaml | grep -c private_key
   # MUST return 1
   ```
6. Verify the age recipient list in `.sops.yaml` includes all machines that need to decrypt.

## Step 3: Verify (hand off to code agent)

1. Run the phase-0 checklist script:
   ```bash
   bash docs/plans/phase-0-checklist.sh
   ```
   All checks must pass before proceeding.
2. The remaining phase-0 tasks (0.C webhook receiver, 0.D end-to-end verification)
   are code tasks handled by the development agent. Your work is done once the checklist passes.

## What NOT to do

- Do NOT store the `.pem` on USB, email it, or put it in git.
- Do NOT use the production App for testing -- use the sandbox repo only.
- Do NOT proceed to phase 1 until the checklist script passes.
- Do NOT share age private keys (`keys.txt`) via chat or email -- they stay on each machine, never shared.
