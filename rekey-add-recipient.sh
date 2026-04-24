#!/usr/bin/env bash
# rekey-add-recipient.sh — run on a machine that CAN already decrypt the vault.
#
# Adds a new machine's age public key as a recipient to Monty-CNS-Secrets,
# re-encrypts every sops file, commits, and pushes.
#
# Usage:
#   ./rekey-add-recipient.sh <new-pubkey> <label>
#
# Example:
#   ./rekey-add-recipient.sh age1abc...xyz oracle-vm
#
# The <label> is a human hint written as a comment in .sops.yaml (e.g. the
# hostname of the machine being added). It does not affect decryption.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <age1...pubkey> <label>" >&2
  exit 2
fi

NEW_PUBKEY="$1"
LABEL="$2"

if [[ ! "$NEW_PUBKEY" =~ ^age1[a-z0-9]+$ ]]; then
  echo "error: first arg does not look like an age public key (age1...)" >&2
  exit 2
fi

SECRETS_REPO="${SECRETS_REPO:-$HOME/src/Monty-CNS-Secrets}"
SOPS_YAML="$SECRETS_REPO/.sops.yaml"

if [[ ! -f "$SOPS_YAML" ]]; then
  echo "error: no .sops.yaml at $SOPS_YAML — is the secrets repo cloned?" >&2
  exit 1
fi

if grep -q "$NEW_PUBKEY" "$SOPS_YAML"; then
  echo "already a recipient: $NEW_PUBKEY" >&2
  exit 0
fi

# Extract current recipients (first matching age: line), append new one comma-separated.
current=$(grep -m1 '^\s*age:\s' "$SOPS_YAML" | sed 's/.*age:\s*//; s/\s*$//')
if [[ -z "$current" ]]; then
  echo "error: couldn't parse existing 'age:' line in $SOPS_YAML" >&2
  exit 1
fi
combined="${current},${NEW_PUBKEY}"

echo "==> adding '$LABEL' ($NEW_PUBKEY) to .sops.yaml"
# Replace every age: line and insert a recipient comment near the top.
python3 - "$SOPS_YAML" "$current" "$combined" "$LABEL" "$NEW_PUBKEY" <<'PY'
import sys, re, pathlib
path, old, new, label, pubkey = sys.argv[1:]
p = pathlib.Path(path)
text = p.read_text()
# Replace every occurrence of the old recipient list after 'age:' with the new one.
# Safe because sops.yaml uses the same recipients in every creation_rule.
text = re.sub(r'(^(\s*age:\s*)).*$',
              lambda m: m.group(1) + new,
              text, flags=re.MULTILINE)
# Insert a recipient comment under "Active recipients:" if present.
marker = "# Active recipients:"
if marker in text and label not in text:
    text = text.replace(
        marker,
        f"{marker}\n#   {label} — {pubkey}",
        1,
    )
p.write_text(text)
PY

echo "==> re-encrypting every sops file"
cd "$SECRETS_REPO"
# Find all encrypted files: anything matching .sops.* or named env.sops.yaml etc.
mapfile -t FILES < <(git ls-files | grep -E '(^|/)(env\.sops\.[^.]+|.*\.sops\.[^.]+)$' || true)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "   (no sops files found to re-key)"
else
  for f in "${FILES[@]}"; do
    echo "   sops updatekeys -y $f"
    sops updatekeys -y "$f"
  done
fi

echo "==> committing + pushing"
git add .sops.yaml "${FILES[@]}" 2>/dev/null || git add .sops.yaml
if git diff --cached --quiet; then
  echo "   nothing to commit"
else
  git commit -m "secrets: add recipient $LABEL"
  git push
  echo "==> pushed."
fi

echo
echo "Done. The machine with pubkey $NEW_PUBKEY can now:"
echo "  1. git pull in $SECRETS_REPO"
echo "  2. run ./activate-secrets.sh --verify to confirm decryption works"
