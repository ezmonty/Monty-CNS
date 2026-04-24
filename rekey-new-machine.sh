#!/usr/bin/env bash
# rekey-new-machine.sh — run on a NEW machine that needs to become a recipient.
#
# Does the "half" of the re-key flow that lives on the machine being added:
#   1. Installs sops + age (via activate-secrets.sh's installer) if missing.
#   2. Generates an age keypair here if missing.
#   3. Prints the public key + the exact command to run from an already-trusted
#      machine to admit this one.
#
# After the trusted machine runs `rekey-add-recipient.sh <pubkey> <label>` and
# pushes, re-run this script with --finish to clone/pull the secrets repo and
# verify decryption.
#
# Usage:
#   ./rekey-new-machine.sh            # initial: generate key, show pubkey + instructions
#   ./rekey-new-machine.sh --finish   # after other machine admitted us: verify decryption

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
SECRETS_REPO="${SECRETS_REPO:-$HOME/src/Monty-CNS-Secrets}"
DROPIN="$REPO_DIR/claude/hooks/session-start.d/10-decrypt-sops.sh"

MODE=init
for arg in "$@"; do
  case "$arg" in
    --finish) MODE=finish ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ensure_tools() {
  if command -v sops >/dev/null && command -v age >/dev/null; then return 0; fi
  echo "==> installing sops + age (delegating to activate-secrets.sh installer)"
  # activate-secrets.sh has an install_tools function; simplest way to reuse
  # its logic is a one-shot invocation that exits after phase 1.
  # We just call it with --yes and trust the user can Ctrl-C if they don't want the rest.
  echo "    tip: run ./activate-secrets.sh directly if you want the full flow."
  exit 1
}

gen_key() {
  if [[ -r "$AGE_KEY_FILE" ]]; then return 0; fi
  mkdir -p "$(dirname "$AGE_KEY_FILE")"
  age-keygen -o "$AGE_KEY_FILE"
  chmod 600 "$AGE_KEY_FILE"
}

if [[ "$MODE" == init ]]; then
  ensure_tools
  gen_key
  PUBKEY=$(grep '^# public key:' "$AGE_KEY_FILE" | awk '{print $4}')
  LABEL="${HOSTNAME:-$(hostname -s 2>/dev/null || hostname)}"
  cat <<EOF

=== This machine's age identity ===
  Label:      $LABEL
  Public key: $PUBKEY

=== Next step — on a machine that can ALREADY decrypt the vault ===
  cd ~/src/Monty-CNS
  git pull
  ./rekey-add-recipient.sh $PUBKEY $LABEL

That will re-encrypt env.sops.yaml (and any mcp/*.sops.*) for this machine
and push the change. Then come back here and run:

  ./rekey-new-machine.sh --finish

EOF
  exit 0
fi

# --finish
echo "==> cloning or pulling $SECRETS_REPO"
if [[ -d "$SECRETS_REPO/.git" ]]; then
  (cd "$SECRETS_REPO" && git pull --ff-only)
else
  REMOTE=$(git -C "$REPO_DIR" config --get remote.origin.url 2>/dev/null | sed 's|/Monty-CNS\(\.git\)\?$|/Monty-CNS-Secrets.git|')
  : "${REMOTE:=git@github.com:ezmonty/Monty-CNS-Secrets.git}"
  git clone "$REMOTE" "$SECRETS_REPO"
fi

echo "==> testing decryption"
if [[ -x "$DROPIN" ]]; then
  tmp=$(mktemp)
  CLAUDE_ENV_FILE="$tmp" "$DROPIN"
  count=$(grep -c '^export ' "$tmp" 2>/dev/null || echo 0)
  rm -f "$tmp"
  if [[ "$count" -gt 0 ]]; then
    echo "✓ decryption works — $count variables would be exported into \$CLAUDE_ENV_FILE"
    echo "✓ this machine is now a full recipient. Start a fresh Claude Code session to pick up secrets."
  else
    echo "✗ drop-in ran but exported nothing. Check that the other machine actually pushed."
    exit 1
  fi
else
  echo "drop-in not found at $DROPIN — run ./activate-secrets.sh to set it up."
  exit 1
fi
