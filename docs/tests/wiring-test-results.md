# W3 Integration Test Results

**Date:** 2026-04-18T08:17:18+00:00
**Environment:** Claude Code web sandbox, Postgres 16, Node 22, Python 3.11
**MCP Server:** monty-ledger v0.1.0 (TypeScript, 7 tools)

## Results: 17/17 PASS

### W3.1: Full Knowledge Loop
| Test | Result | Evidence |
|------|--------|----------|
| create_inbox_note creates note | PASS | MCP returned "Created inbox note" |
| File exists on disk | PASS | `00_Inbox/2026-04-18_w3-final-age-key-rotation-procedure.md` |
| Row in Postgres | PASS | `origin_type=ai-proposed, confidence=2` |
| Tags in Postgres | PASS | 3 tags inserted (w3test, sops, security) |
| query_notes finds by tag | PASS | 1 note returned for tag "w3test" |

### W3.2: Search + Profiles
| Test | Result | Evidence |
|------|--------|----------|
| search_content | PASS | 3 results for "Marine leadership duty" |
| list_profiles | PASS | 10 profiles returned |

### W3.3: Pod + Packet
| Test | Result | Evidence |
|------|--------|----------|
| get_pod (Executive Negotiation) | PASS | Pod found, 1354 chars |
| build_packet | PASS | Packet built, 5571 chars |

### W3.4: All 7 Tools Health
| Tool | Result |
|------|--------|
| query_notes | PASS |
| get_note | PASS |
| search_content | PASS |
| build_packet | PASS |
| get_pod | PASS |
| list_profiles | PASS |
| create_inbox_note | PASS |

### W3.5: Cross-Machine Query
| Test | Result | Evidence |
|------|--------|----------|
| ai-proposed notes visible | PASS | 5 notes queryable from "any machine" |

## Bugs Found and Fixed During Testing

1. **create_inbox_note didn't insert tags** — tags were written to
   markdown frontmatter but not to the `tags` table. Fixed by adding
   INSERT INTO tags loop after the notes INSERT.

2. **get_pod filtered on `type = 'pod'`** — but vault stores pods as
   `type: note`. Fixed to also match `path LIKE '13_Pods/%'`.

## Test Artifacts in Vault Inbox

```
00_Inbox/2026-04-18_mcp-live-test.md          (MCP roundtrip test)
00_Inbox/2026-04-18_jwt-rs256-needs-full-cert-chain.md  (W0.1 /learn test)
00_Inbox/2026-04-18_w3-test-sops-age-key-rotation.md    (W3.1 first run)
00_Inbox/2026-04-18_w3-final-age-key-rotation-procedure.md  (W3.1 final)
00_Inbox/2026-04-18_w3-health-check.md        (W3.4 health check)
```
