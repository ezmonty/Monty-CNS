# Disk encryption — mandatory on every CNS machine

Full-disk encryption (FDE) is **the single most important security control**
on any machine that runs CNS. It protects:

- The sops ciphertext files (a stolen machine's git clone of `Monty-CNS-Secrets`)
- The age private key (`~/.config/sops/age/keys.txt`)
- Any decrypted values cached in swap or temp files
- Browser sessions, credentials, cookies, everything else on the machine

**If FDE is off and a laptop is physically stolen**, everything on disk is
readable by the attacker regardless of file permissions, regardless of
sops encryption, regardless of anything clever.

**If FDE is on** and the machine is powered off or locked when stolen, the
disk is an encrypted brick. This is the hinge on which CNS's entire threat
model rests.

## Per-OS setup

All modern operating systems include native FDE. You don't need third-party
software unless your OS edition doesn't include it (Windows Home).

### macOS — FileVault

Built in since OS X 10.3. Uses AES-256 with the Secure Enclave on Apple
Silicon Macs. TouchID / password unlock.

**Enable:**

```
System Settings → Privacy & Security → FileVault → Turn On
```

Or via CLI:

```bash
sudo fdesetup enable
```

**Verify:**

```bash
fdesetup status
# → "FileVault is On."
```

**Recovery:** during enablement, macOS asks if you want to store the
recovery key with iCloud or print/save it locally. **Print + safe** is
safest if you don't trust iCloud; **iCloud** is safest if you might forget
the key. Pick one — never skip recovery entirely.

**What it protects against:** stolen powered-off laptop, stolen asleep
laptop, disk removed and read in another machine.

**What it does NOT protect against:** unlocked running session, malware
with your user privileges.

---

### Windows — BitLocker (Pro / Enterprise) or VeraCrypt (Home)

**Windows 10/11 Pro, Enterprise, Education:** BitLocker is built-in.

**Enable:**

```
Settings → Privacy & Security → Device encryption → Turn On
```

Or via PowerShell (admin):

```powershell
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -SkipHardwareTest
```

**Verify:**

```powershell
Get-BitLockerVolume
```

**Recovery:** BitLocker generates a 48-digit recovery key during setup.
Save it to your Microsoft account, a file on a USB drive, or print it.
**Do not save it on the same drive you're encrypting.**

**Windows 10/11 Home** ships without BitLocker. Use one of:

- **Device Encryption** (a lightweight variant of BitLocker available on some Home editions with modern TPM hardware — check `Settings → Privacy & Security → Device encryption`)
- **VeraCrypt** — free, open-source, battle-tested: https://www.veracrypt.fr
  - Install, create a system partition container, boot from the VeraCrypt Rescue Disk

**Upgrading to Pro is $99 and gets you BitLocker natively** — easier than VeraCrypt for most users.

---

### Linux — LUKS

Built into every mainstream distro via `cryptsetup`. Uses AES-XTS by
default.

**At install time (strongly recommended):** most Linux installers offer
"Encrypt the new installation for security" as a checkbox in the disk
partitioning step. Turn it on. You set a passphrase, and LUKS handles the
rest.

- **Ubuntu / Mint / Pop_OS:** installer has an "Encrypt the new Ubuntu installation" checkbox during partitioning
- **Fedora:** Anaconda installer: "Encrypt my data" checkbox
- **Arch:** set up manually during `archinstall` or a custom partition step — use `cryptsetup luksFormat /dev/sdX` then `cryptsetup open`
- **NixOS:** configure `boot.initrd.luks.devices` in your `configuration.nix`

**Already installed without encryption?** On Linux, full-disk encryption
after the fact is painful — backup, wipe, reinstall with encryption on is
usually faster than `cryptsetup-reencrypt`. Plan for a couple hours.

**Verify on a running system:**

```bash
lsblk -o NAME,FSTYPE,MOUNTPOINT
# Look for "crypto_LUKS" entries
cat /proc/mounts | grep dm-crypt
```

**Recovery:** LUKS supports multiple unlock passphrases (up to 8). Add a
second one on a yubikey, print a backup, or store one in a password
manager. A single forgotten passphrase = data loss.

```bash
sudo cryptsetup luksAddKey /dev/sdX
```

---

### Chromebooks

Already encrypted by default (eCryptfs + hardware-backed key in the TPM).
No action required.

---

### WSL (Windows Subsystem for Linux)

WSL inherits the host Windows disk encryption. If your Windows volume has
BitLocker or Device Encryption enabled, your WSL filesystem is encrypted
at rest.

If you want additional protection specifically for a WSL workload (e.g. a
containerized dev environment), use LUKS inside a loopback file within
WSL — overkill for CNS in most cases.

---

### Cloud dev environments (Codespaces, Gitpod, DevPod)

The cloud provider handles disk encryption at the infrastructure layer
(EBS encryption on AWS, Persistent Disk encryption on GCP). You don't
manage it. But:

- **Credentials in a cloud dev box are owned by whoever controls the host.** For CNS use inside a codespace, the age key still gets generated and stored inside the box, but it only lives as long as the codespace does.
- For **ephemeral** codespaces, consider fetching the age key from a secret manager on session start instead of storing it in the codespace filesystem. This is the scenario where 1Password / cloud KMS integration would matter most.

---

## Lock screen settings — equally important

FDE only protects a **powered-off or rebooted** machine. A **running,
logged-in** machine is fully unlocked to anyone who walks up. Configure
auto-lock:

### macOS

```
System Settings → Lock Screen → Require password after screen saver begins: immediately
System Settings → Lock Screen → Start Screen Saver when inactive: 5 minutes (or less)
```

Optionally:

```
System Settings → Lock Screen → Show message when locked: (something identifying you, no confidential info)
```

### Windows

```
Settings → Accounts → Sign-in options → Dynamic lock: On
Settings → Personalization → Lock screen → Screen timeout: 5 minutes
```

### Linux (GNOME)

```
Settings → Privacy → Screen → Blank Screen Delay: 5 minutes
Settings → Privacy → Screen → Automatic Screen Lock: On
```

Equivalent settings exist in KDE, XFCE, Cinnamon, etc.

## Biometric unlock — convenience, not a replacement

TouchID (Mac), Windows Hello, and fingerprint readers on Linux are fine
**in addition to** a strong password. They speed up unlock; they don't
replace the password. FDE passphrase is the real key; biometrics just
proxy it for convenience.

## Recovery kit — do this once

Put somewhere you can find it later, that is **not on this laptop**:

- [ ] The FDE recovery key / passphrase
- [ ] 1Password / password manager emergency kit (if you use one)
- [ ] GitHub recovery codes (Settings → Password and authentication → Recovery codes)
- [ ] Any 2FA backup codes
- [ ] Age private key backup (encrypted, offline — see below)

Options: a USB drive in a drawer, a printed envelope in a safe, a spare
phone's secure notes, a trusted family member's copy. Pick **at least two**
recovery channels. If you lose your laptop and your recovery kit is **also**
on the laptop, you are locked out forever.

## Age key recovery

The age private key at `~/.config/sops/age/keys.txt` is **the thing that
cannot be regenerated**. If you lose it without a backup, every file
currently encrypted only to that key is unrecoverable.

Options for backing it up:

1. **Copy to a second machine.** Simplest. Both machines can decrypt. Add both public keys as recipients.
2. **Print it on paper** and store in a safe. The key is small (~70 chars). `cat ~/.config/sops/age/keys.txt | lpr`.
3. **Encrypt it with a passphrase and store the encrypted blob** somewhere cloud (Dropbox, iCloud):
   ```bash
   age -p -o ~/age-key-backup.age ~/.config/sops/age/keys.txt
   # Prompts for a strong passphrase — remember it
   ```
4. **Store in a password manager** as a secure note. Works if you trust the password manager.

**Always have at least one offline backup.** "Only backup is on another machine" is not enough — a house fire or simultaneous loss of both takes you out.
