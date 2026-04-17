#!/usr/bin/env bash
# PreCompact hook for Monty-CNS.
#
# Wired in via ~/.claude/settings.json. Runs before Claude Code compacts
# context. Writes a structured CHECKPOINT.md so the next session (or
# post-compaction context) can pick up where the previous one left off.
#
# Must NEVER block compaction -- exits 0 unconditionally.

set -uo pipefail

# Drain stdin (hook input JSON).
cat >/dev/null 2>&1 || true

# Find the git repo root. Fall back to $PWD.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "${PWD}")"

# --- Git state ---------------------------------------------------------------
branch="$(git -C "$repo_root" branch --show-current 2>/dev/null || echo "unknown")"
head_sha="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
uncommitted="$(git -C "$repo_root" status --porcelain 2>/dev/null | wc -l || echo 0)"
recent_commits="$(git -C "$repo_root" log --oneline -3 2>/dev/null || echo "(none)")"

# --- Current task (best-effort from worklogs) --------------------------------
task_status=""
for pattern in \
    "$repo_root"/docs/plans/worklogs/*.md \
    "$repo_root"/worklog/agent-*.md \
    "$repo_root"/NOTES.md; do
    # shellcheck disable=SC2086
    for f in $pattern; do
        [ -f "$f" ] || continue
        # Grab the last non-empty line that looks like a status marker.
        candidate="$(grep -E '^Status:|^## [0-9]{4}-' "$f" \
            | tail -1 2>/dev/null || true)"
        if [ -n "$candidate" ]; then
            task_status="$candidate"
            break 2
        fi
    done
done
[ -z "$task_status" ] && task_status="Unknown -- check worklog"

# --- Choose output path ------------------------------------------------------
if [ -d "$repo_root/.claude" ]; then
    out="$repo_root/.claude/CHECKPOINT.md"
elif [ -d "$repo_root/docs" ]; then
    out="$repo_root/docs/CHECKPOINT.md"
else
    out="$repo_root/CHECKPOINT.md"
fi

# --- Write checkpoint --------------------------------------------------------
timestamp="$(date -Is 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"

{
    echo "# Session Checkpoint"
    echo ""
    echo "Generated: $timestamp"
    echo "Branch: $branch"
    echo "HEAD: $head_sha"
    echo "Uncommitted changes: $uncommitted"
    echo ""
    echo "## Recent commits"
    while IFS= read -r line; do
        [ -n "$line" ] && echo "- $line"
    done <<< "$recent_commits"
    echo ""
    echo "## Current task"
    echo "$task_status"
    echo ""
    echo "## Next steps"
    echo "Review checkpoint and continue from last task"
} > "$out" 2>/dev/null || true

exit 0
