#!/usr/bin/env bash
# phase-0-checklist.sh — Verify phase-0 exit criteria for the Valor GitHub Integration plan.
# Reference: docs/plans/valor-github-integration.md, section "Phase 0 — Foundations"
set -euo pipefail

# -- Colors ------------------------------------------------------------------
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

PASS=0; FAIL=0; SKIP=0; MANUAL=0

pass()  { ((PASS++));   printf "${GREEN}[PASS]${NC}  %s\n" "$1"; }
fail()  { ((FAIL++));   printf "${RED}[FAIL]${NC}  %s\n" "$1"; }
skip()  { ((SKIP++));   printf "${YELLOW}[SKIP]${NC}  %s\n" "$1"; }
manual(){ ((MANUAL++)); printf "${YELLOW}[MANUAL]${NC} %s\n" "$1"; }

WORKLOG="docs/plans/worklogs/valor-github-integration.md"
SECRETS_FILE="secrets/valor-github-app.sops.yaml"
WEBHOOK_URLS=("http://localhost:8000/gh-hook" "https://webhook.valor.tail-xxxx.ts.net/gh-hook")

# -- 1. sops secrets (Milestone 2: private key in sops+age) -------------------
echo ""
echo "=== sops secrets ==="
if ! command -v sops &>/dev/null; then
  skip "sops CLI not installed — cannot verify ${SECRETS_FILE}"
elif [ ! -f "$SECRETS_FILE" ]; then
  fail "secrets file not found: ${SECRETS_FILE}"
else
  sops_ok=true
  for field in private_key app_id webhook_secret installation_id; do
    val=$(sops --decrypt --extract "[\"${field}\"]" "$SECRETS_FILE" 2>/dev/null) || val=""
    if [ -z "$val" ]; then
      fail "sops field '${field}' missing or empty in ${SECRETS_FILE}"
      sops_ok=false
    fi
  done
  if $sops_ok; then
    pass "all 4 required fields present in ${SECRETS_FILE}"
  fi
fi

# -- 2. Private key gate (C4 amendment) — CRITICAL ----------------------------
echo ""
echo "=== Private key gate (C4 amendment) ==="
pem_matches=$(find ~/ -maxdepth 4 -name '*.pem' ! -path '*/node_modules/*' ! -path '*/.cache/*' 2>/dev/null | grep -i valor || true)
if [ -n "$pem_matches" ]; then
  fail "CRITICAL — valor .pem file(s) found on disk (shred immediately):"
  echo "$pem_matches" | while read -r f; do printf "       %s\n" "$f"; done
else
  pass "no valor .pem files found under \$HOME"
fi

# -- 3. Worklog entry: phase-0-verification-complete --------------------------
echo ""
echo "=== Worklog entry ==="
if [ ! -f "$WORKLOG" ]; then
  fail "worklog file not found: ${WORKLOG}"
elif grep -q "phase-0-verification-complete" "$WORKLOG"; then
  pass "worklog contains 'phase-0-verification-complete'"
else
  fail "worklog exists but missing entry 'phase-0-verification-complete'"
fi

# -- 4. No phase-1 branches ---------------------------------------------------
echo ""
echo "=== Branch check (no phase-1 work yet) ==="
phase1_branches=$(git branch -a 2>/dev/null | grep -E 'phase-1|phase.1' || true)
if [ -n "$phase1_branches" ]; then
  fail "phase-1 branch(es) found — no code should exist on these yet:"
  echo "$phase1_branches" | while read -r b; do printf "       %s\n" "$b"; done
else
  pass "no phase-1 branches exist (local or remote)"
fi

# -- 5. Webhook health check (Milestone 3: receiver returns 200) --------------
echo ""
echo "=== Webhook endpoint health check ==="
webhook_checked=false
for url in "${WEBHOOK_URLS[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
    -H "Content-Type: application/json" \
    -H "X-GitHub-Event: ping" \
    -H "X-GitHub-Delivery: 00000000-0000-0000-0000-000000000000" \
    -d '{"zen":"phase-0 checklist probe"}' \
    --connect-timeout 3 --max-time 5 \
    "$url" 2>/dev/null) || code="000"
  if [ "$code" = "200" ]; then
    pass "webhook endpoint returned 200 at ${url}"
    webhook_checked=true
    break
  fi
done
if ! $webhook_checked; then
  skip "webhook endpoint not reachable at any known URL"
fi

# -- 6. Manual verification prompts -------------------------------------------
echo ""
echo "=== Manual checks (human must verify) ==="
manual "Milestone 1: App registered in GitHub, permissions set, installed on sandbox repo"
manual "Milestone 4: X-GitHub-Delivery UUID from 'Recent Deliveries' matches Valor server logs"
manual "Redeliver test: clicked 'Redeliver' in GitHub UI and confirmed duplicate arrived"

# -- Summary ------------------------------------------------------------------
TOTAL=$((PASS + FAIL + SKIP + MANUAL))
echo ""
echo "================================================================"
printf "  PASSED: ${GREEN}%d${NC}   FAILED: ${RED}%d${NC}   SKIPPED: ${YELLOW}%d${NC}   MANUAL: ${YELLOW}%d${NC}   TOTAL: %d\n" \
  "$PASS" "$FAIL" "$SKIP" "$MANUAL" "$TOTAL"
echo "================================================================"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}Phase 0 exit criteria NOT met.${NC} Fix failures above before proceeding.\n"
  exit 1
else
  printf "\nAll automated checks passed. Complete the manual checks above to confirm phase 0.\n"
  exit 0
fi
