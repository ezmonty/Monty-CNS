#!/usr/bin/env bash
# Monty-CNS — one-command secrets activation.
#
# Wraps the full sops+age bootstrap into a single interactive installer.
# Idempotent — safe to re-run. Detects state at each phase and skips what
# is already done. Non-destructive — never overwrites existing keys or
# encrypted files without explicit confirmation.
#
# What it does:
#   1. Detects OS and offers to install sops + age if missing.
#   2. Generates an age keypair for this machine (only if missing).
#   3. Clones Monty-CNS-Secrets (or initializes it from the scaffold if empty).
#   4. Substitutes the real age public key into .sops.yaml placeholders.
#   5. Creates the first env.sops.yaml bundle.
#   6. Commits + pushes (on confirmation).
#   7. Runs the decrypt drop-in to verify the loop end-to-end.
#
# Usage:
#   ./activate-secrets.sh              # full interactive flow
#   ./activate-secrets.sh --yes        # assume yes to all non-destructive prompts
#   ./activate-secrets.sh --verify     # just test the drop-in, skip setup
#   ./activate-secrets.sh --status     # report current state, do nothing
#   ./activate-secrets.sh --help

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_REPO_DIR="${SECRETS_REPO:-$HOME/src/Monty-CNS-Secrets}"
AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
SCAFFOLD_DIR="$REPO_DIR/scaffold/secrets-repo"
DROPIN="$REPO_DIR/claude/hooks/session-start.d/10-decrypt-sops.sh"

YES=0
MODE=full
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=1 ;;
    --verify) MODE=verify ;;
    --status) MODE=status ;;
    -h|--help)
      sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $arg (try --help)" >&2; exit 2 ;;
  esac
done

# ---------- pretty output helpers ----------

bold()   { printf '\033[1m%s\033[0m' "$*"; }
green()  { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
red()    { printf '\033[31m%s\033[0m' "$*"; }
dim()    { printf '\033[2m%s\033[0m' "$*"; }

say()    { printf '%s\n' "$*"; }
info()   { printf '  %s %s\n' "$(dim '›')" "$*"; }
ok()     { printf '  %s %s\n' "$(green '✓')" "$*"; }
warn()   { printf '  %s %s\n' "$(yellow '!')" "$*"; }
err()    { printf '  %s %s\n' "$(red '✗')" "$*" >&2; }
step()   { printf '\n%s %s\n' "$(bold "==>")" "$(bold "$*")"; }

ask_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if [[ $YES -eq 1 ]]; then return 0; fi
  # Send prompt to stderr so it doesn't pollute any captured stdout.
  if [[ "$default" == "Y" ]]; then
    printf '%s [Y/n] ' "$prompt" >&2
  else
    printf '%s [y/N] ' "$prompt" >&2
  fi
  read -r reply || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

ask_string() {
  local prompt="$1" default="${2:-}" reply
  # Under --yes, return the default without prompting.
  if [[ $YES -eq 1 ]]; then
    printf '%s' "$default"
    return 0
  fi
  # Prompt to stderr so the captured value doesn't include the prompt text.
  if [[ -n "$default" ]]; then
    printf '%s [%s] ' "$prompt" "$default" >&2
  else
    printf '%s ' "$prompt" >&2
  fi
  read -r reply || true
  printf '%s' "${reply:-$default}"
}

# ---------- OS detection ----------

detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|linuxmint|pop) echo "debian" ;;
      fedora|rhel|centos)           echo "fedora" ;;
      arch|manjaro|endeavouros)     echo "arch" ;;
      alpine)                       echo "alpine" ;;
      *)                            echo "linux-other" ;;
    esac
  else
    echo "unknown"
  fi
}

OS="$(detect_os)"

# ---------- status report ----------

