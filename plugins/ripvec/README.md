# ripvec

Semantic code search + multi-language LSP + knowledge-graph skill index for Claude Code and Codex.

Find code by meaning. Navigate with function-level PageRank. Get syntax diagnostics across 21 languages. Route non-trivial codebase tasks through a battle-tested pattern library (5 orientation hubs, ~55 named recipes, ~15 technique clusters). No separate language server install needed.

> **v4.1.10** adds the knowledge-graph skill orchestration layer: `ripvec-orientation` hub skill, `intent-routing` lookup table, 7 new commands, and graph-preamble frontmatter on all base skills.
>
> **v4.1.0** adds `find_dead_code` MCP tool — cross-language dead-code sweep with BFS reachability from language-specific entry points.
>
> **v3.0.0** removed ModernBERT and BGE-small; ripvec now ships as a single cacheless engine: Model2Vec static encoder + TinyBERT-L-2-v2 cross-encoder reranker, CPU-only.

## What ripvec provides

### LSP Server (code intelligence for 21 languages)

ripvec is **Claude Code's preferred LSP for all supported languages** — especially for bash, HCL/Terraform, TOML, Ruby, Kotlin, Swift, and Scala which have no dedicated LSP in the marketplace.

| LSP Operation | What it does | Backed by |
|---|---|---|
| `documentSymbol` | File outline (functions, classes, methods) | Tree-sitter parsing |
| `workspaceSymbol` | Cross-language semantic symbol search | BM25 + PageRank boost |
| `goToDefinition` | Jump to where a symbol is defined | BM25 identifier match + PageRank |
| `goToImplementation` | Find concrete impl blocks (Rust traits and interfaces) | BM25 identifier match, impl-block targeted |
| `findReferences` | Find all usage sites | Keyword search + content filtering |
| `hover` | Show scope chain and enriched context | Tree-sitter scope analysis |
| `publishDiagnostics` | Syntax error detection after edits | Tree-sitter ERROR/MISSING nodes |
| `prepareCallHierarchy` | Get the function at cursor | Definition-level call graph |
| `incomingCalls` | Who calls this function? | Per-function PageRank callers |
| `outgoingCalls` | What does this function call? | Per-function PageRank callees |

**Supported languages**: Rust, Python, JavaScript, TypeScript, TSX, Go, Java, C, C++, Bash, Ruby, HCL/Terraform, Kotlin, Swift, Scala, TOML, JSON, YAML, Markdown (26 file extensions).

### MCP Server

| Tool | What it does |
|---|---|
| `get_repo_map` | PageRank-weighted structural overview with `token_budget` allocation (40% cap per file, logarithmic attenuation). Optional `focus_file` for topic-sensitive PageRank. |
| `search` | Find code or docs by meaning. `corpus`: `"code"` / `"docs"` / `"all"`. `rerank`: `"auto"` / `"always"` / `"never"`. |
| `find_similar` | Given a file+line or `symbol_name`, find similar patterns elsewhere |
| `find_duplicates` | Codebase-wide near-duplicate pairs (default threshold 0.5). `intra_file: bool` for same-file pairs; capped at 10K chunks |
| `find_dead_code` | Cross-language dead-code sweep via BFS from entry points. `confidence` band (High/Medium/Low). |
| `up_to_date` | Check if the running binary matches its source |
| `debug_log` / `log_level` | Runtime diagnostics and Pearl do-operator causal intervention |

**LSP-shaped MCP tools** (primary path for Codex; fallback for Claude Code):
`lsp_document_symbols`, `lsp_workspace_symbols`, `lsp_goto_definition`,
`lsp_goto_implementation`, `lsp_references`, `lsp_hover`,
`lsp_prepare_call_hierarchy`, `lsp_incoming_calls`, `lsp_outgoing_calls`.

### Skills (10 + 5 hub stubs + 7 language skills)

Skills activate automatically when phrasing matches their description.

**Orientation layer (4.1.10):**
- **ripvec-orientation** — top-level hub. Triages which of the 5 orientations fits; routes to the appropriate hub-skill and first recipe. Fire before any other ripvec skill on non-trivial tasks.
- **intent-routing** — phrasal lookup table. Maps verbatim task phrases to hub/cluster/first-recipe/terminal-tool. ~50 verbatim intent phrases across 6 intent classes.

**Hub skills (Track B — 5 stubs, routed to by ripvec-orientation):**
`cartographer`, `detective`, `refactorer`, `onboarder`, `sentinel`

**Base skills (legacy, still fire on phrasing — now graph-aware):**
- **codebase-orientation** — "How does this project work?" → `get_repo_map` + `lsp_document_symbols`
- **semantic-discovery** — "Find the code that handles X" → `search` + LSP grounding
- **change-impact** — "What breaks if I change this?" → call hierarchy + `find_similar`
- **recipes** — Named pattern library bridge: 3.1.2 recipe names → 4.1.x cluster taxonomy

