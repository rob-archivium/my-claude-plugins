# ripvec

Semantic code search + multi-language LSP for Claude Code and Codex.

Find code by meaning. Navigate with function-level PageRank. Get syntax diagnostics across 21 languages. No separate language server install needed — ripvec handles everything.

> **v3.0.0** removed the optional ModernBERT and BGE-small transformer bi-encoders. ripvec now ships as a single cacheless engine: Model2Vec static encoder + TinyBERT-L-2-v2 cross-encoder reranker, CPU-only. See `CHANGELOG.md` for the breaking-change boundary.

## What ripvec provides

### LSP Server (code intelligence for 21 languages)

ripvec is **Claude Code's preferred LSP for all supported languages** — especially for bash, HCL/Terraform, TOML, Ruby, Kotlin, Swift, and Scala which have no dedicated LSP in the marketplace.

| LSP Operation | What it does | Backed by |
|---|---|---|
| `documentSymbol` | File outline (functions, classes, methods) | Tree-sitter parsing |
| `workspaceSymbol` | Cross-language semantic symbol search | BM25 + PageRank boost |
| `goToDefinition` | Jump to where a symbol is defined | BM25 identifier match + PageRank |
| `goToImplementation` | Find concrete implementations | Same as definition |
| `findReferences` | Find all usage sites | Keyword search + content filtering |
| `hover` | Show scope chain and enriched context | Tree-sitter scope analysis |
| `publishDiagnostics` | Syntax error detection after edits | Tree-sitter ERROR/MISSING nodes |
| `prepareCallHierarchy` | Get the function at cursor | Definition-level call graph |
| `incomingCalls` | Who calls this function? | Per-function PageRank callers |
| `outgoingCalls` | What does this function call? | Per-function PageRank callees |

**Supported languages**: Rust, Python, JavaScript, TypeScript, TSX, Go, Java, C, C++, Bash, Ruby, HCL/Terraform, Kotlin, Swift, Scala, TOML, JSON, YAML, Markdown (26 file extensions).

For languages that also have dedicated LSPs (Rust via rust-analyzer, Go via gopls, etc.), ripvec **complements** with cross-language semantic features no single-language LSP can provide.

### MCP Server

| Tool | What it does |
|---|---|
| `get_repo_map` | PageRank-weighted structural overview — shows which files and functions matter most |
| `search` | Find code or docs by meaning. `scope`: `"code"` (skips docs, no rerank), `"docs"` (prose only, cross-encoder rerank on NL queries), `"all"` (default; rerank fires when corpus ≥30% prose). `include_extensions` / `exclude_extensions` narrow further |
| `find_similar` | Given a file+line, find similar patterns elsewhere |
| `find_duplicates` | Codebase-wide near-duplicate pairs above a similarity threshold |
| `reindex` | Force a fresh in-memory rebuild |
| `index_status` | Confirm the MCP server is up; report chunk/file counts |
| `up_to_date` | Check if the running binary matches its source |
| `debug_log` / `log_level` | Runtime diagnostics |

**LSP-shaped MCP tools** (for hosts without a native LSP integration — notably Codex):

| Tool | LSP equivalent |
|---|---|
| `lsp_document_symbols` | `documentSymbol` |
| `lsp_workspace_symbols` | `workspaceSymbol` |
| `lsp_goto_definition` | `goToDefinition` |
| `lsp_goto_implementation` | `goToImplementation` |
| `lsp_references` | `findReferences` |
| `lsp_hover` | `hover` |
| `lsp_prepare_call_hierarchy` | `prepareCallHierarchy` |
| `lsp_incoming_calls` | `incomingCalls` |
| `lsp_outgoing_calls` | `outgoingCalls` |

The ripvec engine (Model2Vec static encoder + TinyBERT cross-encoder reranker) builds its in-memory index on first query and keeps it for the MCP process lifetime. **There is no on-disk cache.** CPU-only; no GPU dependencies.

