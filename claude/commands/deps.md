---
description: Audit dependencies for CVEs, outdated versions, and weak pinning.
---

Audit dependencies for security vulnerabilities, outdated packages, and version pinning.

Target: $ARGUMENTS ("python", "node", "go", or empty for auto-detect)

## Auto-Detect
Look for: `requirements.txt`, `pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `Gemfile`

## Python
```bash
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null
pip audit 2>/dev/null || echo "pip-audit not installed"
pip list --outdated 2>/dev/null | head -20
```
- Check all deps use exact versions (`==`), flag `>=` or unpinned
- Watch: `cryptography`, `requests`, `pyjwt`/`python-jose`, `sqlalchemy`, `pillow`

## Node
```bash
npm audit 2>/dev/null
npm outdated 2>/dev/null
```
- Watch: `axios`, `express`, `jsonwebtoken`, `lodash`

## Go
```bash
go list -m -u all 2>/dev/null
govulncheck ./... 2>/dev/null
```

## Rust
```bash
cargo audit 2>/dev/null
cargo outdated 2>/dev/null
```

## Report
```
Dependency Audit
════════════════
[Language] ([file]):
  Packages:       XX total
  Pinned:         XX/XX
  Vulnerabilities: X critical, X high, X medium
  Outdated:       X packages

Action Items (by priority):
  1. [CRITICAL] ...
  2. [HIGH] ...
```
Ask: "Want me to fix any of these?"
