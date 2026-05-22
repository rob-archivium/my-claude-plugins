---
name: duplicates
description: Find duplicate or near-duplicate code in the codebase
---

Find code that is duplicated or highly similar across the codebase. Uses ripvec's embedding index to detect semantic similarity between chunks.

## How to find duplicates

1. Use `get_repo_map` to identify the most important functions (highest PageRank). The engine auto-reconciles file changes on every call — no readiness check needed.

3. For workspace-wide near-duplicate detection:

```
find_duplicates(threshold: 0.85)
```

Or for a single location's neighbors:

```
find_similar(file: "path/to/file.rs", line: 42, top_k: 10)
```

In Claude Code, tools may live under `mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*` — `ToolSearch("ripvec")` if unsure. In Codex, call the bare names directly.

4. Filter results by similarity score:
   - **> 0.95**: likely exact or near-exact duplicates (copy-paste)
   - **0.85 - 0.95**: very similar logic, possibly refactorable
   - **0.70 - 0.85**: similar patterns, worth reviewing

5. **Ground each cluster with LSP.** Pass each duplicate's `lsp_location` to `find_references` (native `LSP()` or ripvec MCP `lsp_references`) to see actual usage. A high similarity score is necessary but not sufficient — some "duplicates" are unrelated symbols with similar token distributions.

6. Group the findings by similarity cluster and report:
   - Which functions are duplicated
   - Where the duplicates live
   - Whether they're exact copies or variations
   - Suggested refactoring (extract shared function, trait, etc.)

Focus on chunks with high similarity scores (> 0.85) — these are the most likely candidates for deduplication. Ignore test files unless specifically asked to include them.

Report results as a table: source location, duplicate location, similarity score, and a brief description of what's duplicated.
