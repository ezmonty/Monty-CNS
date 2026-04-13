Perform a security audit on the specified code.

Target: $ARGUMENTS (file path, directory, or "all")

## Check These Categories

### 1. Injection
- **SQL injection**: Raw queries, unsanitized inputs, string concatenation in queries
- **Command injection**: `subprocess`, `os.system`, `exec`, `eval` with user input
- **XSS**: Unescaped user content rendered in HTML/React (dangerouslySetInnerHTML)
- **Template injection**: User input in template strings

### 2. Authentication & Authorization
- Missing auth checks on endpoints
- Role/permission bypass
- Hardcoded credentials or API keys
- Weak token validation (no expiry, no signature check)
- Session fixation

### 3. Data Exposure
- Secrets in code or config (API keys, passwords, tokens)
- Verbose error messages leaking internals to users
- Sensitive data in logs
- PII without encryption

### 4. API Security
- Missing input validation on endpoints
- No rate limiting
- CORS misconfiguration (allow *)
- Missing CSRF protection
- Missing security headers

### 5. Dependencies
Check for known vulnerable packages:
```bash
pip audit 2>/dev/null
npm audit 2>/dev/null
```

### 6. Cryptography
- Weak algorithms (MD5, SHA1 for passwords)
- Hardcoded encryption keys
- Using `random` instead of `secrets` for security purposes

## Output
```
[CRITICAL|HIGH|MEDIUM|LOW] file:line
  Issue: [description]
  OWASP: [category]
  Fix:   [recommendation]
```
