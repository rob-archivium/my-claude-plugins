---
name: change-impact
description: "ALWAYS use this skill instead of Grep or Read when exploring outward from known code — understanding what depends on it, what it depends on, or what's similar. This skill MUST be used before any refactor, rename, or signature change. Triggers on: 'what depends on this', 'what breaks if I change this', 'find all callers', 'what calls this', 'find similar code', 'trace the call chain', 'blast radius'. Use ripvec's LSP incoming_calls/outgoing_calls and find_similar instead of grepping for function names."
graph:
  generalizes_to:
    - ripvec:ripvec-orientation
  specializes_into: []
  cross_references:
    - ripvec:refactorer
    - ripvec:codebase-orientation
    - ripvec:intent-routing
  escalate_to: ripvec:refactorer
---

## §0 — Graph position

**Parent hub:** `ripvec:refactorer` (Refactorer orientation, HUB-R).
**Composes-into:** `ripvec:codebase-orientation` (the focused map gives
the dependency direction after the blast radius is known). See
`SKILL_SEMANTIC_GRAPH.md §4` CL-BLAST-RADIUS and CL-CONTRACT-SURVEY for
the cluster bodies this skill traverses. The canonical recipe is
**T10 Blast-Radius Manifest** (P2 Fixed-Point Expansion). For the full
orientation triage, load `ripvec:ripvec-orientation` first.

# Change Impact: Code → Context → Connections

Start at a known location. Explore outward with LSP, then search for parallel patterns.

## Tool access

ripvec exposes the same tool surface to both hosts; only the call syntax differs.

**In Claude Code**, MCP tools are deferred. Load them via `ToolSearch`:

```
ToolSearch("ripvec")                            # discover the active namespace
ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search,mcp__ripvec__find_similar,mcp__ripvec__find_duplicates")
```

Use the **native `LSP()` tool** for call-hierarchy and reference operations when a language server is configured. The ripvec MCP `lsp_*` tools are the fallback when there is no native LSP wired up:

```
ToolSearch("select:mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_hover,mcp__ripvec__lsp_goto_definition,mcp__ripvec__lsp_references,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls")
```

**In Codex**, tools are resolved by bare names — call `find_similar`, `find_duplicates`, `lsp_incoming_calls`, etc. directly. Codex has no native LSP integration; the ripvec MCP `lsp_*` tools ARE the LSP path.

**Index lifecycle.** The ripvec engine builds its in-memory index on first query and keeps it for the MCP process lifetime. CPU-only Model2Vec; no on-disk cache, no warm/cold distinction.

## When to use

- "What calls this function?" → LSP `incoming_calls`
- "What does this function call?" → LSP `outgoing_calls`
- "Find all uses of this struct" → LSP `find_references`
- "Find code similar to this" → `find_similar`
- "What's the blast radius of changing this?" → this full workflow
- "Are there duplicates of this?" → `find_duplicates`

## The pattern

```
document_symbol(file)              # see what's in the file
incoming_calls(function)           # who depends on this
outgoing_calls(function)           # what this depends on
get_repo_map(focus_file: file)     # structural neighborhood
find_similar(file, line)           # parallel implementations
find_duplicates(threshold: 0.5)    # codebase-wide near-copies (raise to 0.90 for exact-copy focus)
```

Both flows consume the same `lsp_location` shape returned by ripvec semantic tools and repo-map entries. Use native `LSP()` in Claude Code when it's available; use ripvec MCP `lsp_*` tools in Codex or any host without native LSP.

### Step 1: Understand the local structure

```
# Claude Code (native):
LSP(method: "textDocument/documentSymbol", ...)

# Codex (MCP):
lsp_document_symbols(file_path: "src/auth/middleware.rs")
```

See every function, field, constant. Identify the function being changed.

### Step 2: Trace the call graph

```
prepare_call_hierarchy(lsp_location)   # build a call-hierarchy item for the symbol
incoming_calls(call_item)              # every function that calls this
outgoing_calls(call_item)              # every function this calls
find_references(lsp_location)          # all usage sites
```

These use ripvec's function-level call graph — backed by PageRank, not just text matching. Available for all 21 supported languages.

### Step 3: See the structural neighborhood

```
get_repo_map(focus_file: "src/auth/middleware.rs", max_tokens: 1500)
```

Topic-sensitive PageRank concentrates on the focus file's callers and callees. Shows which other files are structurally connected.

### Step 4: Find parallel implementations

```
find_similar(file: "src/auth/middleware.rs", line: 42, top_k: 10)
```

Finds code with similar embeddings — different implementations of the same pattern. If you're changing a function signature, these likely need the same change.

### Step 5: Check for duplicates

```
find_duplicates(threshold: 0.5)
```

Near-exact copies (>0.90) are likely copy-paste that should be refactored. Similar patterns (0.75-0.90) may need coordinated changes. The default threshold is 0.5 (recalibrated post-v3.1); use a higher value to focus on tighter matches. Add `intra_file: true` to also surface same-file duplicates.

## Safety checklist before a structural change

- [ ] `incoming_calls` (native or MCP) — identify all direct callers
- [ ] `find_references` (native or MCP) — all usage sites (including type annotations)
- [ ] `find_similar` — parallel implementations needing the same change
- [ ] `get_repo_map(focus_file)` — structural neighborhood
- [ ] Run tests on the dependency neighborhood, not just the changed file

## Don't

- Change a function signature without checking `incoming_calls` first
- Assume only one file is affected
- Skip `find_similar` — copy-paste code is everywhere
- Use Grep to find "who uses this" — use LSP `find_references`
- Treat `search` or `get_repo_map` results as fully grounded until their `lsp_location` has been resolved through native `LSP()` or ripvec MCP `lsp_*` tools
