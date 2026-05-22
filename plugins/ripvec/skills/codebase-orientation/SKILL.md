---
name: codebase-orientation
description: "ALWAYS use this skill instead of reading files sequentially when starting work on unfamiliar code. This skill MUST be used before Read or Glob for orientation tasks. Triggers on: 'how does this project work', 'explain the architecture', 'show me the structure', 'where should I start', 'what are the main modules'. Use ripvec's get_repo_map and LSP document_symbol instead of listing directories or reading files one by one."
---

# Codebase Orientation

When you need to understand how a project is structured — which files are central, what depends on what, where the key abstractions live — use `get_repo_map` before reading individual files.

## Tool access

ripvec exposes the same tool surface to both hosts; only the call syntax differs.

**In Claude Code**, MCP tools are deferred. Load them via `ToolSearch`:

```
ToolSearch("ripvec")                            # discover the active namespace
ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search,mcp__ripvec__index_status")
```

The namespace is either `mcp__ripvec__*` (project-level) or `mcp__plugin_ripvec_ripvec__*` (plugin). Claude Code users should prefer the **native `LSP()` tool** when grounding repo-map entries — it talks to whichever LSP server is configured (ripvec, rust-analyzer, gopls, etc.).

When no native LSP is configured, load ripvec's MCP `lsp_*` tools as the fallback:

```
ToolSearch("select:mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_hover,mcp__ripvec__lsp_goto_definition,mcp__ripvec__lsp_references,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls")
```

**In Codex**, tools are resolved by bare names — call `get_repo_map`, `search`, `lsp_document_symbols`, etc. directly. No `ToolSearch`, no prefix. Codex has no native LSP integration; the ripvec MCP `lsp_*` tools ARE the LSP path.

**Index lifecycle.** The ripvec engine builds its in-memory index on first query against a root and keeps it for the MCP process lifetime. CPU-only Model2Vec static encoder; no on-disk cache, no warm/cold distinction, no manifest to manage. `index_status` reports liveness if you want to confirm the server is up.

## Why this matters

Reading files one by one to understand architecture is slow and expensive. A single `get_repo_map` call returns a function-level PageRank overview showing:
- Which files and functions are structurally central (called by many others)
- Key definitions (traits, structs, functions) with signatures
- Call graph flow (who calls whom at the function level)

This replaces 10+ sequential `Read` operations with one tool call.

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

`get_repo_map`, `search`, and `find_similar` return `lsp_location` data on every result. Use it to ground architectural guesses in symbol-aware navigation.

- **Claude Code**: pass the locations to the native `LSP()` tool — `document_symbol`, `go_to_definition`, `hover`, `find_references`, call hierarchy.
- **Codex (or any host without native LSP)**: pass the same shapes to ripvec MCP `lsp_document_symbols`, `lsp_workspace_symbols`, `lsp_hover`, `lsp_goto_definition`, `lsp_references`, `lsp_prepare_call_hierarchy`, `lsp_incoming_calls`, `lsp_outgoing_calls`.

ripvec MCP LSP responses return ripvec-style `results[]` plus `lsp.raw_response`. The `results[].lsp_location` values can be fed directly back into either native `LSP()` or the MCP `lsp_*` tools.

ripvec provides LSP code intelligence for all 21 supported languages. After identifying key files from the repo map:

- `document_symbol` — full symbol outline of a file (functions, classes, methods). Works for ALL ripvec-supported languages including bash, HCL, TOML, Ruby, Kotlin, Swift, Scala.
- `go_to_definition` — jump to where a symbol is defined.
- `hover` — scope chain and context for a symbol.
- `incoming_calls` / `outgoing_calls` — trace call chains through the function-level PageRank graph.

## Examples across languages

**Rust monorepo**: "How does the backend trait system work?"
→ `get_repo_map` shows `backend/mod.rs` as high-rank with trait definition, then each backend impl file as callees

**Django project**: "Where do I start understanding this app?"
→ `get_repo_map` shows `urls.py` and `models.py` as most-imported, `views.py` as primary caller — read in that order

**Terraform infrastructure**: "What resources depend on what?"
→ `get_repo_map` shows which `.tf` files are central. Native `LSP() document_symbol` or ripvec MCP `lsp_document_symbols` lists all resource/data/variable blocks per file. **ripvec is the only LSP that covers HCL.**

**React + Express full-stack**: "How does the frontend talk to the backend?"
→ `get_repo_map` reveals the API boundary: `api/routes/index.ts` as the hub, `src/hooks/useApi.ts` as the frontend entry point

## When NOT to use this

- You already know the file you need → just `Read` it
- You need an exact string → use `Grep`
- You need a specific symbol definition → use native `LSP() go_to_definition` (Claude) or `lsp_goto_definition` (Codex)

Orientation is for the "I don't know where to start" moment. Once oriented, switch to precise tools.
