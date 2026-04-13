Review code for bugs, security issues, performance, and best practices.

Target: $ARGUMENTS (file path, directory, or "staged" for git staged changes)

## What to Check

### 1. Correctness
- Logic errors, edge cases, off-by-one errors
- Null/None/undefined handling
- Race conditions in async code
- Resource leaks (unclosed files, connections, streams)

### 2. Security (OWASP Top 10)
- **Injection**: SQL injection, command injection, XSS
- **Auth**: Missing auth checks, weak token validation
- **Secrets**: Hardcoded credentials, API keys in code
- **Data exposure**: Sensitive data in logs, verbose errors
- **Input validation**: Missing or insufficient validation

### 3. Performance
- N+1 queries (DB calls in loops)
- Blocking calls in async code
- Missing indexes on frequently queried columns
- Unnecessary re-renders (React), unnecessary copies
- Large payloads without pagination

### 4. Code Quality
- Dead code, unused imports
- Overly complex functions (should be split)
- Missing error handling
- Inconsistent naming or patterns

### 5. Testing
- Is this code tested?
- Are edge cases covered?
- Could a test have caught this?

## How to Get the Code
If target is "staged": `git diff --cached`
Otherwise: read the specified files.

## Output
For each finding:
```
[CRITICAL|HIGH|MEDIUM|LOW] file:line
  What: [description]
  Fix:  [how to fix it]
```

End with: "Want me to fix any of these? Just say which ones."
