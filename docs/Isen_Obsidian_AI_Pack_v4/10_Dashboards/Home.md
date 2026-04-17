# Home

This dashboard starts manual and gets automated later.

## Start here

- [[README]]
- [[START_HERE]]
- [[Project - Vault Implementation]]
- [[Profile - Identity and Context]]
- [[Profile - Voice and Writing]]
- [[Profile - Roles and Modes]]

## Active project

- [[Project - Vault Implementation]]

## Live profile spine

- [[Profile - Identity and Context]]
- [[Profile - Voice and Writing]]
- [[Profile - Reasoning and Decision]]
- [[Profile - Values and Duty]]
- [[Profile - Leadership]]
- [[Profile - Life Arc]]
- [[Profile - Work and Execution]]
- [[Profile - Revision and Feedback]]
- [[Profile - Roles and Modes]]

## Suggested Dataview blocks

```dataview
TABLE status, updated, review_due
FROM "02_Projects"
WHERE type = "project" AND status = "active"
SORT updated DESC
```

```dataview
TABLE type, review_due, access, truth_layer
FROM ""
WHERE review_due AND date(review_due) <= date(today) + dur(14 days)
SORT review_due ASC
```

```dataview
TABLE confidence, tags
FROM "06_Writing"
WHERE type = "writing_rule"
SORT confidence DESC
```
