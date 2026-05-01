#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook: route prompts through Valor /secret/intake.
# Fail-closed: if intake unreachable or non-200, BLOCK the submission.
# No-op pass-through unless VALOR_INTAKE_ENABLED=true.
set -euo pipefail

# Source ~/.claude/.valor-env (mode 0600) for the API key + flag — keeps
# secrets out of settings.json (which may be world-readable).
if [[ -f "${HOME}/.claude/.valor-env" ]]; then
    # shellcheck disable=SC1091
    source "${HOME}/.claude/.valor-env"
fi

if [[ "${VALOR_INTAKE_ENABLED:-false}" != "true" ]]; then
    cat
    exit 0
fi

INTAKE_URL="${VALOR_INTAKE_URL:-https://api.remedy-reconstruction.com/api/console/secret/intake}"
API_KEY="${VALOR_API_KEY:-}"
TIMEOUT="${VALOR_INTAKE_TIMEOUT:-5}"

if [[ -z "$API_KEY" ]]; then
    echo "[secret-intake] FAIL-CLOSED: VALOR_API_KEY not set" >&2
    exit 1
fi

INPUT=$(cat)

# W4: fail-closed on malformed JSON or non-empty input that we can't
# extract a prompt from. Only pass through silently when the input
# itself is empty/whitespace (nothing to scrub).
INPUT_TRIMMED=$(printf '%s' "$INPUT" | tr -d '[:space:]')
if [[ -z "$INPUT_TRIMMED" ]]; then
    printf '%s' "$INPUT"
    exit 0
fi

PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null) || {
    echo "[secret-intake] FAIL-CLOSED: input is not valid JSON" >&2
    exit 1
}

if [[ -z "$PROMPT" ]]; then
    # Input was non-empty but had no .prompt — refuse rather than
    # forward un-scrubbed.
    echo "[secret-intake] FAIL-CLOSED: non-empty input with no .prompt field" >&2
    exit 1
fi

RESP=$(curl -fsS --max-time "$TIMEOUT" \
    -X POST "$INTAKE_URL" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" \
    -d "$(jq -n --arg p "$PROMPT" '{prompt: $p, source: "claude"}')" \
    2>&1) || { echo "[secret-intake] FAIL-CLOSED: intake unreachable or returned error: $RESP" >&2; exit 1; }

SCRUBBED=$(printf '%s' "$RESP" | jq -r '.data.prompt // empty')
if [[ -z "$SCRUBBED" ]]; then
    echo "[secret-intake] FAIL-CLOSED: malformed intake response: $RESP" >&2
    exit 1
fi

printf '%s' "$INPUT" | jq --arg p "$SCRUBBED" '.prompt = $p'
