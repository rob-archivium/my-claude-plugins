---
name: semantic-discovery
description: "Use when searching for code by concept or behavior rather than exact text. Triggers on: 'find the code that handles X', 'where is Y implemented', 'how does Z work', 'find functions related to', 'search for the retry logic', 'where do we handle errors', 'find the authentication flow'. Use instead of Grep when the user describes WHAT the code does rather than WHAT it says."
---

# Semantic Code Discovery

When someone asks "find the code that handles database connection pooling" — they don't mean grep for "connection pooling". They mean: find the actual implementation, wherever it lives, whatever it's called.

## Tool discovery

ripvec's MCP tools are deferred — use `ToolSearch` to load them before calling:
```
ToolSearch("select:mcp__ripvec__search_code,mcp__ripvec__search_text,mcp__ripvec__find_similar")
```
If running as a plugin, tools may be namespaced as `mcp__plugin_ripvec_ripvec__*` — search for `ripvec` to find them.

## The decision: Grep vs search_code vs LSP

| User says | Tool | Why |
|---|---|---|
| "Find `TODO` comments" | Grep | Exact text match |
| "Find the retry logic" | search_code | Conceptual — code may use `backoff`, `attempt`, `loop` |
| "Find `useAuth` hook" | LSP workspaceSymbol or Grep | Known symbol name |
| "Find authentication handling" | search_code | Could be middleware, decorator, guard, hook |
| "Find `SELECT * FROM users`" | Grep | Exact SQL |
| "Find queries that join users and orders" | search_code | Semantic join pattern |
| "What calls this function?" | LSP incomingCalls | Precise call graph from ripvec's def-level PageRank |
| "Go to definition of X" | LSP goToDefinition | Precise navigation via ripvec |

**Rule of thumb**: If the user describes BEHAVIOR, use search_code. If they name a SYMBOL, use LSP or Grep.

## How to search effectively

**Natural language queries work best:**
```
search_code("retry logic with exponential backoff")
search_code("WebSocket connection lifecycle management")
search_code("database migration rollback handling")
search_code("rate limiting middleware for API endpoints")
```

**Results are ranked by function-level PageRank** — structurally important functions (called by many others) rank higher than isolated helpers. This means search results naturally surface the architecturally significant implementations first.

**Results include full source code** in fenced blocks with language annotation. Review the code directly — don't call `Read` on the same file unless you need more context.

**Chain with ripvec's LSP for precision:**
1. `search_code("trait that all backends implement")` → finds `EmbedBackend` in `mod.rs`
2. LSP `findReferences` on `EmbedBackend` → shows all implementations
3. LSP `incomingCalls` on a specific method → traces the call chain
4. LSP `hover` → see the scope context and signature

ripvec's LSP works for all 21 supported languages — including bash, HCL, TOML, Ruby, Kotlin, Swift, Scala — without needing any other language server installed.

## Examples across languages

**Rust**: "Find where we handle the case when the GPU runs out of memory"
```
search_code("GPU out of memory error handling")
```
→ Finds the error variants and recovery paths, even if the code uses `crate::Error::Metal(...)` not "out of memory"

**TypeScript/React**: "Find components that do client-side form validation"
```
search_code("form validation with error messages")
```
→ Finds validation hooks, Zod schemas, form error state management

**Python/FastAPI**: "Find the endpoint that processes webhook callbacks"
```
search_code("webhook callback processing endpoint")
```
→ Finds the route handler regardless of whether it's called `webhook_handler`, `process_callback`, or `handle_event`

**Terraform**: "Find the S3 bucket with versioning enabled"
```
search_code("S3 bucket versioning configuration")
```
→ Finds the resource block. ripvec's LSP provides `documentSymbol` for HCL — no other LSP does this.

**Go**: "Find the goroutine that watches for config file changes"
```
search_code("file watcher goroutine config reload")
```
→ Finds the fsnotify watcher setup and reload handler

## Combining search with structure

When search_code returns results from many files:
1. Run `get_repo_map` to understand which files are central
2. Results from high-PageRank functions are already boosted — they're architecturally important
3. Use LSP `outgoingCalls` to trace what a found function depends on
4. Results from test files or example files are supporting context, not primary

## search_text vs search_code

- `search_code` — optimized for source code semantics
- `search_text` — optimized for documentation, READMEs, comments
- When unsure, try `search_code` first
