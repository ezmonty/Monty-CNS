# Compromise playbook

What to do if something goes wrong. Read this **now** so you're not
reading it for the first time in the middle of a real incident.

Keep this doc bookmarked and accessible from a device that is **not** the
machine you think is compromised.

## 🚨 Triage — first 5 minutes

Before doing anything else, answer these three questions:

1. **What's compromised?** A laptop? A single credential? A whole git repo? Your whole GitHub account?
2. **What data did it have access to?** Use `classification.md` to assess. Was it only CNS secrets, or did it touch Restricted data in Valor?
3. **Is the compromise still active?** If yes (laptop currently in attacker's hands, shell still has the session), cut the lifeline first.

If the compromise includes **Restricted data (customer info)**, stop
following this playbook and **call a qualified security / legal
professional immediately**. Breach notification laws have short clocks
(72 hours under GDPR, varying state laws in the US) and the wrong first
move can make the legal situation dramatically worse. This playbook is
for operational credential rotation, not regulated data incidents.

---

## Scenario A — Laptop lost or stolen

Assumption: device had CNS installed, encrypted disk, running session
that might still be unlocked.

### Immediate (within the first hour)

1. **Lock / wipe remotely** if possible:
   - macOS: https://icloud.com → Find My → locate → Mark As Lost → Erase This Mac
   - Windows: https://account.microsoft.com/devices → find device → Find My Device → Erase
   - Linux: no built-in remote wipe unless you pre-configured one (Prey, Tailscale + ssh kill)
2. **Change the lock/login password** on any other device that shares iCloud / Microsoft account state — the attacker may try to sync.
3. **Revoke active sessions** on your primary identity provider:
   - GitHub: https://github.com/settings/sessions → Sign out all sessions
   - Google: https://myaccount.google.com/security → Your devices → Sign out
   - 1Password / Bitwarden / Keychain: same principle, revoke all active sessions

### Within 4 hours

4. **Rotate every credential that was in `Monty-CNS-Secrets/env.sops.yaml`.** The age key to decrypt it may have been on that laptop. Assume everything decrypted on that laptop is compromised. Open each of these URLs and click "Revoke" or "Regenerate":
   - Anthropic: https://console.anthropic.com/settings/keys
   - OpenAI: https://platform.openai.com/api-keys
   - GitHub PATs: https://github.com/settings/tokens — revoke every token that machine had
   - GitHub SSH keys: https://github.com/settings/keys — revoke the machine's key
   - Any other paid API dashboards
5. **Rotate the age key itself:**
   - On a clean machine: `age-keygen -o ~/.config/sops/age/keys.txt.new`
   - Update `.sops.yaml` in `Monty-CNS-Secrets` to remove the old key and add the new one
   - `sops updatekeys env.sops.yaml` (for every encrypted file)
   - Commit + push
   - Move `keys.txt.new` → `keys.txt`
6. **Re-seed `env.sops.yaml` with freshly-rotated values:**
   ```bash
   sops ~/src/Monty-CNS-Secrets/env.sops.yaml
   # Replace every value with the freshly-rotated version from step 4
   ```
   Commit + push.
7. **Revoke the stolen machine's own recipient** in `.sops.yaml`:
   - Edit `.sops.yaml`, remove the line for the lost machine
   - `sops updatekeys env.sops.yaml` again (with new recipient list)
   - Commit + push
   - Now even if an attacker recovered the old age key from disk, they can't decrypt the new ciphertext

### Within 24 hours

8. **Review billing / usage dashboards** for spike detection:
   - Anthropic console → Usage
   - OpenAI platform → Usage
   - GitHub Actions minutes, any metered service
9. **Check GitHub audit log** for unauthorized actions:
   - https://github.com/settings/security-log
   - Look for: new tokens created, new SSH keys, unusual commits, settings changes
10. **File a police report** if the laptop was stolen (not just lost) — required for insurance, useful if the device is recovered, establishes a timeline.
11. **Notify your insurer** if device is covered.
12. **Buy the replacement** and run through the new-machine setup from scratch — don't try to "restore" a backup that may have been written while the machine was compromised.

### Within a week

13. **Post-mortem:** write down what happened, what you'd do differently, what controls would have helped. Update this playbook with anything you learned.

---

## Scenario B — A single credential leaked (API key in a screenshot, committed to the wrong repo, pasted in chat)

Assumption: machine is fine, just one credential is known to be exposed.

1. **Rotate the credential immediately.** Don't wait to "assess scope" — rotate, then assess.
2. **Replace in `env.sops.yaml`:** `sops ~/src/Monty-CNS-Secrets/env.sops.yaml`, replace the value, commit, push.
3. **Check for abuse.** Provider dashboards → usage logs for that key's window of exposure.
4. **If the leak was in a git repo**, rotation is enough — **don't** try to rewrite git history to remove it. The leaked value is public the moment it was pushed; history rewriting doesn't unpublish it, and it makes the trail messier for incident review. Just rotate and move on.
5. **If the leak was in a public screenshot or chat**, rotate, delete the image/message if you can, and note: deletion does not guarantee the secret is gone — assume it's permanently public and rely on rotation as the fix.

---

## Scenario C — `Monty-CNS-Secrets` repo access compromised (attacker has read access to the private repo via a stolen PAT or GitHub session)

The encrypted files are now in the attacker's hands. They need the age
private key to make them useful. If they don't have the age key,
rotation is precautionary. If they have both, treat as Scenario A.

1. **Revoke the GitHub credentials** that gave them access (PAT, SSH key, or session).
2. **Audit who has access:** https://github.com/ezmonty/Monty-CNS-Secrets/settings/access — remove any collaborators you don't recognize.
3. **Rotate every credential in `env.sops.yaml`** as in Scenario A step 4. The attacker has ciphertext; if they ever crack it, the values will be stale.
4. **Rotate the age keys**, re-key every file, commit the new ciphertext.
5. **Review git history** for commits you didn't make: `git log --all --source --remotes` on a fresh clone.

---

## Scenario D — You suspect malware is running on your machine right now

Don't use that machine to fix things. Switch to another machine or phone.

1. **Disconnect the suspected machine from the network** (airplane mode or unplug ethernet).
2. **From a clean device**, run Scenario A steps 1-6 (credential rotation, remote session revocation).
3. **Do not** log into anything sensitive from the suspected machine until it's been wiped and reinstalled from clean media.
4. **Back up nothing from the suspected machine** — backups might carry the malware.
5. **Wipe and reinstall the OS** from a known-clean installer. Not a recovery partition (which may also be compromised).
6. **Rebuild CNS from scratch** on the clean machine via the one-liner install.

---

## Scenario E — Claude Code itself or an MCP server leaked credentials

Tools evolve. If Claude Code, a sops version, or an MCP server ships a bug
that leaks env vars (in logs, error reports, crash dumps):

1. **Read the CVE / advisory** carefully — which versions, what was leaked.
2. **Rotate any credentials that the affected version had access to** — same as Scenario B, bulk.
3. **Update the affected tool** before rotating — otherwise rotation just creates new credentials to leak.
4. **Audit logs** of the affected tool for suspicious activity during the exposure window.
5. **Consider disabling** the affected tool until patched if it's mission-critical.

---

## Tools and cheat sheet

### Revocation URLs (bookmark these)

- **Anthropic:** https://console.anthropic.com/settings/keys
- **OpenAI:** https://platform.openai.com/api-keys
- **GitHub tokens:** https://github.com/settings/tokens
- **GitHub SSH:** https://github.com/settings/keys
- **GitHub sessions:** https://github.com/settings/sessions
- **GitHub audit log:** https://github.com/settings/security-log
- **Google:** https://myaccount.google.com/security
- **iCloud Find My:** https://icloud.com/find
- **1Password:** https://my.1password.com → Settings → Devices
- **Bitwarden:** https://vault.bitwarden.com → Settings → Sessions

### Commands to know

```bash
# Rotate age key (on a clean machine)
age-keygen -o ~/.config/sops/age/keys.txt.new

# Re-key every sops file for new recipient list
cd ~/src/Monty-CNS-Secrets
sops updatekeys env.sops.yaml
for f in mcp/*.sops.*; do sops updatekeys "$f"; done

# Edit (and re-encrypt) a sops file
sops env.sops.yaml

# Audit git history for suspicious commits
git log --all --source --remotes --format='%H %ai %an %s'

# Nuclear option — revoke GitHub machine access from another device
# Log into github.com, Settings → Sessions → revoke everything
```

## Practice drill — do this once, every 6 months

Schedule a calendar reminder for every 6 months to **practice the
rotation** without an actual incident:

1. Rotate your ANTHROPIC_API_KEY (just this one)
2. Update `env.sops.yaml`
3. Commit + push
4. Verify next Claude Code session picks up the new key
5. Time yourself — under 10 minutes is the goal

If the drill takes more than 10 minutes, something in the process is
broken — fix it before the real incident.

## Updating this playbook

After every near-miss, actual incident, or lessons-learned moment, update
this doc. A compromise playbook that's never been touched is usually
wrong.
