#!/usr/bin/env bash
# Monty-CNS one-line new-machine installer.
#
# Run from anywhere:
#   curl -fsSL https://raw.githubusercontent.com/ezmonty/Monty-CNS/main/install.sh | bash
#
# Or review first (recommended — curl|bash is a security smell):
#   curl -fsSL https://raw.githubusercontent.com/ezmonty/Monty-CNS/main/install.sh -o /tmp/monty-cns-install.sh
#   less /tmp/monty-cns-install.sh    # read what it's going to do
#   bash /tmp/monty-cns-install.sh
#
# Or fully manual — clone and run locally:
#   git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS
#   ~/src/Monty-CNS/install.sh
#
# Environment overrides (optional):
#   MONTY_CNS_DIR=/path/to/clone      (default: $HOME/src/Monty-CNS)
#   MONTY_CNS_REPO=<git url>          (default: https://github.com/ezmonty/Monty-CNS.git)
#   MONTY_CNS_BRANCH=<branch>         (default: main)
#   MONTY_CNS_YES=1                   (unattended: skip every prompt, assume yes)
#   MONTY_CNS_NO_SECRETS=1            (skip the activate-secrets phase)
#   MONTY_CNS_NO_MCP=1                (skip the MCP servers phase)
#
# What this script does NOT do:
#   - sudo anything without asking
#   - overwrite existing files without moving them to backups/
#   - fetch anything from outside github.com/ezmonty
#   - install Claude Code itself (you need the `claude` CLI before MCP setup works)

set -euo pipefail

REPO="${MONTY_CNS_REPO:-https://github.com/ezmonty/Monty-CNS.git}"
DIR="${MONTY_CNS_DIR:-$HOME/src/Monty-CNS}"
BRANCH="${MONTY_CNS_BRANCH:-main}"
YES="${MONTY_CNS_YES:-0}"
NO_SECRETS="${MONTY_CNS_NO_SECRETS:-0}"
NO_MCP="${MONTY_CNS_NO_MCP:-0}"

# ---------- pretty output ----------

bold()   { printf '\033[1m%s\033[0m' "$*"; }
green()  { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
red()    { printf '\033[31m%s\033[0m' "$*"; }
dim()    { printf '\033[2m%s\033[0m' "$*"; }

say()  { printf '%s\n' "$*"; }
info() { printf '  %s %s\n' "$(dim '›')" "$*"; }
ok()   { printf '  %s %s\n' "$(green '✓')" "$*"; }
warn() { printf '  %s %s\n' "$(yellow '!')" "$*"; }
err()  { printf '  %s %s\n' "$(red '✗')" "$*" >&2; }
step() { printf '\n%s %s\n' "$(bold "==>")" "$(bold "$*")"; }

# ---------- interactive input (works under curl|bash) ----------

# When piped via curl|bash, stdin is the script itself, so read would
# consume script content instead of user input. Read from /dev/tty in
# that case so prompts actually reach the user.
if [[ -t 0 ]]; then
  TTY_IN=/dev/stdin
elif [[ -r /dev/tty ]]; then
  TTY_IN=/dev/tty
else
  TTY_IN=/dev/null
fi

ask_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if [[ "$YES" == "1" ]]; then return 0; fi
  if [[ "$TTY_IN" == "/dev/null" ]]; then
    # No tty and not --yes — fall back to the default so we don't deadlock.
    [[ "$default" == "Y" ]]
    return
  fi
  if [[ "$default" == "Y" ]]; then
    printf '%s [Y/n] ' "$prompt" >&2
  else
    printf '%s [y/N] ' "$prompt" >&2
  fi
  read -r reply <"$TTY_IN" || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

# ---------- intro banner ----------

say
say "$(bold "Monty-CNS — one-command installer")"
say "$(dim  "repo: $REPO  branch: $BRANCH  dest: $DIR")"
say

if [[ "$YES" != "1" ]]; then
  say "This script will:"
  say "  1. Check for git + dev tools"
  say "  2. Clone $REPO to $DIR (or pull if it already exists)"
  say "  3. Run bootstrap.sh (symlinks into ~/.claude)"
  [[ "$NO_SECRETS" != "1" ]] && say "  4. Offer to activate secrets (sops + age)"
  [[ "$NO_MCP"     != "1" ]] && say "  5. Offer to install tracked MCP servers"
  say "  6. Report next steps"
  say
  if ! ask_yes_no "Proceed?" Y; then
    say "Aborted. Nothing changed."
    exit 0
  fi
fi

# ---------- phase 1: preflight ----------

step "Phase 1 — preflight"

OS_NAME="$(uname)"
case "$OS_NAME" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)      OS="other" ;;
esac
ok "detected OS: $OS ($OS_NAME)"

if ! command -v git >/dev/null 2>&1; then
  err "git not found"
  if [[ "$OS" == "macos" ]]; then
    info "On macOS, install Xcode Command Line Tools:"
    info "  $(bold "xcode-select --install")"
    info "That will install git (among other dev tools). Then re-run this script."
  else
    info "Install git via your package manager, then re-run this script."
  fi
  exit 1