status_report() {
  step "Current state"

  if command -v sops >/dev/null 2>&1; then
    ok "sops installed ($(sops --version 2>/dev/null | head -1))"
  else
    warn "sops not installed"
  fi

  if command -v age >/dev/null 2>&1; then
    ok "age installed"
  else
    warn "age not installed"
  fi

  if [[ -r "$AGE_KEY_FILE" ]]; then
    local pubkey
    pubkey="$(grep '^# public key:' "$AGE_KEY_FILE" 2>/dev/null | awk '{print $4}')"
    ok "age key present ($AGE_KEY_FILE)"
    [[ -n "$pubkey" ]] && info "public key: $pubkey"
  else
    warn "age key missing ($AGE_KEY_FILE)"
  fi

  if [[ -d "$SECRETS_REPO_DIR/.git" ]]; then
    ok "secrets repo cloned ($SECRETS_REPO_DIR)"
    if [[ -f "$SECRETS_REPO_DIR/env.sops.yaml" ]]; then
      if grep -q 'ENC\[' "$SECRETS_REPO_DIR/env.sops.yaml" 2>/dev/null; then
        ok "env.sops.yaml present and encrypted"
      else
        warn "env.sops.yaml present but does NOT look encrypted"
      fi
    else
      warn "env.sops.yaml not created yet"
    fi
    if [[ -f "$SECRETS_REPO_DIR/.sops.yaml" ]]; then
      if grep -q 'REPLACE_ME' "$SECRETS_REPO_DIR/.sops.yaml"; then
        warn ".sops.yaml still contains REPLACE_ME placeholders"
      else
        ok ".sops.yaml configured with real recipient(s)"
      fi
    fi
  else
    warn "secrets repo not cloned at $SECRETS_REPO_DIR"
  fi

  if [[ -x "$DROPIN" ]]; then
    ok "decrypt drop-in executable"
  else
    warn "decrypt drop-in not executable"
  fi

  say
}

if [[ "$MODE" == status ]]; then
  status_report
  exit 0
fi

# ---------- verify only ----------

run_verify() {
  step "Verifying decrypt drop-in"
  if [[ ! -x "$DROPIN" ]]; then
    err "drop-in not executable: $DROPIN"
    return 1
  fi
  local tmp
  tmp="$(mktemp)"
  CLAUDE_ENV_FILE="$tmp" "$DROPIN" 2>&1 || true
  if [[ -s "$tmp" ]]; then
    local count
    count="$(grep -c '^export ' "$tmp" || true)"
    ok "drop-in exported $count variable(s) into \$CLAUDE_ENV_FILE"
    info "(contents not printed — would leak secrets)"
  else
    warn "drop-in wrote nothing to \$CLAUDE_ENV_FILE"
    info "this is expected if you haven't created env.sops.yaml yet"
  fi
  rm -f "$tmp"
}

if [[ "$MODE" == verify ]]; then
  run_verify
  exit 0
fi

# ---------- full flow ----------

header() {
  say
  say "$(bold "Monty-CNS — Secrets activation")"
  say "$(dim  "sops + age · detected OS: $OS")"
  say
}

