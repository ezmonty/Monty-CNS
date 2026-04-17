# Review Queue

Use this note weekly.

## Manual checks

- inbox processed
- new evidence units extracted
- profile notes updated
- review_due items touched
- dead notes archived
- contradictions flagged
- any quote provenance gaps corrected

## Dataview

```dataview
TABLE type, review_due, access
FROM ""
WHERE review_due AND date(review_due) <= date(today) + dur(7 days)
SORT review_due ASC
```
