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
#   - Top-level files in claude/ become file symlinks in ~/.claude.
#   - Top-level dirs in claude/ become dir symlinks in ~/.claude, UNLESS
#     the destination already exists as a real directory — in which case
#     we recurse and symlink the children individually. This "merge mode"
#     lets us add tracked skills alongside host-provided or machine-local
#     skills without blowing them away.
#   - Conflicts are moved to ~/.claude/backups/<timestamp>/, never deleted.
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
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }
run() { if [[ $DRY_RUN -eq 1 ]]; then say "DRY: $*"; else eval "$@"; fi; }

backup_once() {
  # Create the backup dir lazily so we don't leave an empty one behind
  # when nothing conflicts.
  if [[ $DRY_RUN -eq 0 && ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi
}

# install_entry <src> <dest>
# - If src is a file, symlink dest -> src.
# - If src is a directory and dest doesn't exist or is already the correct
#   symlink, symlink the whole dir.
# - If src is a directory and dest exists as a real directory, merge:
#   ensure dest is a dir, then recurse on each child of src.
install_entry() {
  local src="$1" dest="$2"
  local name
  name="$(basename "$src")"

  # Skip .gitkeep sentinels — they only exist to let git track empty dirs.
  [[ "$name" == ".gitkeep" ]] && return 0

  # Already correctly linked?
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    say "ok    $dest -> $src"
    return 0
  fi

  # Merge mode: src is a dir, dest is an existing real dir (not a symlink).
  if [[ -d "$src" && -d "$dest" && ! -L "$dest" ]]; then
    say "merge $dest/ (recursing into $name/)"
    local child
    shopt -s nullglob dotglob
    local children=("$src"/*)
    shopt -u dotglob
    for child in "${children[@]}"; do
      install_entry "$child" "$dest/$(basename "$child")"
    done
    return 0
  fi

  # Conflict: back up then replace.
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_once
    say "backup $dest -> $BACKUP_DIR/"
    run "mv '$dest' '$BACKUP_DIR/'"
  fi

  # Ensure parent dir exists (needed for recursive merges).
  local parent
  parent="$(dirname "$dest")"
  if [[ ! -d "$parent" ]]; then
    run "mkdir -p '$parent'"
  fi

  say "link  $dest -> $src"
  run "ln -s '$src' '$dest'"
}

# uninstall_entry <src> <dest>
# Mirror of install_entry for --unlink: removes any symlink that points
# back into this repo. Leaves real files/dirs alone.
uninstall_entry() {
  local src="$1" dest="$2"
  local name
  name="$(basename "$src")"
  [[ "$name" == ".gitkeep" ]] && return 0

  # Exact symlink into the repo: remove it.
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    say "unlink $dest"
    run "rm '$dest'"
    return 0
  fi

  # Merge mode dir: recurse.
  if [[ -d "$src" && -d "$dest" && ! -L "$dest" ]]; then
    local child
    shopt -s nullglob dotglob
    local children=("$src"/*)
    shopt -u dotglob
    for child in "${children[@]}"; do
      uninstall_entry "$child" "$dest/$(basename "$child")"
    done
    # Clean up empty directories we created under dest.
    if [[ -d "$dest" ]] && [[ -z "$(ls -A "$dest" 2>/dev/null)" ]]; then
      run "rmdir '$dest'"
    fi
    return 0
  fi
}

if [[ ! -d "$SRC_DIR" ]]; then
  echo "error: $SRC_DIR does not exist" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

shopt -s nullglob dotglob
entries=("$SRC_DIR"/*)
shopt -u dotglob

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "nothing to install in $SRC_DIR" >&2
  exit 0
fi

for src in "${entries[@]}"; do
  name="$(basename "$src")"
  dest="$DEST_DIR/$name"
  if [[ $UNLINK -eq 1 ]]; then
    uninstall_entry "$src" "$dest"
  else
    install_entry "$src" "$dest"
  fi
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
