# /smoke — Live Stack Verification

Run this after every deploy that touches UI or agent files.
It hits the real endpoints, reports actual response data, and sets the
verification marker so the stop hook passes.

## What to check

Determine what changed in the last commit:

```bash
git diff --name-only HEAD~1 HEAD
```

Then run the relevant checks below. Always report the **actual response
content**, not just the HTTP status code.

## Checks by surface

### Construction console UI (`ui/construction-console`)
```bash
# Title present in deployed HTML
curl -s https://api.remedy-reconstruction.com/ | grep -o '<title>[^<]*</title>'

# CFO role nav item present in compiled JS bundle
# (CFO is now a role-switched WorkstationPage, not an external link — label is "CFO")
ssh valor-vm "grep -rl 'label:\"CFO\"' ~/valor2.0/ui/construction-console/dist/assets/ | wc -l"
# Expected: 1 (bundle file found)
```

### Delivery integrity (run after every build + deploy)

These two checks confirm users are actually receiving the new code, not a
browser-cached or nginx-served stale version.

```bash
# 1. index.html must never be cached by the browser
curl -sI https://api.remedy-reconstruction.com/ | grep -i cache-control
# Expected: no-cache, no-store, must-revalidate

# 2. Verify the delivered JS bundle matches the current build
#    Extract the hashed JS filename from the live index.html served by nginx,
#    then confirm the asset is served as JS (not the SPA fallback text/html)
#    and carries immutable cache headers.
BUNDLE=$(ssh valor-vm "grep -o 'index-[^\"]*\.js' ~/valor2.0/ui/construction-console/dist/index.html | head -1") && \
curl -sI "https://api.remedy-reconstruction.com/assets/$BUNDLE" | grep -i "content-type\|cache-control"
# content-type  → must be application/javascript (not text/html)
# cache-control → must contain immutable
```

### Agent code verification (run after every ConstructionAutopilotAgent.py change)
```bash
ssh valor-vm "cd ~/valor2.0 && python3 -m pytest tests/smoke_workstation_action.py -q 2>&1 | tail -3"
# Expected: 8 passed
```

### CFO Console app (`valor-cfo-console` at /cfo/)
```bash
# App loads
curl -s https://api.remedy-reconstruction.com/cfo/ | grep -o '<title>[^<]*</title>'

# Real API data (not mock): dashboard must return actual metrics
# Note: CFOConsoleAgent requires x-api-key (reads VALOR_API_KEY from env)
ssh valor-vm "KEY=\$(grep '^VALOR_API_KEY=' ~/valor2.0/.env | cut -d= -f2); \
  curl -s -H \"x-api-key: \$KEY\" http://localhost:8350/api/cfo/dashboard | python3 -c \
  'import sys,json; d=json.load(sys.stdin); \
   print(\"source:\", d.get(\"source\")); \
   print(\"metrics:\", len(d.get(\"metrics\",[])), \"items\"); \
   print(\"dscr:\", d.get(\"dscr\")); \
   print(\"risk_score:\", d.get(\"risk_score\")); \
   print(\"risk_band:\", d.get(\"risk_band\"))'"
```

### CFOConsoleAgent (port 8350)
```bash
ssh valor-vm "curl -s http://localhost:8350/health | python3 -m json.tool"
ssh valor-vm "KEY=\$(grep '^VALOR_API_KEY=' ~/valor2.0/.env | cut -d= -f2); \
  curl -s -H \"x-api-key: \$KEY\" http://localhost:8350/api/cfo/dashboard | \
  python3 -c 'import sys,json; d=json.load(sys.stdin); print(list(d.keys()))'"
```

### MontyCore (port 8090)
```bash
ssh valor-vm "curl -s http://localhost:8090/health | python3 -m json.tool"
```

### SoR sync endpoint
```bash
ssh valor-vm "curl -s -X POST http://localhost:8090/api/sor/sync \
  -H 'Content-Type: application/json' \
  -d '{\"provider\":\"procore\",\"tenant_id\":\"default\"}' | python3 -m json.tool | head -10"
```

## After running checks

Report the **actual values** returned — not "it worked". Example:

> smoke results:
> - construction console title: ✓ "Valor Construction Console"
> - CFO nav bundle: ✓ 1 file (label:"CFO" present)
> - index.html Cache-Control: ✓ no-cache, no-store, must-revalidate
> - bundle content-type: ✓ application/javascript, immutable
> - /cfo/ title: ✓ "Valor CFO Console"
> - dashboard source: "seeded", metrics: 4, dscr: 1.61, risk_score: 10 (low)
> - CFOConsoleAgent health: ok, 54 endpoints
> - backend smoke: 8 passed

Then set the verification marker so the stop hook passes:

```bash
touch /tmp/valor-live-verified
```

## When to run

- After any `git push` that changed UI files or agent files
- Before saying a feature is "done" or "live"
- After any nginx config change
- After any `npm run build` + deploy sequence