install_tools() {
  step "Phase 1 — install sops + age"

  local need_sops=0 need_age=0
  command -v sops >/dev/null 2>&1 || need_sops=1
  command -v age  >/dev/null 2>&1 || need_age=1

  if [[ $need_sops -eq 0 && $need_age -eq 0 ]]; then
    ok "sops and age already installed"
    return 0
  fi

  say "  Missing: $([[ $need_sops -eq 1 ]] && echo -n 'sops ')$([[ $need_age -eq 1 ]] && echo -n 'age')"

  case "$OS" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        if ask_yes_no "  Install with 'brew install sops age'?" Y; then
          brew install sops age
        else
          return 1
        fi
      else
        # No Homebrew — offer direct binary download from github releases.
        # This avoids a ~5min brew install on bare Macs.
        say
        info "Homebrew not found. Two options:"
        info "  A. Install Homebrew (recommended long-term, 5 min):"
        info "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        info "  B. Download sops + age binaries directly from GitHub releases (30 sec)"
        say
        if ! ask_yes_no "  Download sops + age directly now? (needs sudo for /usr/local/bin install)" Y; then
          err "can't continue without sops + age"
          info "  Re-run after installing either option."
          return 1
        fi

        local arch
        case "$(uname -m)" in
          arm64)  arch=arm64  ;;
          x86_64) arch=amd64  ;;
          *)      err "unsupported arch: $(uname -m)"; return 1 ;;
        esac

        # Ensure /usr/local/bin exists (Apple Silicon Macs may not have it by default)
        sudo mkdir -p /usr/local/bin

        # sops — single binary from github releases
        info "downloading sops (darwin-$arch)..."
        local sops_url="https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.darwin.$arch"
        if ! curl -fsSLo /tmp/sops "$sops_url"; then
          err "sops download failed from $sops_url"
          return 1
        fi
        sudo install -m 0755 /tmp/sops /usr/local/bin/sops
        rm -f /tmp/sops
        ok "installed /usr/local/bin/sops"

        # age — tarball with age + age-keygen
        info "downloading age (darwin-$arch)..."
        local age_url="https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-darwin-$arch.tar.gz"
        if ! curl -fsSLo /tmp/age.tgz "$age_url"; then
          err "age download failed from $age_url"
          return 1
        fi
        tar -xzf /tmp/age.tgz -C /tmp
        sudo install -m 0755 /tmp/age/age        /usr/local/bin/age
        sudo install -m 0755 /tmp/age/age-keygen /usr/local/bin/age-keygen
        rm -rf /tmp/age /tmp/age.tgz
        ok "installed /usr/local/bin/age + /usr/local/bin/age-keygen"
      fi
      ;;
    debian)
      if ask_yes_no "  Install with 'sudo apt install age' and download sops binary?" Y; then
        sudo apt update && sudo apt install -y age
        # sops often isn't in apt — pull from GitHub releases
        local arch
        arch="$(uname -m)"
        case "$arch" in
          x86_64) arch=amd64 ;;
          aarch64|arm64) arch=arm64 ;;
          *) err "unsupported arch: $arch"; return 1 ;;
        esac
        local url="https://github.com/getsops/sops/releases/latest/download/sops-v3.8.1.linux.$arch"
        info "downloading sops from $url"
        curl -sSLo /tmp/sops.bin "$url"
        sudo install /tmp/sops.bin /usr/local/bin/sops
        rm -f /tmp/sops.bin
      else
        return 1
      fi
      ;;
    arch)
      if ask_yes_no "  Install with 'sudo pacman -S sops age'?" Y; then
        sudo pacman -S --needed sops age
      else
        return 1
      fi
      ;;
    fedora)
      if ask_yes_no "  Install with 'sudo dnf install sops age'?" Y; then
        sudo dnf install -y sops age
      else
        return 1
      fi
      ;;
    alpine)
      if ask_yes_no "  Install with 'sudo apk add sops age'?" Y; then
        sudo apk add sops age
      else
        return 1
      fi
      ;;
    *)
      err "automatic install not supported for OS '$OS'"
      info "install manually and re-run:"
      info "  sops: https://github.com/getsops/sops/releases"
      info "  age:  https://github.com/FiloSottile/age/releases"
      return 1
      ;;
  esac

  if command -v sops >/dev/null 2>&1 && command -v age >/dev/null 2>&1; then
    ok "sops and age installed"
  else
    err "install did not complete — check errors above"
    return 1
  fi
}

generate_key() {
  step "Phase 2 — generate this machine's age key"

  if [[ -r "$AGE_KEY_FILE" ]]; then
    ok "age key already exists at $AGE_KEY_FILE"
    return 0
  fi

  if ask_yes_no "  Generate age keypair at $AGE_KEY_FILE?" Y; then
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    age-keygen -o "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    ok "generated $AGE_KEY_FILE"
    local pubkey
    pubkey="$(grep '^# public key:' "$AGE_KEY_FILE" | awk '{print $4}')"
    info "public key: $(bold "$pubkey")"
    say
    warn "Back this file up somewhere safe."
    info "If you lose the private key, you lose access to every secret"
    info "encrypted only for this machine. Consider generating a recovery"
    info "key too and storing the private half offline (USB / paper)."
  else
    return 1
  fi
}

