#!/usr/bin/env bash
# PostToolUse hook: syntax-check after Edit/Write
# Warns on error (exit 0 always — PostToolUse cannot block).
set -uo pipefail

file=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null) || exit 0
[[ -z "$file" || ! -f "$file" ]] && exit 0

ext="${file##*.}"
rc=0
has() { command -v "$1" &>/dev/null; }

case ".$ext" in
  .py)  out=$(timeout 3 python3 -m py_compile "$file" 2>&1) || rc=$? ;;
  .js)  has node  || exit 0; out=$(timeout 3 node --check "$file" 2>&1) || rc=$? ;;
  .ts)  has npx   || exit 0; out=$(timeout 3 npx tsc --noEmit "$file" 2>&1 | head -5) || rc=$? ;;
  .rb)  has ruby  || exit 0; out=$(timeout 3 ruby -c "$file" 2>&1) || rc=$? ;;
  .go)  has go    || exit 0; out=$(timeout 3 go vet "$file" 2>&1) || rc=$? ;;
  .sh)  out=$(timeout 3 bash -n "$file" 2>&1) || rc=$? ;;
  .json)
    out=$(timeout 3 python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$file" 2>&1) || rc=$? ;;
  .yaml|.yml)
    python3 -c "import yaml" 2>/dev/null || exit 0
    out=$(timeout 3 python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$file" 2>&1) || rc=$? ;;
  *) exit 0 ;;
esac

if [[ $rc -ne 0 ]]; then
  echo "⚠ Syntax error in $file:" >&2
  echo "$out" | head -5 >&2
fi
exit 0
