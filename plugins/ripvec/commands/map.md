---
name: map
description: Show the PageRank-weighted structural overview of this codebase
arguments:
  - name: focus
    description: File to focus on (optional — shows the dependency neighborhood)
    required: false
---

Call the `get_repo_map` MCP tool to get a structural overview of this codebase.

If the user provided a focus file argument, use it:

```
get_repo_map(focus_file: "<focus argument>", max_tokens: 2000)
```

If no focus argument, get the default overview:

```
get_repo_map(max_tokens: 2000)
```

In Claude Code, the tool may live under `mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*` — use `ToolSearch("ripvec")` if unsure. In Codex, call `get_repo_map` directly.

Present the output directly — it's already formatted as a readable structural overview with PageRank scores, callers/callees, and function signatures organized by importance tier.

After presenting, optionally suggest:
- `get_repo_map(focus_file: ...)` to zoom into a specific file's neighborhood
- Native `LSP() document_symbol` (Claude Code) or `lsp_document_symbols` (Codex / MCP fallback) on the top-ranked files for full outlines
- `/ripvec:hotspots` to see the highest-PageRank functions specifically
