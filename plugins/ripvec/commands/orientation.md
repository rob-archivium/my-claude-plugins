---
name: orientation
description: Overview of ripvec — when to use which tool, how to compose MCP + LSP, how to scope and filter searches
---

# ripvec: orientation

ripvec is **semantic code search + a generic multi-language LSP**, packaged as one MCP server plus a Language Server Protocol endpoint over stdio. This command is a single-page map: what ripvec offers, which tool to reach for in each situation, and how to compose the MCP and LSP surfaces together.

## What ripvec gives you

**An MCP server** with 8 tools — semantic search, structural maps, similarity, and 9 LSP-shaped tools that work even when no native LSP is available (notably Codex). The engine auto-reconciles on every search: file additions, edits, and deletions are detected via blake3-confirmed mtime/size/inode diff before results are returned — no manual reindex needed.

**An LSP server** (`ripvec-mcp --lsp`) covering **all 21 supported languages**: Rust, Python, JavaScript, TypeScript, TSX, Go, Java, C, C++, Bash, Ruby, HCL/Terraform, Kotlin, Swift, Scala, TOML, JSON, YAML, Markdown — including the ones with no dedicated language server in the marketplace (bash, HCL, TOML, Ruby, Kotlin, Swift, Scala).

The MCP and LSP surfaces share the same underlying index (Model2Vec static encoder, function-level PageRank, tree-sitter parsing). They are designed to compose: MCP gives you the search and structure; LSP gives you the symbol-precise navigation.

## When to use which tool

| Your question | Tool | Why |
|---|---|---|
| "How does this project work?" | `get_repo_map` | PageRank-weighted overview of files and functions |
| "Where is X implemented?" / "Find auth logic" | `search` | Semantic — meaning, not text |
| "What does the docs say about Y?" | `search(scope: "docs")` | Prose-only; cross-encoder reranker fires |
| "Find code matching only `.rs` files" | `search(include_extensions: ["rs"])` | Extension filter |
| "What does this function call?" | LSP `outgoing_calls` (or `lsp_outgoing_calls` MCP) | Function-level call graph |
| "Who calls this function?" | LSP `incoming_calls` (or `lsp_incoming_calls`) | Same call graph, inbound |
| "Show me everything in this file" | LSP `document_symbol` (or `lsp_document_symbols`) | Tree-sitter outline |
| "Jump to where X is defined" | LSP `go_to_definition` (or `lsp_goto_definition`) | Symbol resolution |
| "Find all usages of X" | LSP `find_references` (or `lsp_references`) | All call sites |
| "Find code similar to this line" | `find_similar` | Embedding-similarity search |
| "Find copy-paste in this codebase" | `find_duplicates` | High-similarity pair detection |
| "Find TODO: comments" | Built-in `Grep` / `rg` | Exact strings — ripvec is overkill |
| "Find files matching `*.rs`" | Built-in `Glob` | File path matching |

The first rule: **describe behavior → `search`. Name a specific symbol you already know about → LSP. Look for exact text → Grep.**

## For non-trivial work: invoke the recipes skill

This orientation page is the fast map. For any substantial task — chasing a bug, planning a refactor, auditing a module, teaching a codebase — reach for the **named-pattern library**:

**`Skill ripvec:recipes`**

