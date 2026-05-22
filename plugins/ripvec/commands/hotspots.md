---
name: hotspots
description: Show the most structurally important functions in the codebase
---

Show the functions with the highest PageRank — the structural backbone of the codebase. These are the functions most code depends on.

Call `get_repo_map` with a high token budget to get the full ranked overview:

```
get_repo_map(max_tokens: 3000)
```

In Claude Code, the tool may live under `mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*` — `ToolSearch("ripvec")` if unsure. In Codex, call `get_repo_map` directly.

From the results, identify the top-tier functions (those with the most callers and highest PageRank). Present them as:

1. **Critical path** — functions that, if broken, would affect the most code
2. **Hub functions** — functions called by many different modules
3. **Gateway functions** — entry points where external input first touches internal logic

For each hotspot, show:
- Function name and location
- What calls it (incoming) — native `LSP() incoming_calls` or ripvec MCP `lsp_incoming_calls`
- What it calls (outgoing) — native `LSP() outgoing_calls` or ripvec MCP `lsp_outgoing_calls`
- Why it's important (brief description)

This is useful before:
- Major refactors (know what NOT to break)
- Code reviews (focus attention on high-impact changes)
- Onboarding (understand the architectural spine first)

See `/ripvec:orientation` for the full tool overview.
