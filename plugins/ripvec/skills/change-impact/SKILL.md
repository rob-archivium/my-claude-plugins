---
name: change-impact
description: "ALWAYS use this skill instead of Grep or Read when exploring outward from known code — understanding what depends on it, what it depends on, or what's similar. This skill MUST be used before any refactor, rename, or signature change. Triggers on: 'what depends on this', 'what breaks if I change this', 'find all callers', 'what calls this', 'find similar code', 'trace the call chain', 'blast radius'. Use ripvec's LSP incomingCalls/outgoingCalls and find_similar instead of grepping for function names."
---

# Change Impact: Code → Context → Connections

Start at a known location. Explore outward with LSP, then search for patterns.

## Tool discovery

MCP tools are deferred. Load before calling:
```
ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search_code,mcp__ripvec__find_similar,mcp__ripvec__find_duplicates,mcp__ripvec__index_status")
```
For LSP grounding on hosts without native LSP, also load:
```
ToolSearch("select:mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_hover,mcp__ripvec__lsp_goto_definition,mcp__ripvec__lsp_references,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls")
```
Plugin namespace: `mcp__plugin_ripvec_ripvec__*`. Call `index_status` first — wait if indexing.

## When to use

- "What calls this function?" → LSP `incomingCalls`
- "What does this function call?" → LSP `outgoingCalls`
- "Find all uses of this struct" → LSP `findReferences`
- "Find code similar to this" → `find_similar`
- "What's the blast radius of changing this?" → this full workflow
- "Are there duplicates of this?" → `find_duplicates`

## The pattern

```
document symbols(file)             → see what's in the file
incoming calls(function)           → who depends on this
outgoing calls(function)           → what this depends on
get_repo_map(focus_file: file)     → structural neighborhood
find_similar(file, line)           → parallel implementations
find_duplicates(threshold: 0.85)   → codebase-wide near-copies
```

Use native LSP in Claude Code when it is available. Use ripvec MCP LSP tools
in Codex or any host without native LSP. Both flows consume the same
`lsp_location` shape returned by ripvec semantic tools and repo-map entries.

### Step 1: Understand the local structure

```
lsp_document_symbols(file_path: "src/auth/middleware.rs")
```

See every function, field, constant. Identify the function being changed.

### Step 2: Trace the call graph

```
lsp_prepare_call_hierarchy(lsp_location)  → call hierarchy item for symbol
lsp_incoming_calls(call_item)             → every function that calls this
lsp_outgoing_calls(call_item)             → every function this calls
lsp_references(lsp_location)              → all usage sites
```

These use ripvec's function-level call graph — backed by PageRank, not
just text matching. Available for all supported languages.

### Step 3: See the structural neighborhood

```
get_repo_map(focus_file: "src/auth/middleware.rs", max_tokens: 1500)
```

Topic-sensitive PageRank concentrates on the focus file's callers and
callees. Shows which other files are structurally connected.

### Step 4: Find parallel implementations

```
find_similar(file: "src/auth/middleware.rs", line: 42, top_k: 10)
```

Finds code with similar embeddings — different implementations of the
same pattern. If changing a function signature, these likely need the
same change.

### Step 5: Check for duplicates

```
find_duplicates(threshold: 0.90)
```

Near-exact copies (>0.90) are likely copy-paste that should be refactored.
Similar patterns (0.85-0.90) may need coordinated changes.

## Safety checklist before a structural change

- [ ] Native `incomingCalls` or ripvec `lsp_incoming_calls` — identify all direct callers
- [ ] Native `findReferences` or ripvec `lsp_references` — all usage sites (including type annotations)
- [ ] `find_similar` — parallel implementations needing the same change
- [ ] `get_repo_map(focus_file)` — structural neighborhood
- [ ] Run tests on the dependency neighborhood, not just the changed file

## Don't

- Change a function signature without checking `incomingCalls` first
- Assume only one file is affected
- Skip `find_similar` — copy-paste code is everywhere
- Use Grep to find "who uses this" — use LSP `findReferences`
- Treat `search_code` or `get_repo_map` results as fully grounded until their
  `lsp_location` has been resolved through native LSP or ripvec MCP LSP