clone_or_init_secrets_repo() {
  step "Phase 3 — secrets repo at $SECRETS_REPO_DIR"

  if [[ -d "$SECRETS_REPO_DIR/.git" ]]; then
    ok "already cloned"
    return 0
  fi

  local default_remote="git@github.com:ezmonty/Monty-CNS-Secrets.git"
  local remote
  remote="$(ask_string "  Secrets repo remote URL:" "$default_remote")"

  mkdir -p "$(dirname "$SECRETS_REPO_DIR")"

  if git clone "$remote" "$SECRETS_REPO_DIR" 2>&1; then
    ok "cloned $remote"
  else
    warn "clone failed — the repo may be empty or not exist yet"
    if ask_yes_no "  Initialize an empty repo locally and set the remote?" Y; then
      mkdir -p "$SECRETS_REPO_DIR"
      (
        cd "$SECRETS_REPO_DIR"
        git init
        git remote add origin "$remote"
      )
      ok "initialized empty repo at $SECRETS_REPO_DIR"
    else
      return 1
    fi
  fi
}

seed_from_scaffold() {
  step "Phase 4 — seed from scaffold"

  local had_files=0
  for f in .sops.yaml README.md .gitignore env.sops.yaml.example; do
    [[ -e "$SECRETS_REPO_DIR/$f" ]] && had_files=1
  done

  if [[ $had_files -eq 0 ]]; then
    info "repo is empty — copying scaffold from $SCAFFOLD_DIR"
    cp -r "$SCAFFOLD_DIR/." "$SECRETS_REPO_DIR/"
    ok "scaffold copied"
  else
    ok "scaffold files already present"
  fi
}

substitute_pubkey() {
  step "Phase 5 — write .sops.yaml with this machine as recipient"

  local sops_yaml="$SECRETS_REPO_DIR/.sops.yaml"
  local pubkey hostname_short
  pubkey="$(grep '^# public key:' "$AGE_KEY_FILE" | awk '{print $4}')"
  hostname_short="$(hostname -s 2>/dev/null || hostname)"

  # If .sops.yaml already exists AND has no placeholders, verify this
  # machine's key is listed and return.
  if [[ -f "$sops_yaml" ]] && ! grep -q 'REPLACE_ME' "$sops_yaml"; then
    if grep -q "$pubkey" "$sops_yaml"; then
      ok "this machine is already a recipient"
      return 0
    else
      warn "placeholders already replaced, but this machine's key is NOT a recipient"
      info "add this machine from an already-working box:"
      info "  pubkey: $pubkey"
      info "  then: sops updatekeys $SECRETS_REPO_DIR/env.sops.yaml"
      return 1
    fi
  fi

  # Otherwise generate a fresh .sops.yaml from scratch. Generating is
  # simpler and safer than patching — the file gets written with exactly
  # one recipient (this machine) and no inline comments inside the bech32
  # value (sops rejects those). Add more machines later from another box.
  say
  info "generating a fresh .sops.yaml with one recipient: $hostname_short"
  info "public key: $(bold "$pubkey")"
  if ! ask_yes_no "  Overwrite .sops.yaml with this recipient?" Y; then
    return 1
  fi

  cat > "$sops_yaml" <<EOF
# sops configuration for Monty-CNS-Secrets.
#
# Recipients below can decrypt the files matching path_regex. To add
# another machine:
#   1. age-keygen on the new machine, note the public key.
#   2. Append its age1... key to both 'age:' entries below (comma-separated).
#   3. On THIS machine: sops updatekeys env.sops.yaml
#      (repeat for any files in mcp/).
#   4. Commit + push.
#
# Active recipients:
#   ${hostname_short} — ${pubkey}

creation_rules:
  - path_regex: '\.sops\.(ya?ml|json|env|toml|ini)$'
    age: ${pubkey}

  - path_regex: '\.sops\.[a-zA-Z0-9]+$'
    age: ${pubkey}
EOF

  ok "wrote $sops_yaml"
  info "current contents:"
  sed 's/^/    /' "$sops_yaml"
  say
}

