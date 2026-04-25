#!/usr/bin/env bash
# healthcheck.sh — Verify the full Monty-CNS stack on this machine.
set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
PASS=0; FAIL=0; SKIP=0; WARN=0
pass() { ((++PASS)) || true; printf "${GREEN}[PASS]${NC}  %s\n" "$1"; }
fail() { ((++FAIL)) || true; printf "${RED}[FAIL]${NC}  %s\n" "$1"; }
skip() { ((++SKIP)) || true; printf "${YELLOW}[SKIP]${NC}  %s\n" "$1"; }
warn() { ((++WARN)) || true; printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"

check_symlink() {
  local label="$1" path="$2"
  if [ -L "$path" ]; then
    local target; target="$(readlink -f "$path" 2>/dev/null || true)"
    if [[ "$target" == "$REPO"/* ]] && [ -e "$target" ]; then pass "$label"
    else fail "$label symlink broken or outside repo ($target)"; fi
  elif [ -e "$path" ]; then fail "$label exists but is not a symlink"
  else fail "$label missing"; fi
}

# == 1. Symlinks =============================================================
echo ""; echo "=== Symlinks ==="
check_symlink "~/.claude/settings.json" "$HOME/.claude/settings.json"
check_symlink "~/.claude/hooks/" "$HOME/.claude/hooks"
# Individual hook files live inside the hooks/ symlink — verify they exist
for _hk in session-start.sh pre-compact-checkpoint.sh post-tool-syntax-check.sh; do
  if [ -f "$HOME/.claude/hooks/$_hk" ]; then pass "~/.claude/hooks/$_hk present"
  else fail "~/.claude/hooks/$_hk missing"; fi
done
cmd_count=$(find -L "$HOME/.claude/commands" -maxdepth 1 \( -type f -o -type l \) 2>/dev/null | wc -l)
if [ "$cmd_count" -ge 20 ]; then pass "~/.claude/commands/ has $cmd_count files (>=20)"
else fail "~/.claude/commands/ has $cmd_count files (need >=20)"; fi
skill_dirs=$(find -L "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) 2>/dev/null | wc -l)
if [ "$skill_dirs" -ge 10 ]; then pass "~/.claude/skills/ has $skill_dirs dirs (>=10)"
else fail "~/.claude/skills/ has $skill_dirs dirs (need >=10)"; fi

# == 2. Hooks =================================================================
echo ""; echo "=== Hooks ==="
settings="$HOME/.claude/settings.json"
if [ ! -f "$settings" ]; then
  fail "settings.json not found"
else
  missing_hooks=()
  for hook in SessionStart PreToolUse PostToolUse PreCompact Stop; do
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert '$hook' in str(d.get('hooks',{}))" \
      "$settings" 2>/dev/null || missing_hooks+=("$hook")
  done
  if [ ${#missing_hooks[@]} -eq 0 ]; then pass "all 5 hook types registered"
  else warn "missing hooks: ${missing_hooks[*]}"; fi
fi

# == 3. Secrets ===============================================================
echo ""; echo "=== Secrets ==="
if ! command -v sops &>/dev/null; then
  skip "sops not installed — secrets checks skipped"
else
  age_key="$HOME/.config/sops/age/keys.txt"; secrets_repo="$HOME/src/Monty-CNS-Secrets"
  all_ok=true
  if [ -f "$age_key" ]; then pass "age key present"; else fail "age key not found at $age_key"; all_ok=false; fi
  if [ -d "$secrets_repo" ]; then pass "secrets repo present"; else fail "secrets repo not found"; all_ok=false; fi
  if $all_ok; then
    sf=$(find "$secrets_repo" -name '*.sops.*' -print -quit 2>/dev/null || true)
    if [ -n "$sf" ] && sops --decrypt --extract '["ANTHROPIC_API_KEY"]' "$sf" &>/dev/null; then
      pass "sops decrypt ANTHROPIC_API_KEY succeeded"
    else warn "sops decrypt ANTHROPIC_API_KEY failed or no secrets file"; fi
  fi
fi

# == 4. MCP Servers ===========================================================
echo ""; echo "=== MCP Servers ==="
if ! command -v claude &>/dev/null; then
  skip "claude CLI not available — MCP checks skipped"
else
  mcp_list=$(claude mcp list 2>/dev/null || true)
  mcp_missing=()
  for srv in github filesystem fetch memory brave-search; do
    echo "$mcp_list" | grep -qi "$srv" || mcp_missing+=("$srv")
  done
  if [ ${#mcp_missing[@]} -eq 0 ]; then pass "all 5 MCP servers registered"
  else warn "MCP servers missing: ${mcp_missing[*]}"; fi
fi

# == 5. Monty-Ledger ==========================================================
echo ""; echo "=== Monty-Ledger ==="
ledger_path=""
[ -d "$HOME/src/Monty-Ledger" ] && ledger_path="$HOME/src/Monty-Ledger"
[ -d "$REPO/monty-ledger" ] && ledger_path="$REPO/monty-ledger"
if [ -z "$ledger_path" ]; then
  skip "ledger vault not found"
else
  md_count=$(find "$ledger_path" -name '*.md' 2>/dev/null | wc -l)
  pass "ledger vault at $ledger_path ($md_count .md files)"
  if [ -n "${LEDGER_DATABASE_URL:-}" ]; then
    if psql "$LEDGER_DATABASE_URL" -c "SELECT count(*) FROM notes" &>/dev/null; then pass "ledger DB reachable"
    else warn "LEDGER_DATABASE_URL set but psql query failed"; fi
  else skip "LEDGER_DATABASE_URL not set — DB check skipped"; fi
fi

# == 6. Git State =============================================================
echo ""; echo "=== Git State ==="
cd "$REPO"
git fetch origin --quiet 2>/dev/null || true
behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "?")
if [ "$behind" = "0" ]; then pass "repo up to date with origin/main"
elif [ "$behind" = "?" ]; then warn "could not determine if repo is behind origin"
else warn "repo is $behind commit(s) behind origin/main"; fi
if git diff --quiet && git diff --cached --quiet; then pass "no uncommitted changes"
else warn "uncommitted changes present"; fi
gpgsign=$(git config commit.gpgsign 2>/dev/null || echo "false")
if [ "$gpgsign" = "true" ]; then pass "commit signing enabled"
else warn "commit signing not enabled (commit.gpgsign=$gpgsign)"; fi

# == Summary ==================================================================
TOTAL=$((PASS + FAIL + SKIP + WARN))
echo ""
echo "================================================================"
printf "  PASS: ${GREEN}%d${NC}  FAIL: ${RED}%d${NC}  WARN: ${YELLOW}%d${NC}  SKIP: ${YELLOW}%d${NC}  TOTAL: %d\n" \
  "$PASS" "$FAIL" "$WARN" "$SKIP" "$TOTAL"
echo "================================================================"
if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}Health check found failures.${NC} Fix the items above.\n"; exit 1
else
  printf "\nAll checks passed (${WARN} warning(s), ${SKIP} skipped).\n"; exit 0
fi