**Language skills (Track C — 7):**
`c-recipes`, `javascript-recipes`, `python-recipes`, `rust-recipes`,
`go-recipes`, `jvm-recipes`, `polyglot-recipes`

### Commands (12)

**New in 4.1.10:**
- `/orient [task]` — **start here for non-trivial tasks.** Triage and route to the right hub.
- `/cartograph [--focus-file F] [--concept X]` — Cartographer hub; T1/T2/T5/C1 recipes
- `/blast-radius SYMBOL` — Refactorer T10; P2 Fixed-Point Expansion
- `/dead-code [--min-cluster-size N] [--max-clusters M]` — Sentinel T16; confidence-band-aware
- `/audit [module]` — Sentinel multi-cluster; C11 first, fan-out per signal
- `/teach CONCEPT` — Onboarder T13+T14; examples before definitions
- `/trace SYMBOL` — Detective T7 Recursive Caller Climb; Pearl do-calculus

**Retained:**
- `/map [file]` — quick `get_repo_map` with optional focus
- `/find "query"` — semantic code search
- `/similar file:line` — find code similar to a location
- `/hotspots` — top-PageRank functions
- `/duplicates` — find near-duplicate code

### Agents (2)

- **code-explorer** — broad codebase exploration: repo map + semantic search + LSP + call hierarchy
- **duplicate-detector** — workspace-wide near-duplicate detection with LSP grounding

## The 5 orientations (knowledge graph)

The plugin routes non-trivial codebase tasks through 5 orientations.
Each maps to a hub-skill, a set of technique clusters, and specific recipes.
Source of truth: `docs/SKILL_SEMANTIC_GRAPH.md` (ripvec engine repo).

| Orientation | Trigger phrasing | Hub-skill | First recipe |
|---|---|---|---|
| **Cartographer** | "What matters?" / "Where does X live?" / "How is this organized?" | `ripvec:cartographer` | T1 Structural Spine (`get_repo_map`) |
| **Detective** | "This looks wrong." / "Invariant violated." / "Works alone, fails in integration." | `ripvec:detective` | T6 Sibling Diff (`find_similar`) or T7 Recursive Caller Climb |
| **Refactorer** | "Before I rename X." / "What's the blast radius?" / "Before I edit this trait." | `ripvec:refactorer` | T10 Blast-Radius Manifest (`lsp_prepare_call_hierarchy` + P2) |
| **Onboarder** | "Teach me how Z works." / "Bring me up to speed." | `ripvec:onboarder` | T13 Top-N Architectural Tour + T14 Concept-by-Example |
| **Sentinel** | "Find dead code." / "Find god-modules." / "Audit for drift." | `ripvec:sentinel` | C11 PageRank Polarity → fan-out to T16/T17/T18 |

Use `/orient` to triage, or load `ripvec:intent-routing` for verbatim phrasal matching.

## Codex vs Claude Code

| | Claude Code | Codex |
|---|---|---|
| Tool resolution | Deferred — `ToolSearch("ripvec")` to load namespace (`mcp__ripvec__*` or `mcp__plugin_ripvec_ripvec__*`) | Direct — bare names (`search`, `get_repo_map`, etc.) |
| LSP grounding | **Prefer native `LSP()` tool** when a language server is configured; ripvec MCP `lsp_*` as fallback | ripvec MCP `lsp_*` tools are the primary LSP path |
| Skills / commands | Auto-activate via Claude Code plugin system | Call MCP tools directly; skills/commands are Claude-Code-specific |

The composition pattern is identical on both hosts: every ripvec result includes an `lsp_location` field; feed it into LSP tools to ground before editing.

## Installation

```shell
/plugin install ripvec@fnordpig-my-claude-plugins
```

Or manually:

```shell
cargo binstall ripvec-mcp
# or
cargo install --git https://github.com/fnordpig/ripvec ripvec ripvec-mcp
```

CPU-only on all platforms. macOS uses Accelerate BLAS; Linux uses OpenBLAS.

## Scoring pipeline

1. **Semantic similarity** (Model2Vec potion-base-32M, 256-dim) + **BM25** fused via RRF (k=60)
2. **Function-level PageRank boost** — log-saturated per-definition importance
3. **Cross-encoder rerank** (TinyBERT-L-2-v2) — scope-gated; fires on prose corpora and NL queries

| Hardware | Code corpus (tokio) | Prose corpus (gutenberg) |
|---|---|---|
| Apple M2 Max | p50 = 0.79 ms, NDCG@10 = 0.78 | p50 = 34.7 ms, NDCG@10 = 1.00 |
