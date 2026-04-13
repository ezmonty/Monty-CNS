#!/usr/bin/env bash
# Install.command — double-clickable Monty-CNS installer for macOS.
#
# Save this file to your Desktop (or wherever you like) and double-click.
# macOS will open Terminal.app, run this script, and walk you through the
# install. The first time you double-click a .command file, Gatekeeper may
# warn — right-click → Open instead, then it remembers.
#
# What it does:
#   1. Checks for git (offers to install Xcode Command Line Tools if missing)
#   2. Clones github.com/ezmonty/Monty-CNS into ~/src/Monty-CNS
#      (uses https; first run prompts for github auth via Keychain)
#   3. Runs install.sh, which handles bootstrap + secrets + MCP servers
#
# Why a separate file: install.sh assumes you're in a terminal already.
# This wrapper is for the "I just want to double-click an icon" case.

set -euo pipefail

REPO="https://github.com/ezmonty/Monty-CNS.git"
DIR="$HOME/src/Monty-CNS"

# Make sure we have a tty — when launched via Finder double-click, stdin
# is the .command file itself, so prompts have to come from /dev/tty.
exec </dev/tty

cat <<'BANNER'

  ┌─────────────────────────────────────────┐
  │   Monty-CNS installer                   │
  │   private dotfiles for ~/.claude        │
  └─────────────────────────────────────────┘

BANNER

# 1. Check git
if ! command -v git >/dev/null 2>&1; then
  echo "git not installed."
  echo "macOS will now offer to install the Xcode Command Line Tools."
  echo "Click 'Install', wait ~10 minutes, then double-click this file again."
  echo
  read -rp "Press ENTER to trigger the installer..."
  xcode-select --install || true
  echo
  echo "When Xcode CLT is finished, re-run this installer."
  read -rp "Press ENTER to close..."
  exit 0
fi
echo "✓ git installed"

# 2. Clone or pull
if [[ -d "$DIR/.git" ]]; then
  echo "✓ repo already cloned at $DIR — pulling latest"
  git -C "$DIR" pull --ff-only --quiet || echo "  (pull failed — using local copy)"
else
  echo "Cloning $REPO into $DIR..."
  echo "(First time: macOS Keychain will pop up to authenticate to GitHub)"
  mkdir -p "$(dirname "$DIR")"
  if ! git clone "$REPO" "$DIR"; then
    echo
    echo "✗ clone failed."
    echo "  Common fixes:"
    echo "    - Sign in to github.com in Safari first, then retry"
    echo "    - Or: brew install gh && gh auth login, then retry"
    echo "    - Or: generate a fine-grained PAT at github.com/settings/tokens"
    echo "      with read access to ezmonty/Monty-CNS, paste it as the password"
    echo
    read -rp "Press ENTER to close..."
    exit 1
  fi
fi

# 3. Hand off to install.sh
echo
echo "Handing off to install.sh..."
echo
"$DIR/install.sh"

echo
echo "Done. You can close this window."
read -rp "Press ENTER to close..."
