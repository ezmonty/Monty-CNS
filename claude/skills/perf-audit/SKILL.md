---
name: perf-audit
description: Find performance bottlenecks — slow endpoints, N+1 queries, blocking calls in async code, memory leaks, frontend render storms, large bundles. Use when the user reports slowness or wants to optimize.
---

# Performance Audit

Target: $ARGUMENTS (file, directory, feature area, or "all")

## Backend Checks

### 1. Blocking calls inside async handlers

Search for synchronous operations inside `async def` / `async function`:

- `requests.get/post` in Python → use `httpx.AsyncClient`
- `time.sleep()` → use `asyncio.sleep()`
- `open()` / file I/O → use `aiofiles` or offload to a thread
- Sync DB drivers under async handlers → use the async variant

### 2. N+1 query patterns

Look for:

- Loops that issue one DB query or HTTP call per item
- `for item in items: fetch(item.id)` shapes
- Missing batch endpoints — prefer `WHERE id IN (...)` or a join

### 3. Missing or misused caching

- Frequently-read static data hitting disk / DB every request
- Cache keys that include user-specific data (bloats cache)
- No TTL — stale data forever
- Cache stampede when many requests miss at once (use single-flight / lock)

### 4. Heavy computation in the request path

- Large JSON serialization on every request
- File processing inline — move to a worker queue
- Unbounded loops over user-supplied data without limits/pagination

### 5. Database specifics

- Missing index on frequently-queried columns (`EXPLAIN`/`EXPLAIN ANALYZE`)
- `SELECT *` when you need three columns
- Cartesian joins
- ORM lazy-loading N+1s (the silent killer)

## Frontend Checks

### 6. React rendering

- Components re-rendering without prop/state change — missing `React.memo`, `useMemo`, `useCallback`
- Inline object/array literals as props forcing re-renders
- Large lists without virtualization (`react-window`, `react-virtuoso`)
- Context providers wrapping the whole tree for data only 1-2 components read

### 7. Network

- Missing request deduplication (same query fired 5x on mount)
- No loading state — user spam-clicks, duplicate requests
- Waterfalls: sequential fetches that could parallelize
- Oversized payloads — paginate or trim

### 8. Bundle size

- Run the project's build and check chunk sizes
- Flag any chunk over ~300 KB gzipped
- Look for accidentally imported heavy deps (moment, lodash, charting libs)
- Prefer dynamic `import()` for rarely-used routes

## Report Format

For each finding, use this shape so fixes are actionable:

```
Location:  path/to/file.py:123
Issue:     What's slow and why, in one sentence.
Impact:    [Blocking / Wasted renders / Large payload / etc.]
Fix:       Specific recommendation (code change, config, or tool).
Effort:    [Quick / Medium / Major]
```

## Measurement First

Never optimize without numbers:

- Backend: request timing middleware, flamegraphs (`py-spy`, `perf`), DB slow query log
- Frontend: Chrome DevTools Performance tab, React DevTools Profiler, Lighthouse
- Always benchmark **before and after** — some "optimizations" are slower.
