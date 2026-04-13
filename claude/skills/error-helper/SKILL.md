---
name: error-helper
description: Systematically diagnose and fix errors — Python tracebacks, npm errors, Docker issues, network/connection failures. Use when the user encounters an error or something isn't working.
---

# Error Diagnosis

When the user encounters an error, follow this systematic approach. **Fix one thing at a time.** Don't change multiple things and hope one works.

## Step 1: Read the Full Error

Before guessing:

1. Read the **complete** traceback top to bottom — the root cause is usually at the bottom in Python, top in JS.
2. Identify the exact file and line number.
3. Note the error type (the class name, e.g. `ConnectionRefusedError`, `ModuleNotFoundError`).

## Step 2: Classify by Pattern

| Error Pattern | Likely Cause | First Check |
|---|---|---|
| `ConnectionRefusedError` / `ECONNREFUSED` | Target service not running, or wrong port | `lsof -i :<port>` or `ss -tlnp` |
| `ModuleNotFoundError` (Python) | Missing dep or wrong venv | `pip list \| grep <name>`, check venv |
| `ENOENT` / `MODULE_NOT_FOUND` (Node) | Missing `node_modules` or wrong path | `npm install` |
| `ValidationError` (Pydantic / Zod) | Payload doesn't match schema | Diff actual vs. expected shape |
| `TypeError: Cannot read properties of undefined` | API returned unexpected shape | Log the full response before destructuring |
| `Port already in use` / `EADDRINUSE` | Another process holding the port | `lsof -i :<port>` → kill or pick new port |
| `EACCES` / `Permission denied` | Filesystem or socket permissions | `ls -la` on the path, check ownership |
| `KeyError` / `undefined property` | Missing key in data structure | Print/log the object, confirm the key exists |
| SSL / cert errors | Clock skew, self-signed cert, expired CA | Check system time, cert chain |

## Step 3: Gather Context

1. What changed recently? `git diff` and `git log -5`.
2. Is the service actually running? `ps aux`, `docker ps`, `systemctl status`.
3. Do the logs show anything before the error? Tail them.
4. Does it reproduce cleanly? Flaky errors often indicate race conditions or environmental drift.

## Step 4: Common First-Aid (in order of safety)

Try the least invasive fix first:

### Python / backend

```bash
pip install -r requirements.txt   # Missing dep
python -m <your_module>           # Start the service fresh
pytest -x <relevant_test>         # Verify after fix
```

### Node / frontend

```bash
rm -rf node_modules package-lock.json
npm install                       # Nuclear option — saves debugging lockfile weirdness
npm run build                     # Surface type errors
```

### Docker

```bash
docker compose logs -f <service>  # Find the real error
docker compose down && docker compose up -d
```

### Ports

```bash
lsof -i :<port>                   # What's holding it
kill <pid>                        # Or pick a new port
```

## Step 5: Verify the Fix

- Re-run the original failing command.
- Run the relevant test.
- Check adjacent functionality didn't regress.

## Anti-Patterns to Avoid

- **Stack Overflow copy-paste without reading** — understand the fix first.
- **Disabling the error** (broad `try/except`, TypeScript `any`) instead of solving it.
- **Restarting without understanding** — if it was a race condition, it'll come back.
- **Changing five things at once** — now you don't know which one worked.
