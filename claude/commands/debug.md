Analyze and fix an error or bug.

Error: $ARGUMENTS (paste the error, traceback, or describe the symptom)

## Step 0: Query vault for similar past issues
If the `query_notes` MCP tool is available, query with tags matching the error type (e.g., 'auth', 'database', 'network', 'timeout'). Check if a prior learning or decision note addresses this error pattern. Include relevant vault findings in the diagnosis.

## Step 1: Understand the Error
- If a traceback: parse it → identify root cause file and line
- If a description: search the codebase for relevant code
- If a runtime error: check logs, environment, config

## Step 2: Reproduce
- Identify the conditions that trigger the error
- Find or write a test that reproduces it

## Step 3: Diagnose
- Read the failing code and its dependencies
- Check common issues:
  - Missing imports or dependencies
  - Wrong configuration / environment variables
  - Type mismatches
  - Race conditions
  - Network/connection issues (wrong port, host, timeout)

## Step 4: Fix
- Apply the minimal fix that addresses the root cause
- Do NOT refactor surrounding code

## Step 5: Verify
- Run the relevant tests
- Confirm the error no longer occurs

## Step 6: Report
```
What was wrong: [root cause]
What changed:   [file:line — description]
Test results:   [passing]
```