create_first_bundle() {
  step "Phase 6 — create env.sops.yaml"

  local env_file="$SECRETS_REPO_DIR/env.sops.yaml"
  local example="$SECRETS_REPO_DIR/env.sops.yaml.example"

  if [[ -f "$env_file" ]]; then
    if grep -q 'ENC\[' "$env_file" 2>/dev/null; then
      ok "env.sops.yaml already exists and is encrypted"
      return 0
    else
      warn "env.sops.yaml exists but is NOT encrypted — refusing to touch"
      info "inspect manually at $env_file"
      return 1
    fi
  fi

  if [[ ! -f "$example" ]]; then
    err "env.sops.yaml.example not found — scaffold seems incomplete"
    return 1
  fi

  if ask_yes_no "  Seed env.sops.yaml from the example and encrypt it now?" Y; then
    cp "$example" "$env_file"
    (cd "$SECRETS_REPO_DIR" && sops -e -i "env.sops.yaml")
    ok "encrypted env.sops.yaml created"
    info "edit values anytime with: $(bold "sops $env_file")"
  else
    warn "skipping env.sops.yaml creation"
    info "you can create it later with: $(bold "sops $env_file")"
  fi
}

commit_and_push() {
  step "Phase 7 — commit + push"

  (
    cd "$SECRETS_REPO_DIR"

    if [[ -z "$(git status --porcelain)" ]]; then
      ok "nothing to commit"
      return 0
    fi

    git add .
    say "  pending changes:"
    git status --short | sed 's/^/    /'
    say

    local hostname_short
    hostname_short="$(hostname -s 2>/dev/null || hostname)"

    if ask_yes_no "  Commit these changes?" Y; then
      git commit -m "activate secrets on $hostname_short"
      ok "committed"
    else
      warn "skipped commit"
      return 0
    fi

    if ask_yes_no "  Push to origin?" Y; then
      # Figure out the default branch — main or master
      local branch
      branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"
      if git push -u origin "$branch" 2>&1; then
        ok "pushed to origin/$branch"
      else
        warn "push failed — resolve manually, then re-run --verify"
      fi
    else
      warn "skipped push"
    fi
  )
}

# ---------- orchestrate ----------

header
status_report

say "$(bold "About to run:")"
say "  1. Install sops + age (if missing)"
say "  2. Generate age key (if missing)"
say "  3. Clone or initialize $SECRETS_REPO_DIR"
say "  4. Seed from scaffold (if empty)"
say "  5. Substitute your public key into .sops.yaml"
say "  6. Create encrypted env.sops.yaml"
say "  7. Commit + push"
say "  8. Verify the decrypt drop-in"
say

if ! ask_yes_no "Proceed?" Y; then
  say "Aborted. Nothing changed."
  exit 0
fi

install_tools
generate_key
clone_or_init_secrets_repo
seed_from_scaffold
substitute_pubkey
create_first_bundle
commit_and_push
run_verify

step "Done"
ok "Secrets are active on this machine."
say
say "Next steps:"
say "  · Edit any value:    $(bold "sops $SECRETS_REPO_DIR/env.sops.yaml")"
say "  · Add a file secret: $(bold "sops $SECRETS_REPO_DIR/mcp/<name>.sops.<ext>")"
say "  · Add another box:   run this script there, then re-key from here"
say "  · Check the log:     $(bold "tail ~/.claude/logs/session-start.log")"
say
say "Start a fresh Claude Code session to confirm secrets flow into \$CLAUDE_ENV_FILE."
say
exit 0
