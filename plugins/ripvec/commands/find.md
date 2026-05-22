---
name: find
description: Semantic code search — find code by meaning, not text
arguments:
  - name: query
    description: Natural language description of what you're looking for
    required: true
---

Call the `search` MCP tool with the user's query, defaulting to code scope:

```
search(query: "<query argument>", scope: "code", top_k: 5)
```

In Claude Code, the tool may live under `mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*` — use `ToolSearch("ripvec")` if you're unsure. In Codex, just call `search` directly.

Results include full source code in fenced blocks plus an `lsp_location` per hit. Present the top results with:
- File path and line range
- Similarity score
- The code content
- A note that the caller can pass `lsp_location` to LSP (native `LSP()` for Claude, or ripvec `lsp_goto_definition` / `lsp_hover` for Codex / MCP fallback) to ground the candidate before editing

If results seem off-topic, suggest the user try:
- More specific phrasing
- `search(query: ..., scope: "docs")` for documentation/comments
- `search(query: ...)` with no `scope` to search everything (default `"all"`)
- `search(query: ..., include_extensions: ["rs", "ts"])` to narrow by file type
- `search(query: ..., exclude_extensions: ["lock", "md"])` to exclude noise
- `Grep` if they're looking for an exact string

See `/ripvec:orientation` for the full search-scoping decision tree.