### Skills (3)

Skills activate automatically when phrasing matches their description:

- **codebase-orientation** — "How does this project work?" Routes to `get_repo_map` + LSP `document_symbol` before any file reads.
- **semantic-discovery** — "Find the code that handles X." Routes to `search` for conceptual queries, then LSP for grounding.
- **change-impact** — "What breaks if I change this?" Combines `get_repo_map(focus_file)` + LSP `incoming_calls` / `find_references` + `find_similar` for blast-radius analysis.

### Commands (7)

- `/ripvec:orientation` — **start here.** Overview of ripvec, when to use which tool, MCP↔LSP composition, search scoping.
- `/ripvec:map [file]` — quick structural overview (optional focus file)
- `/ripvec:find "query"` — semantic code search
- `/ripvec:similar file:line` — find code similar to a location
- `/ripvec:hotspots` — top-PageRank functions (the architectural spine)
- `/ripvec:duplicates` — find near-duplicate code
- `/ripvec:repo-index` — force a fresh in-memory rebuild

### Agents (2)

- **code-explorer** — deep codebase exploration combining repo map, semantic search, LSP navigation, and call-hierarchy tracing
- **duplicate-detector** — workspace-wide near-duplicate detection with LSP grounding

## Codex vs Claude Code

ripvec ships the same tool surface to both hosts; only the call syntax differs.

| | Claude Code | Codex |
|---|---|---|
| Tool resolution | Deferred — use `ToolSearch("ripvec")` to load by namespace (`mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*`) | Direct — call bare names (`search`, `get_repo_map`, `lsp_hover`, etc.) |
| LSP grounding | **Prefer native `LSP()` tool** when a language server is configured; ripvec MCP `lsp_*` tools are the fallback | ripvec MCP `lsp_*` tools are the primary LSP path (no native LSP integration) |
| Skills/commands/agents activation | Automatic via Claude Code plugin system | Skills/agents are Claude-Code-specific; Codex calls the MCP tools directly |

The composition pattern is identical: `search` (or `get_repo_map`, or `find_similar`) returns results with an `lsp_location` field, which you feed into native `LSP()` (Claude) or ripvec MCP `lsp_*` (Codex) to ground the candidate symbol before editing.

## Installation

The binary auto-installs on first use — no manual setup needed.

```shell
# Install the plugin
/plugin install ripvec@fnordpig-my-claude-plugins
```

### Manual binary install (alternative)

```shell
# Pre-built binary (recommended)
cargo binstall ripvec-mcp

# Or build from source
cargo install --git https://github.com/fnordpig/ripvec ripvec ripvec-mcp
```

Single platform path post-v3.0.0: ripvec is CPU-only on all platforms. macOS uses Accelerate BLAS; Linux uses OpenBLAS. No CUDA / Metal / MLX builds (those engines were removed in the v3.0.0 surgery).

## Scoring pipeline

Search results are ranked by a principled Bayesian pipeline:

1. **Semantic similarity** (Model2Vec potion-base-32M static encoder, 256-dim) + **BM25 keyword matching** fused via Reciprocal Rank Fusion (k=60)
2. **Function-level PageRank boost** — per-definition importance from the call graph, log-saturated to prevent top-heavy distortion
3. **Cross-encoder rerank** (TinyBERT-L-2-v2) on prose-corpus / NL queries — scope-gated to skip code corpora and symbol-shaped queries

Results from structurally important functions rank higher without promoting irrelevant matches.

## Performance

| Hardware | Code corpus (tokio) | Prose corpus (gutenberg) |
|---|---|---|
| Apple M2 Max | p50 = 0.79 ms, NDCG@10 = 0.78 | p50 = 34.7 ms, NDCG@10 = 1.00 |

(Numbers from `docs/surgery/perf_baseline.json` in the ripvec repo. The cross-encoder rerank is what brings prose NDCG@10 to 1.00; it fires on prose corpora automatically.)