fi
ok "git: $(git --version)"

if ! command -v curl >/dev/null 2>&1; then
  warn "curl not found — the sops install step may fail on Debian/Ubuntu"
fi

# ---------- phase 2: clone or update ----------

step "Phase 2 — clone or update repo"

if [[ -d "$DIR/.git" ]]; then
  info "repo already present at $DIR"
  (
    cd "$DIR"
    git fetch --quiet origin
    # Switch to the requested branch, pulling if it's already the current one.
    current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo DETACHED)"
    if [[ "$current_branch" != "$BRANCH" ]]; then
      info "switching from $current_branch to $BRANCH"
      git checkout "$BRANCH"
    fi
    if git rev-parse --verify --quiet "origin/$BRANCH" >/dev/null; then
      git merge --ff-only "origin/$BRANCH" || warn "fast-forward failed (local has diverged)"
    fi
  )
  ok "updated"
else
  info "cloning $REPO to $DIR"
  mkdir -p "$(dirname "$DIR")"
  if git clone --branch "$BRANCH" "$REPO" "$DIR" 2>&1; then
    ok "cloned"
  else
    err "clone failed"
    info "If the repo is private, make sure your git credentials are set up"
    info "(HTTPS: personal access token in your credential manager; SSH: key added to ssh-agent)."
    exit 1
  fi
fi

# ---------- phase 3: bootstrap ----------

step "Phase 3 — bootstrap symlinks"

if [[ ! -x "$DIR/bootstrap.sh" ]]; then
  err "bootstrap.sh not found or not executable at $DIR/bootstrap.sh"
  exit 1
fi

"$DIR/bootstrap.sh"

# ---------- phase 4: activate secrets (optional) ----------

if [[ "$NO_SECRETS" != "1" ]]; then
  step "Phase 4 — secrets activation (sops + age)"

  if [[ ! -x "$DIR/activate-secrets.sh" ]]; then
    warn "activate-secrets.sh not found — skipping"
  else
    say "  This will install sops + age (asking before using your package manager),"
    say "  generate a machine-local age key, clone or initialize Monty-CNS-Secrets,"
    say "  seed the encrypted env bundle, and verify the decrypt loop."
    say
    if ask_yes_no "  Run activate-secrets.sh now?" Y; then
      if [[ "$YES" == "1" ]]; then
        "$DIR/activate-secrets.sh" --yes
      else
        "$DIR/activate-secrets.sh"
      fi
    else
      info "skipped. Run later with: $(bold "$DIR/activate-secrets.sh")"
    fi
  fi
else
  info "secrets phase skipped (MONTY_CNS_NO_SECRETS=1)"
fi

# ---------- phase 5: install MCP servers (optional) ----------

if [[ "$NO_MCP" != "1" ]]; then
  step "Phase 5 — MCP server installation"

  if [[ ! -x "$DIR/claude/mcp/install-servers.sh" ]]; then
    warn "install-servers.sh not found — skipping"
  elif ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found — skipping MCP install"
    info "Install Claude Code first: https://claude.com/product/claude-code"
    info "Then run: $(bold "~/.claude/mcp/install-servers.sh")"
  elif ! command -v jq >/dev/null 2>&1; then
    warn "jq not found — skipping MCP install"
    case "$OS" in
      macos) info "Install with: $(bold "brew install jq")" ;;
      linux) info "Install with: $(bold "sudo apt install jq")  (or pacman/dnf/apk)" ;;
    esac
    info "Then run: $(bold "~/.claude/mcp/install-servers.sh")"
  else
    if ask_yes_no "  Install tracked MCP servers (github/filesystem/fetch)?" Y; then
      "$DIR/claude/mcp/install-servers.sh"
    else
      info "skipped. Run later with: $(bold "~/.claude/mcp/install-servers.sh")"
    fi
  fi
else
  info "MCP phase skipped (MONTY_CNS_NO_MCP=1)"
fi

# ---------- phase 6: done ----------

step "Done"

ok "Monty-CNS installed at $DIR"
say
say "$(bold "Next steps:")"
say "  · Start a fresh Claude Code session — settings, hooks, skills, commands load automatically."
say "  · Check the session log: $(bold "tail ~/.claude/logs/session-start.log")"
say "  · Update anytime:       $(bold "cd $DIR && git pull && ./bootstrap.sh")"
say "  · Re-run any phase independently:"
say "      $(bold "$DIR/bootstrap.sh")              # sync symlinks"
say "      $(bold "$DIR/activate-secrets.sh")        # manage secrets"
say "      $(bold "~/.claude/mcp/install-servers.sh") # manage MCP servers"
say
say "$(bold "Docs:")"
say "  · $(bold "$DIR/README.md")"
say "  · $(bold "$DIR/docs/secrets-setup.md")   (sops + age walkthrough)"
say "  · $(bold "$DIR/docs/self-hosting.md")    (run your own git remote)"
say

exit 0
