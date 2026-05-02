# Vault Rules

## Rule 1. Save what changes future output

Do not save something because it is merely interesting.
Save it if it changes how future writing, decisions, planning, leadership, or AI support should happen.

## Rule 2. Separate source from synthesis

Raw notes and processed rules are not the same thing.

Keep the difference between:
- raw input
- extracted pattern
- working interpretation
- output rule

## Rule 3. Preserve provenance

If a line matters, preserve:
- the raw version
- the cleaned version if it exists
- the approved output if it exists
- the note that records the difference

Do not silently replace raw phrasing with a derivative line when the distinction matters.

## Rule 4. Use metadata consistently

Durable notes need frontmatter.
If a note is important enough to keep, it is important enough to classify.

## Rule 5. One note, one job

Do not cram five different note types into one page.
A note should usually do one thing:
- record a decision
- hold a profile layer
- preserve evidence
- define a writing rule
- track a project
- summarize a source
- mark a contradiction

## Rule 6. Links beat duplication

Link to canonical notes rather than repeating the same context everywhere.

## Rule 7. Internal notes do not need to be pretty

Internal notes should be:
- direct
- structured
- retrievable
- faithful

Do not waste effort polishing internal notes into fake outward prose.

## Rule 8. Access matters

Not every note should be treated the same.
Use access, truth layer, and role mode intentionally.

## Rule 9. Archive dead weight

If a note does not help retrieval, action, or understanding, it does not need to sit in the live vault forever.

## Rule 10. The vault must stay usable

A more powerful system that increases friction too much is a worse system.

## Rule 11. Confidence scale

Every note carries `confidence: N` where N is 1–5. The level is composite (provenance-dominant) — see `00_Inbox/2026-05-01_whitepaper_confidence-and-credence-scales-for-ai-vault-systems.md` for the full thesis. Working definition:

| Level | Name | Meaning |
|---|---|---|
| 1 | speculative | Hypothesis worth capturing before it's lost. Could be wrong. |
| 2 | working | AI-proposed default. Internally consistent but unverified. **Default for new AI writes.** |
| 3 | supported | Has in-body evidence (tests, citations, observed behavior). AI ceiling without human input. |
| 4 | verified | Human has read and confirmed, OR a second independent human has ratified. Durable. |
| 5 | canonical | Load-bearing. Other notes defer to this. Foundational decisions, irreversible facts. |

### Promotion rules

- **1 → 2:** AI may self-promote.
- **2 → 3:** AI may self-promote IF in-body evidence is present. AI re-runs in a separate session count as supporting evidence.
- **3 → 4:** HUMAN ONLY. AI Type-1 re-runs do not promote past 3.
- **4 → 5:** HUMAN ONLY. Triggered by 30+ days without contradiction in the vault, OR a second independent human ratifier (collapses the soak requirement).

### Demotion is NOT automatic

When a higher-confidence note contradicts a lower-confidence one, the AI flags the contradiction and the human decides: synthesize the two notes into one, OR explicitly reject one (which becomes the demotion). Demotion is the *outcome* of human deliberation, never a mechanic the AI executes alone.

### Type-1 vs Type-2 (why the AI ceiling sits at 3)

Per Kahneman 2011: System 1 is fast/automatic/pattern-matched; System 2 is slow/deliberate/alternative-aware. AI in this system is exclusively Type-1. Re-running a smoke test is Type-1-twice, not Type-2. The 3 → 4 promotion gate is the deliberative pause that only humans currently practice.

### Audit trail

When a confidence level changes, the frontmatter records it:

```yaml
demoted_from: 4         # or promoted_from
demoted_at: 2026-05-02  # or promoted_at
demoted_reason: "..."   # or promoted_by
```

### AI behavior

- Default new notes to `confidence: 2`.
- Prompt the human at write time (`/learn` step 3.5, `/retro` step 2.5).
- Refuse to set 4 or 5 without an explicit human number reply.
- When a note has open questions, set `status: review-pending` + checklist body + register in `~/.claude/PENDING_REVIEWS.md` (stop hook surfaces the count).
