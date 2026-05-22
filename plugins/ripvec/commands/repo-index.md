---
name: repo-index
description: Force a fresh in-memory rebuild of the search index
---

Call the `reindex` MCP tool to evict any cached in-memory index for the current root and rebuild it from scratch:

```
reindex()
```

In Claude Code, the tool may live under `mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*` — `ToolSearch("ripvec")` if unsure. In Codex, call `reindex` directly.

## What this does

The ripvec engine (Model2Vec static encoder + cross-encoder reranker) is **cacheless and CPU-only** since v3.0.0. The index lives entirely in the MCP process's memory, built on first query against a root, and survives until the process exits.

`reindex` evicts the in-memory cache for the current root and rebuilds. Use it when:
- Files changed and the index is stale (rare — most usage rebuilds on next query naturally)
- You want to confirm the index reflects the current working tree before a critical search
- You suspect a corrupted state and want a fresh build

After `reindex` completes, the response reports:
- Chunks indexed
- Files walked
- Duration (typically <500ms for a medium repo, a few seconds for very large repos)

There is no `.ripvec/cache/` directory to commit; the v2.x repo-local cache was tied to the doomed transformer engines and was removed in v3.0.0. If you want indexing to persist across MCP restarts, that's a future feature; today, the process-lifetime cache is by design (no disk I/O on the hot path, no manifest invalidation logic).

See `/ripvec:orientation` for the full tool overview.
