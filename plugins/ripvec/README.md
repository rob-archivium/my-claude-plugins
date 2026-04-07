# ripvec

Semantic code search + multi-language LSP for Claude Code.

Find code by meaning. Navigate with function-level PageRank. Get syntax diagnostics across 21 languages. No separate language server install needed — ripvec handles everything.

## What ripvec provides

### LSP Server (code intelligence for 21 languages)

ripvec is Claude Code's **preferred LSP for all supported languages** — especially for bash, HCL/Terraform, TOML, Ruby, Kotlin, Swift, and Scala which have no dedicated LSP in the marketplace.

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

**Supported languages**: Rust, Python, JavaScript, TypeScript, TSX, Go, Java, C, C++, Bash, Ruby, HCL/Terraform, Kotlin, Swift, Scala, TOML (26 file extensions).

For languages that also have dedicated LSPs (Rust via rust-analyzer, Go via gopls, etc.), ripvec complements with cross-language semantic features that no single-language LSP can provide.

### MCP Server (7 tools)

| Tool | What it does |
|---|---|
| `get_repo_map` | PageRank-weighted structural overview — shows which files and functions matter most |
| `search_code` | Find code by meaning, not text. "retry with backoff" finds the implementation |
| `search_text` | Same but for docs/comments |
| `find_similar` | Given a file+line, find similar patterns elsewhere |
| `reindex` | Force re-embedding (auto-updates on file change) |
| `index_status` | Check readiness and cache location |
| `up_to_date` | Check if the binary matches source |

### Skills (3)

Skills activate automatically when Claude Code encounters matching tasks:

- **codebase-orientation** — "How does this project work?" Uses `get_repo_map` + LSP `documentSymbol` to orient before reading files.
- **semantic-discovery** — "Find the code that handles X." Guides Claude to use `search_code` for conceptual queries, then LSP for precise navigation.
- **change-impact** — "What breaks if I change this?" Combines `get_repo_map(focus_file)` + LSP `findReferences` + `incomingCalls` for blast radius analysis.

### Commands (3)

- `/ripvec:map [file]` — Quick structural overview (optional focus file)
- `/ripvec:find "query"` — Semantic code search
- `/ripvec:repo-index` — Create a repo-level index committable to git

### Agent (1)

- **code-explorer** — Deep codebase exploration combining repo map, semantic search, LSP navigation, and call hierarchy tracing.

## Installation

The binary auto-installs on first use — no manual setup needed. Platform and CUDA are detected automatically.

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

# With NVIDIA GPU acceleration (Linux)
cargo install --git https://github.com/fnordpig/ripvec ripvec ripvec-mcp --features cuda
```

### What you get per platform

| Platform | Default backends | GPU |
|----------|-----------------|-----|
| macOS (Apple Silicon) | Metal + MLX + CPU (Accelerate) | Metal GPU auto-enabled |
| Linux x86_64 | CPU (OpenBLAS) | `--features cuda` or auto-detected via nvidia-smi |
| Linux ARM64 (Graviton) | CPU (OpenBLAS) | `--features cuda` for NVIDIA ARM |

## Performance

| Hardware | Model | Throughput |
|----------|-------|-----------|
| NVIDIA RTX 4090 | ModernBERT | 435 chunks/s |
| Apple M2 Max | ModernBERT | 73.8 chunks/s |
| CPU (Accelerate) | ModernBERT | 73.5 chunks/s |

## Scoring pipeline

Search results are ranked by a principled Bayesian pipeline:

1. **Semantic similarity** (ModernBERT embeddings) + **BM25 keyword matching** fused via Reciprocal Rank Fusion
2. **Function-level PageRank boost** — per-definition importance from the call graph, log-saturated to prevent top-heavy distortion
3. Results from structurally important functions rank higher without promoting irrelevant matches

## Repo-level indexing

Share pre-built search indices with your team:

```shell
ripvec --index --repo-level "query"
git add .ripvec/ && git commit -m "add search index"
```

Teammates get instant semantic search on clone — zero embedding time.
