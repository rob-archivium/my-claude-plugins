# ripvec

Semantic code search for Claude Code — find code by meaning, understand architecture through dependency graphs.

## Installation

```shell
# 1. Install the MCP server (requires Rust toolchain)
cargo install --git https://github.com/fnordpig/ripvec ripvec-mcp

# With NVIDIA GPU acceleration (Linux, requires CUDA toolkit):
cargo install --git https://github.com/fnordpig/ripvec ripvec-mcp --features cuda

# 2. Install the plugin
/install github:fnordpig/my-claude-plugins/plugins/ripvec
```

The plugin checks for `ripvec-mcp` at session start and shows install instructions if missing.

### What you get per platform

| Platform | Default backends | Opt-in |
|----------|-----------------|--------|
| macOS | Metal + MLX + CPU (Accelerate) | — |
| Linux | CPU (OpenBLAS) | `--features cuda` for NVIDIA GPU |

### Prerequisites

- [Rust toolchain](https://rustup.rs/) (for building ripvec-mcp)
- macOS: Xcode Command Line Tools (provides Metal framework)
- Linux + CUDA: NVIDIA CUDA toolkit (for `--features cuda`)

## What You Get

### MCP Server (6 tools)

| Tool | What it does |
|------|-------------|
| `get_repo_map` | PageRank-weighted structural overview — shows which files matter most |
| `search_code` | Find code by meaning, not text. "retry with backoff" finds the implementation |
| `search_text` | Same but for docs/comments |
| `find_similar` | Given a file+line, find similar patterns elsewhere |
| `reindex` | Force re-embedding (auto-updates on file change) |
| `index_status` | Check readiness |

### Skills (3)

Skills activate automatically when Claude Code encounters matching tasks:

- **codebase-orientation** — Triggers on "how does this project work", "explain the architecture". Uses `get_repo_map` to orient before reading files.
- **semantic-discovery** — Triggers on "find the code that handles X". Guides Claude to use `search_code` instead of Grep for conceptual queries.
- **change-impact** — Triggers on "what breaks if I change this". Combines `get_repo_map(focus_file)` + LSP `findReferences` + `find_similar` for full blast radius.

### Commands (2)

- `/ripvec:map [file]` — Quick structural overview (optional focus file)
- `/ripvec:find "query"` — Semantic code search

### Agent (1)

- **code-explorer** — Deep codebase exploration combining repo map, semantic search, and LSP navigation

## Performance

| Hardware | Model | Throughput |
|----------|-------|-----------|
| NVIDIA RTX 4090 | ModernBERT | 435 chunks/s |
| Apple M2 Max | ModernBERT | 73.8 chunks/s |
| CPU (Accelerate) | ModernBERT | 73.5 chunks/s |

## Supported Languages

Tree-sitter parsing for definitions + imports:
Rust, Python, JavaScript/TypeScript, Go, Java, C/C++

Semantic search works on any text file — the embedding model understands code semantics regardless of language.
