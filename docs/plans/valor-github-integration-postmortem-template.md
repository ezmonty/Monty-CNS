# Postmortem: [INCIDENT TITLE]

| Field     | Value                |
|-----------|----------------------|
| Date      | YYYY-MM-DD           |
| Duration  | X hours Y minutes    |
| Severity  | P0 / P1 / P2        |
| Author    | [name]               |
| Reviewers | [name(s)]            |

## Summary

[2-3 sentence description of what happened, when it started, and when it was resolved.]

## Impact

[What users or systems were affected? How many? For how long? Include metrics if available.]

## Timeline

All times in UTC.

| Time  | Event                    |
|-------|--------------------------|
| HH:MM | Incident detected        |
| HH:MM | Investigation started    |
| HH:MM | Root cause identified    |
| HH:MM | Fix deployed             |
| HH:MM | Incident resolved        |

## Root cause

[Describe the underlying technical cause. Be specific -- link to commits, configs, or code paths where relevant.]

## Contributing factors

- [Factor that made the incident worse or delayed resolution]
- [Factor that allowed the problem to reach production]
- [Gap in monitoring, testing, or documentation]

## What went well

- [Aspect of the response that worked effectively]
- [Tool, process, or communication that helped]

## What went poorly

- [Aspect of the response that was slow or missing]
- [Information that was hard to find or unavailable]

## Action items

| Action                        | Owner  | Priority | Due date   | Status |
|-------------------------------|--------|----------|------------|--------|
| Add monitoring for [X]        | [name] | High     | YYYY-MM-DD | Open   |
| Update runbook section [Y]    | [name] | Medium   | YYYY-MM-DD | Open   |
| Add test coverage for [Z]     | [name] | Medium   | YYYY-MM-DD | Open   |

## Lessons learned

[Capture insights here. If any represent new dogfood lessons, add them to section 5 of the integration plan.]

---

> This postmortem is blameless. Focus on systems, processes, and tooling -- not individuals.
