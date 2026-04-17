Run the CNS healthcheck and report results.

## Steps

1. Run `bash ~/.claude/healthcheck.sh` (or `bash ./claude/healthcheck.sh` if running from the Monty-CNS repo)
2. Parse the output — each line is prefixed with PASS, WARN, or FAIL
3. For any **FAIL** items:
   - Investigate the root cause (missing file, broken symlink, bad config, etc.)
   - Suggest a concrete fix the user can run
4. For any **WARN** items:
   - Note them and explain what's degraded
5. Summarize:
   ```
   Healthcheck: X passed, Y warnings, Z failures
   ```
   List failures first, then warnings. If everything passes, just say "All checks passed."
