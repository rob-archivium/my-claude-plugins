---
name: semantic-discovery
description: "ALWAYS use this skill instead of Grep when the user describes code by behavior, concept, or intent rather than exact text. This skill MUST be used before Grep for: 'find the code that handles X', 'where is Y implemented', 'how does Z work', 'find authentication logic', 'search for retry handling', 'find the database layer', 'where do we handle errors'. Grep is only appropriate for exact strings like 'TODO' or regex patterns. For everything else, use ripvec's semantic search."
graph:
  generalizes_to:
    - ripvec:ripvec-orientation
  specializes_into: []
  cross_references:
    - ripvec:cartographer
    - ripvec:codebase-orientation
    - ripvec:intent-routing
  escalate_to: ripvec:cartographer
---

## §0 — Graph position

**Parent hub:** `ripvec:cartographer` (Cartographer orientation, HUB-C).
**Composes-into:** `ripvec:change-impact` (semantic search finds the
candidate; change-impact quantifies the consequence of touching it). See
`SKILL_SEMANTIC_GRAPH.md §4` CL-CONCEPT-TOUR for the cluster body this
skill traverses — T2 Intent First, T5 Topic-Sensitive Rebias, C1
PageRank-Anchored Concept Tour. For the full orientation triage, load
`ripvec:ripvec-orientation` first.

# Semantic Discovery: Concept → Code → Navigate

Find code by meaning, then navigate into it with LSP.

## Tool access

ripvec exposes the same tool surface to both hosts; only the call syntax differs.

**In Claude Code**, MCP tools are deferred — load them via `ToolSearch` before calling:

```
ToolSearch("ripvec")                            # discover the active namespace
ToolSearch("select:mcp__ripvec__search,mcp__ripvec__get_repo_map,mcp__ripvec__find_similar")
```

The namespace is either `mcp__ripvec__*` (project-level `.mcp.json`) or `mcp__plugin_ripvec_ripvec__*` (plugin install). `ToolSearch("ripvec")` returns whichever your session has. For LSP-shaped grounding tools:

```
ToolSearch("select:mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_hover,mcp__ripvec__lsp_goto_definition,mcp__ripvec__lsp_references,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls")
```

But **Claude Code's native `LSP()` tool is the preferred grounding path** when the workspace has any LSP configured (ripvec or otherwise). The ripvec MCP `lsp_*` tools are a fallback for when no native LSP is wired up.

**In Codex**, tool names are resolved by bare names — no `ToolSearch`, no prefix. Call `search`, `get_repo_map`, `lsp_hover`, `lsp_goto_definition`, etc. directly. Codex does not have a native LSP integration; the ripvec MCP `lsp_*` tools ARE the LSP path.

**Index lifecycle.** The ripvec engine builds its in-memory index on first query against a root and keeps it for the MCP process lifetime. CPU-only Model2Vec static encoder; no on-disk cache, no warm/cold distinction.

## When to use

- Describing behavior: "find the retry logic" → `search(query: ..., scope: "code")`
- "What does the documentation say about X" → `search(query: ..., scope: "docs")`
- Anywhere in the repo: `search(query: ...)` (scope defaults to `"all"`)
- Naming a symbol: "find useAuth hook" → `search` or LSP `workspace_symbol`
- Exact text: "find all TODOs" → Grep (not this skill)

`scope` controls extension filtering and reranking in one switch:
- `"code"` skips docs and disables the cross-encoder rerank
- `"docs"` keeps only prose; cross-encoder reranks NL queries
- `"all"` applies no extension filter; rerank fires when the corpus is ≥30% prose

**Symbol-shaped queries never rerank** (e.g. `ConnectionPool`, `useAuth`) — the bi-encoder + path BM25 + PageRank stack handles them, and the cross-encoder forward pass costs ~1s without quality lift on identifiers.

Use `include_extensions` / `exclude_extensions` to narrow further:

```
search(query: "...", include_extensions: ["rs", "toml"])   # only these
search(query: "...", exclude_extensions: ["lock", "md"])   # everything except these
```

## The pattern

```
search("concept", scope: "code")  →  candidates with lsp_location
ground via LSP(lsp_location)      →  native LSP or ripvec MCP lsp_*
document_symbols(file)            →  full outline of the best match
go_to_definition(position)        →  jump to where the symbol lives
hover(position)                   →  scope chain + context
references(position)              →  every usage site
```

### Step 1: Search by meaning

```
search(query: "authentication middleware that validates JWT tokens", scope: "code")
```

Results are ranked by relevance × structural importance (function-level PageRank). Functions that many others depend on rank higher.

### Step 2: Ground the best match

Every ripvec search result includes an `lsp_location` shape (file, line, character, range). **Vector similarity is not symbol identity.** Ground the candidate before editing or explaining exact behavior:

- **Claude Code**: pass `results[].lsp_location` to the native `LSP()` tool — `document_symbol`, `go_to_definition`, `hover`, `find_references`, call hierarchy.
- **Codex (or any host without native LSP)**: pass the same `lsp_location` shapes to the ripvec MCP `lsp_*` tools: `lsp_document_symbols`, `lsp_goto_definition`, `lsp_hover`, `lsp_references`, `lsp_prepare_call_hierarchy`, `lsp_incoming_calls`, `lsp_outgoing_calls`.

Both paths return the same data. The ripvec MCP LSP responses include both a ripvec-shaped `results[]` array and the raw `lsp.raw_response`, so they can feed back into semantic tools or another LSP call.

### Step 3: Examine the best match

```
# Claude Code (native):
LSP(method: "textDocument/documentSymbol", params: { textDocument: { uri: "..." } })

# Codex (MCP):
lsp_document_symbols(file_path: "auth/middleware.rs")
```

Shows every function, struct, field, constant in the file. ripvec's LSP covers all 21 supported languages including the ones with no dedicated server (bash, HCL, TOML, Ruby, Kotlin, Swift, Scala).

### Step 4: Navigate deeper

```
go_to_definition(lsp_location)     # jump to where a called function lives
incoming_calls(call_item)          # who calls this function (PageRank-weighted)
outgoing_calls(call_item)          # what this function calls
find_similar(file, line)           # parallel implementations elsewhere
```

The composition pattern is identical across hosts; only the call syntax changes.

## Grep vs search

| User describes | Tool |
|----------------|------|
| Behavior ("retry with backoff") | `search(query: ..., scope: "code")` |
| Documentation ("how is X documented") | `search(query: ..., scope: "docs")` |
| Anywhere in the repo | `search(query: ...)` (scope defaults to `"all"`) |
| Symbol name ("ConnectionPool") | `search` or LSP `workspace_symbol` |
| Exact string ("TODO: fix") | Grep |
| Pattern/regex | Grep |

## Don't

- Use Grep for conceptual queries
- Read files sequentially hoping to find something
- Edit based only on vector similarity without grounding through native `LSP()` or ripvec MCP `lsp_*` tools
- Skip `scope` — a code-only query against `scope: "all"` wastes the cross-encoder rerank pass on prose files
