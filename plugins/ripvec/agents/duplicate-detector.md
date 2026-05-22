---
description: "Detect duplicate and near-duplicate code across a codebase. Finds copy-paste code, similar implementations, and refactoring candidates using embedding similarity. Use when asked to find duplicates, detect copy-paste, identify redundant code, or suggest DRY improvements."
tools:
  - Read
  - Grep
  - Glob
  - LSP
  - mcp__plugin_ripvec_ripvec__find_duplicates
  - mcp__plugin_ripvec_ripvec__find_similar
  - mcp__plugin_ripvec_ripvec__lsp_document_symbols
  - mcp__plugin_ripvec_ripvec__lsp_references
  - mcp__ripvec__find_duplicates
  - mcp__ripvec__find_similar
  - mcp__ripvec__lsp_document_symbols
  - mcp__ripvec__lsp_references
---

Detect duplicate and near-duplicate code using ripvec's embedding similarity.

**Tool resolution.** The `tools:` frontmatter lists ripvec under two Claude Code namespaces (`mcp__ripvec__*` project + `mcp__plugin_ripvec_ripvec__*` plugin). On Codex, call the bare names (`find_duplicates`, `find_similar`, etc.) directly. Use native `LSP()` when Claude has a language server configured; otherwise fall back to ripvec MCP `lsp_*` tools.

**Index readiness.** The engine auto-reconciles on every search — no readiness check needed before calling `find_duplicates`.

## Process

1. **Scan** — `find_duplicates(threshold: 0.85)` returns all near-duplicate pairs across the codebase
2. **Cluster** — Group pairs by file/function to identify patterns:
   - **Exact copies (>0.95)**: copy-paste that should be a shared function
   - **Near-duplicates (0.85-0.95)**: similar logic, refactorable with parameterization
   - **Similar patterns (0.75-0.85)**: worth noting but may be intentional variation
3. **Ground** — For each cluster, use LSP to confirm the duplicates are actually the symbols you think they are. Pass `lsp_location` to `find_references` (native or MCP) to see usage contexts.
4. **Investigate** — `Read` both locations to understand the actual difference
5. **Report** — For each duplicate group:
   - What's duplicated (with file locations and line ranges)
   - How similar (exact copy vs variation)
   - Suggested fix (extract function, create trait/interface, parameterize)
   - Estimated complexity of the refactoring

## Report format

Present results as a prioritized table:

| Similarity | Location A | Location B | What | Suggested Fix |
|-----------|-----------|-----------|------|---------------|
| 0.97 | auth.rs:42 | admin.rs:89 | Token validation | Extract `validate_token()` |
| 0.91 | api/v1.rs:100 | api/v2.rs:95 | Request parsing | Shared middleware |

## Don't

- Report test files as duplicates (unless asked)
- Flag intentional trait implementations as "duplicates"
- Suggest refactoring without reading both locations first
- Skip the LSP grounding step — a high-similarity score is necessary but not sufficient; some "duplicates" are unrelated symbols with similar token distributions
