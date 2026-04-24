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
  echo "==> installing sops + age (direct binary from GitHub releases)"

  local kernel arch
  kernel="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$(uname -m)" in
    x86_64)        arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "unsupported arch: $(uname -m)" >&2; return 1 ;;
  esac
  case "$kernel" in
    linux|darwin) ;;
    *) echo "unsupported kernel: $kernel — run ./activate-secrets.sh instead" >&2; return 1 ;;
  esac

  local prefix
  if [[ -w /usr/local/bin ]]; then
    prefix=/usr/local/bin
  elif command -v sudo >/dev/null; then
    prefix=/usr/local/bin
    local SUDO=sudo
  else
    prefix="$HOME/.local/bin"
    mkdir -p "$prefix"
  fi
  local SUDO="${SUDO:-}"

  if ! command -v sops >/dev/null; then
    echo "   downloading sops ($kernel-$arch)..."
    curl -fsSLo /tmp/sops "https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.$kernel.$arch"
    $SUDO install -m 0755 /tmp/sops "$prefix/sops"
    rm -f /tmp/sops
  fi

  if ! command -v age >/dev/null; then
    echo "   downloading age ($kernel-$arch)..."
    curl -fsSLo /tmp/age.tgz "https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-$kernel-$arch.tar.gz"
    tar -xzf /tmp/age.tgz -C /tmp
    $SUDO install -m 0755 /tmp/age/age        "$prefix/age"
    $SUDO install -m 0755 /tmp/age/age-keygen "$prefix/age-keygen"
    rm -rf /tmp/age /tmp/age.tgz
  fi

  export PATH="$prefix:$PATH"
  command -v sops >/dev/null && command -v age >/dev/null || {
    echo "install failed" >&2; return 1;
  }
  echo "   installed: sops $(sops --version | head -1 | awk '{print $2}'), age at $(command -v age)"
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
