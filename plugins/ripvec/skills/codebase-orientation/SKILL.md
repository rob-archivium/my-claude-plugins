---
name: codebase-orientation
description: "ALWAYS use this skill instead of reading files sequentially when starting work on unfamiliar code. This skill MUST be used before Read or Glob for orientation tasks. Triggers on: 'how does this project work', 'explain the architecture', 'show me the structure', 'where should I start', 'what are the main modules'. Use ripvec's get_repo_map and LSP documentSymbol instead of listing directories or reading files one by one."
---

# Codebase Orientation

When you need to understand how a project is structured — which files are central, what depends on what, where the key abstractions live — use `get_repo_map` before reading individual files.

## Tool discovery and readiness

ripvec's MCP tools are deferred — use `ToolSearch` to load them before calling:
```
ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search_code,mcp__ripvec__index_status")
```
When grounding repo-map entries on a host without native LSP, also load:
```
ToolSearch("select:mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_hover,mcp__ripvec__lsp_goto_definition,mcp__ripvec__lsp_references,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls")
```
If running as a plugin, tools may be namespaced as `mcp__plugin_ripvec_ripvec__*` — search for `ripvec` to find them.

**Check index readiness first.** Call `index_status` before searching. If it returns `"indexing": true`, the response includes phase, percentage, and ETA (e.g., "embedding 1200/2383 files (50%, ~16s remaining)"). Wait for indexing to complete — results will be incomplete or empty while building. For small repos this takes 1-3 seconds; for large repos up to 30 seconds.

## Why this matters

Reading files one by one to understand architecture is slow and expensive. A single `get_repo_map` call returns a function-level PageRank overview showing:
- Which files and functions are structurally central (called by many others)
- Key definitions (traits, structs, functions) with signatures
- Call graph flow (who calls whom at the function level)

This replaces 10+ sequential Read operations with one tool call.

## How to orient

**Step 1: Get the structural overview**
```
get_repo_map(max_tokens: 2000)
```
The output ranks files by structural importance. The top files are the architectural spine — read these first.

**Step 2: Zoom into the area you're working on**
```
get_repo_map(focus_file: "src/auth/middleware.ts", max_tokens: 1500)
```
Topic-sensitive PageRank concentrates on the focus file's neighborhood — what it depends on and what depends on it.

**Step 3: Ground repo-map entries with LSP**

`get_repo_map`, `search_code`, `search_text`, and `find_similar` return
`lsp_location` data where possible. Use it to ground architectural guesses in
symbol-aware navigation:

- In Claude Code, pass the locations to native LSP operations:
  `documentSymbol`, `goToDefinition`, `hover`, `findReferences`, and call
  hierarchy.
- In Codex or any host without native LSP, pass the same shapes to ripvec MCP
  tools: `lsp_document_symbols`, `lsp_workspace_symbols`, `lsp_hover`,
  `lsp_goto_definition`, `lsp_references`, `lsp_prepare_call_hierarchy`,
  `lsp_incoming_calls`, and `lsp_outgoing_calls`.
- ripvec MCP LSP responses return ripvec-style `results[]` plus
  `lsp.raw_response`. The `results[].lsp_location` values can be fed directly
  back into either native LSP or the MCP LSP tools.

ripvec provides LSP code intelligence for all supported languages. After
identifying key files from the repo map:

- `document symbols` — get the full symbol outline of a file (functions,
  classes, methods). Works for all languages ripvec supports including bash,
  HCL, TOML, Ruby, Kotlin, Swift, Scala.
- `go to definition` — jump to where a symbol is defined.
- `hover` — see scope chain and context for a symbol.
- `incoming calls` / `outgoing calls` — trace call chains through the
  function-level graph.

## Examples across languages

**Rust monorepo**: "How does the backend trait system work?"
→ `get_repo_map` shows `backend/mod.rs` as high-rank with trait definition, then each backend impl file as callees

**Django project**: "Where do I start understanding this app?"
→ `get_repo_map` shows `urls.py` and `models.py` as most-imported, `views.py` as primary caller — read in that order

**Terraform infrastructure**: "What resources depend on what?"
→ `get_repo_map` shows which `.tf` files are central. Native
`documentSymbol` or ripvec `lsp_document_symbols` lists all
resource/data/variable blocks per file. ripvec provides this — no other LSP
covers HCL.

**React + Express full-stack**: "How does the frontend talk to the backend?"
→ `get_repo_map` reveals the API boundary: `api/routes/index.ts` as the hub, `src/hooks/useApi.ts` as the frontend entry point

## When NOT to use this

- You already know the file you need → just `Read` it
- You need an exact string → use `Grep`
- You need a specific symbol definition → use native `goToDefinition` or
  ripvec `lsp_goto_definition`

Orientation is for the "I don't know where to start" moment. Once oriented, switch to precise tools.
