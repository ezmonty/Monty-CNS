#!/usr/bin/env bash
# Monty-CNS bootstrap: symlink tracked files from this repo into ~/.claude
#
# Usage:
#   ./bootstrap.sh              # install symlinks, backing up any conflicts
#   ./bootstrap.sh --dry-run    # show what would happen
#   ./bootstrap.sh --force      # overwrite without prompting
#   ./bootstrap.sh --unlink     # remove repo-owned symlinks from ~/.claude
#
# Design notes:
#   - We symlink leaf entries (files and top-level dirs) from ./claude/ into
#     ~/.claude/. Top-level dir symlinks keep things simple and let git own
#     the subtree, at the cost of not letting you mix tracked and untracked
#     files inside the same tracked dir. For directories where you need that
#     mix (e.g. skills/), create the leaf files individually in this repo
#     instead of relying on a dir symlink — see docs/self-hosting.md.
#   - Never touches secrets or session data (see .gitignore).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/claude"
DEST_DIR="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP_DIR="$DEST_DIR/backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
FORCE=0
UNLINK=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --unlink)  UNLINK=1 ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then say "DRY: $*"; else eval "$@"; fi; }

if [[ ! -d "$SRC_DIR" ]]; then
  echo "error: $SRC_DIR does not exist" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# Iterate tracked top-level entries under claude/
shopt -s nullglob dotglob
entries=("$SRC_DIR"/*)
shopt -u dotglob

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "nothing to install in $SRC_DIR" >&2
  exit 0
fi

for src in "${entries[@]}"; do
  name="$(basename "$src")"
  # Skip .gitkeep sentinels — the directories they live in are created via
  # the dir symlink itself.
  [[ "$name" == ".gitkeep" ]] && continue
  dest="$DEST_DIR/$name"

  if [[ $UNLINK -eq 1 ]]; then
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
      say "unlink $dest"
      run "rm '$dest'"
    fi
    continue
  fi

  # Already correctly linked? nothing to do.
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    say "ok    $dest -> $src"
    continue
  fi

  # Conflict: back up then replace.
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ $FORCE -eq 0 ]]; then
      say "backup $dest -> $BACKUP_DIR/"
    fi
    run "mkdir -p '$BACKUP_DIR'"
    run "mv '$dest' '$BACKUP_DIR/'"
  fi

  say "link  $dest -> $src"
  run "ln -s '$src' '$dest'"
done

# Make sure tracked scripts are executable in the repo (symlinks inherit).
if [[ $UNLINK -eq 0 ]]; then
  while IFS= read -r -d '' f; do
    if [[ ! -x "$f" ]]; then
      run "chmod +x '$f'"
    fi
  done < <(find "$SRC_DIR" -type f -name '*.sh' -print0)
fi

say
say "done. CLAUDE_HOME=$DEST_DIR"
if [[ $DRY_RUN -eq 1 ]]; then
  say "(dry run — nothing actually changed)"
fi

exit 0