The library distills a 15-agent brainstorm into a usable pattern language:
- **5 orientations** — Cartographer, Detective, Refactorer, Onboarder, Sentinel
- **15 tactical recipes** with concrete tool sequences (e.g., *Blast-Radius Manifest Before Rename*, *Sibling Diff*, *PageRank-Anchored Concept Tour*, *Cohesion Refraction Test*)
- **8 compositional primitives** — Triangulation, Fixed-Point Expansion, Sibling Diff, Duplicates as Taxonomy, Names as Folk Taxonomy, Causal Intervention, Trait Constellation Survey, PageRank Polarity
- **8 heuristics** — when to reach for which composition (H1: *the map you don't summon costs nothing*, H8: *scope before similarity at scale*, etc.)
- **Empirical revisions** — gotchas learned by running the patterns against real codebases (cursor positioning, the silent 10K-chunk cap, kind-tagging caveats)

Each pattern is **named** so you can refer to it: "I ran a *Blast-Radius Manifest* on the symbol; 38 refs across 21 files; rename lands in 4 commits per the invariant grouping" is more useful in a PR than "I looked at where it's used."

**Read the skill before any substantial codebase task.** It's the canonical place to find the *right* pattern; this orientation page is a quickstart.

The three flagship workflows below are the three most common patterns — *Structural Spine* (Cartographer), *Intent First* (Cartographer/Semantic Discovery), and *Blast-Radius Manifest* (Refactorer). The skill catalog covers thirty more.

## The three flagship workflows

### 1. Codebase orientation (you've never seen this code before)

```
get_repo_map(max_tokens: 2000)              → structural spine
get_repo_map(focus_file: "...", max_tokens: 1500)  → topic-sensitive zoom
LSP document_symbol on the top-ranked files  → full outlines
```

Don't read files sequentially. One `get_repo_map` call replaces 10+ file reads.

### 2. Semantic discovery (find code by behavior)

```
search(query: "JWT validation middleware", scope: "code")  → ranked candidates
LSP go_to_definition on the best match                     → ground the symbol
LSP hover / find_references                                 → understand + verify
```

Every `search` result includes an `lsp_location` field. Pass it to LSP tools to ground the candidate before editing. Vector similarity is not symbol identity.

### 3. Change-impact analysis (you're about to refactor)

```
LSP document_symbol(file)                   → see what's in scope
LSP prepare_call_hierarchy(symbol)          → get call-hierarchy item
LSP incoming_calls(item)                    → blast radius (who depends on this)
LSP outgoing_calls(item)                    → what this depends on
find_similar(file, line)                    → parallel implementations elsewhere
find_duplicates(threshold: 0.5)             → copy-paste candidates (raise to 0.90 for exact-copy focus)
```

Use this **before any signature change, rename, or structural refactor**.

## Composing MCP results with LSP

Every ripvec MCP tool that returns code (`search`, `get_repo_map`, `find_similar`, `find_duplicates`) emits an **`lsp_location`** field per result:

```json
{
  "file_path": "src/auth/middleware.rs",
  "line": 42,
  "character": 4,
  "range": { "start": {...}, "end": {...} }
}
```

This is the bridge. Feed `lsp_location` into LSP tools to:
- **Ground** semantic results in symbol-precise navigation (don't edit based on vector similarity alone)
- **Trace** the call hierarchy outward from the candidate
- **Verify** the result is actually the symbol you want before reading or editing

The reverse also works: LSP tools return locations and ranges that can feed back into `search` (e.g., "find code semantically similar to this exact symbol") via `find_similar(file, line)`.

## Search scoping and filtering

`search` accepts a `scope` argument that controls two things in one switch:
- **Which file extensions** are indexed and searched
- **Whether the cross-encoder reranker fires** (the heavy NL-quality pass)

| `scope` value | Extensions searched | Cross-encoder rerank? |
|---|---|---|
| `"code"` | Code files only (skips `.md`, `.txt`, `.rst`) | **Off** — out-of-domain for code |
| `"docs"` | Prose only (`.md`, `.txt`, `.rst`, `.adoc`) | **On** for NL queries |
| `"all"` (default) | Everything | **On** when the indexed corpus is ≥30% prose |

**Symbol-shaped queries never rerank** (e.g. `ConnectionPool`, `useAuth`) — the bi-encoder + path BM25 + PageRank stack is enough; the cross-encoder forward pass costs ~1s without quality lift on identifiers.

**No threshold knob.** ripvec v3.0.0 removed the `threshold` parameter. A calibrated relative noise-floor filter is applied internally: `score < 0.10 × top_score` when rerank is off (code), `score < 0.30 × top_score` when rerank fires (docs). These cutoffs were calibrated against 2,250 LLM-judge verdicts to maximize F1 with PARTIAL counted as a hit. Callers don't tune; the engine handles it.

Further narrowing:

```
search(query: "...", include_extensions: ["rs", "toml"])   # only these
search(query: "...", exclude_extensions: ["lock", "md"])   # everything except these
search(query: "...", scope: "code", top_k: 5)              # smaller result set
```

## Codex vs Claude Code: how to call the tools

**In Claude Code**, the MCP tools are deferred — load them first:

```
ToolSearch("ripvec")                    # find the namespace at runtime
ToolSearch("select:mcp__ripvec__search,mcp__ripvec__get_repo_map,mcp__ripvec__lsp_hover")
```

The namespace is either `mcp__ripvec__*` (project-level `.mcp.json`) or `mcp__plugin_ripvec_ripvec__*` (plugin install). `ToolSearch("ripvec")` returns whichever the current session has.

Claude Code users should also prefer the **native `LSP()` tool** when available — it talks to whichever LSP server Claude is configured with (ripvec, rust-analyzer, gopls, etc.) and returns the same data shapes. The ripvec MCP `lsp_*` tools are a fallback that works the same way but goes through the MCP transport.

**In Codex**, tool names are resolved by their bare names — no prefix, no `ToolSearch` step. Call `search`, `get_repo_map`, `lsp_document_symbols`, `lsp_goto_definition`, `lsp_hover`, `lsp_references`, `lsp_incoming_calls`, `lsp_outgoing_calls`, etc. directly. Codex does not have a native LSP integration; the ripvec MCP `lsp_*` tools are the primary path to LSP behavior.

Both hosts get the same data back. The composition pattern (`search` → `lsp_location` → LSP tool) is identical; only the call syntax differs.

## Bare tool names (reference card)

These names are valid in both Codex (direct) and Claude Code (after `ToolSearch` discovery):

### MCP semantic + structural
- `search` — find code/docs by meaning
- `get_repo_map` — PageRank structural overview (optional `focus_file`)
- `find_similar` — given file+line, find similar embeddings
- `find_duplicates` — codebase-wide near-duplicate pairs (default threshold: 0.5; `intra_file: true` to include same-file pairs; errors above 10K chunks)
- `up_to_date` — is the running binary newer than its source?
- `debug_log` / `log_level` — runtime diagnostics

### MCP LSP-shaped (for hosts without native LSP, or as a fallback)
- `lsp_document_symbols` — file outline (functions, classes, methods)
- `lsp_workspace_symbols` — cross-language symbol search with PageRank boost
- `lsp_goto_definition` — jump to symbol definition
- `lsp_goto_implementation` — find concrete implementations
- `lsp_references` — all usage sites
- `lsp_hover` — scope chain + enriched context
- `lsp_prepare_call_hierarchy` — make a call-hierarchy item at a position
- `lsp_incoming_calls` — who calls this function (function-level PageRank)
- `lsp_outgoing_calls` — what this function calls

### Native LSP (Claude Code users — prefer this when available)
- `LSP()` — the Claude Code tool that talks to the active LSP server. Pass `lsp_location` shapes (file, line, character) from ripvec MCP results to compose.

## Quick reference: scope decisions

```
If you're describing behavior, intent, or a concept:    → search
If you have a known file/line and want neighbors:       → find_similar
If you want the architectural spine:                    → get_repo_map
If you need to know who calls X:                        → LSP incoming_calls
If you need to know what X calls:                       → LSP outgoing_calls
If you need to ground a semantic candidate:             → LSP go_to_definition + hover
If you have an exact string ("TODO", "foo_bar"):        → Grep
If you want files matching *.rs:                        → Glob
```

## Skills installed by this plugin

These skills activate automatically based on user phrasing:

- **`codebase-orientation`** — fires on "how does this work" / "explain the architecture" / "show me the structure". Routes to `get_repo_map` + LSP `document_symbol` before any file reads.
- **`semantic-discovery`** — fires on "find the code that handles X" / "where is Y implemented" / "search for retry logic". Routes to `search` then LSP for grounding.
- **`change-impact`** — fires on "what breaks if I change this" / "find all callers" / "blast radius". Routes to LSP `incoming_calls` + `find_similar` + `find_duplicates`.

Skills can be invoked explicitly via the Skill tool or by phrasing that matches their description.

## Commands installed by this plugin

- `/ripvec:orientation` — this document
- `/ripvec:map [file]` — quick structural overview (optional focus)
- `/ripvec:find "query"` — semantic code search
- `/ripvec:similar file:line` — find code similar to a location
- `/ripvec:hotspots` — top-PageRank functions (architectural spine)
- `/ripvec:duplicates` — find near-duplicate code

## Common anti-patterns to avoid

- **Sequential `Read` walks to understand architecture.** Use `get_repo_map` once instead.
- **`Grep` for conceptual queries.** "Find auth code" is `search`, not `grep auth`.
- **Editing on vector similarity alone.** Pass the result's `lsp_location` through LSP before editing the symbol.
- **Ignoring `scope`.** A code-only query against `scope: "all"` wastes the cross-encoder rerank pass on prose files.
