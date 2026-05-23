# Cartographer recipes

> *Build a map you can navigate; not a map you must memorize.*
> *(Simon: bounded rationality. Maintain a cheap procedure for re-summoning.)*

Cartographer patterns build usable models of unfamiliar code. The recipes assume you've just landed in a codebase and want to extract its architectural shape with minimum reading.

---

## Structural Spine

**When**: First contact with a codebase. "What matters here?"

**Chain**:
```
1. mcp__ripvec__get_repo_map(max_tokens=4000)
     → PageRank-ranked top files
2. For the top 3-5 non-trivial files:
     mcp__ripvec__lsp_document_symbols(file_path=top_file)
     → outline of each file's role
3. For the highest-PageRank file's top-level definitions:
     mcp__ripvec__lsp_outgoing_calls(file, line, character)
     → trace intent flow downstream
```

**Why it works**: PageRank ignores transitive noise; the top files give ~80% of structural shape. Document symbols give "what's in each"; outgoing calls give "how each composes the rest."

**Watch out**:
- The rendered atlas from `get_repo_map` is human-readable, not structured JSON. To compose programmatically, parse with care (the format is `## path (rank: N)` headers).
- `lsp_outgoing_calls` needs the cursor positioned at the function's **name character**, not at line:0. Compute the offset within the line first.

**Example (codex)**: `get_repo_map` reveals that the top-ranked file is a JSON protocol schema (rank 0.066) with 9,624 indexed symbols. This is the architectural signature of a *contract-first* design — code orbits the schema, not the other way around. One tool call surfaces this.

---

## Intent First, Text Second

**When**: "Where is the [retry / cache / auth / dispatch] logic?"

**Chain**:
```
1. mcp__ripvec__search(query="<intent in natural English>", top_k=8, corpus="code")
     → semantic ranking of candidate sites
2. For top-3 hits, mcp__ripvec__lsp_hover(file, line, character)
     → enriched context (kind, type, scope chain)
3. For anything that looks wrong:
     mcp__ripvec__lsp_incoming_calls(item-from-prepare)
     → validate caller assumptions
```

**Why it works**: Semantic search finds meaning before lexical noise (grep) contaminates the result. The hover step turns "candidate locations" into "candidates with context."

**Watch out**:
- Static-encoder cosines are 0.005-0.07 on code; the absolute scores are meaningless, the *ranking* is what matters.
- Hover at `start_line, character=0` often lands on `mod tests {` or a punctuation token. Position the cursor at the symbol's name when possible.

**Example (codex)**: `search("dispatch a tool call from the model to a handler")` returned 5 files across 5 crates — `rollout-trace/tool_dispatch.rs`, `core/tools/tool_dispatch_trace.rs`, `ext/extension-api/contributors/tool_lifecycle.rs`, etc. Real architectural intelligence in one call: tool dispatch is *distributed* across layered concerns.

---

## Trait Constellation Mapping

**When**: "What polymorphism exists in this codebase?"

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(query="<trait name or keyword>")
     → the behavioral vocabulary (post-(name,kind) dedup)
2. For each candidate trait:
     mcp__ripvec__lsp_goto_implementation(file, line, character)
     → real impl blocks (post-R3.1; was returning trait decls before)
3. For each impl, lsp_incoming_calls on its key method
     → which impls are actually hot
4. For zero-incoming impls: find_similar to test if duplicate or genuine dead code
```

**Why it works**: The difference between *designed* and *exercised* polymorphism is invisible to any single tool. Lampson: *"Get it right before you make it fast"* — knowing which impls are hot is prerequisite to knowing where to focus.

**Watch out**:
- Rust's trait keyword isn't always tagged with `kind=Interface` in chunk metadata. If `lsp_workspace_symbols` doesn't filter cleanly to traits, try `search("pub trait <Name>", corpus="code", include_extensions=["rs"])` instead.
- `lsp_goto_implementation` on a non-trait silently falls back to goto_definition. Confirm the target IS a trait before treating the result as an impl list.

---

## PageRank-Anchored Concept Tour *(composition pattern)*

**When**: "Orient me in this codebase, focused on topic X."

**Chain**:
```
1. mcp__ripvec__search(query="<concept>", top_k=5, corpus="code")
     → identify a high-signal anchor file
2. mcp__ripvec__get_repo_map(max_tokens=2000, focus_file=anchor)
     → PageRank rebiased toward the anchor's neighborhood;
       the map's skyline tilts
3. mcp__ripvec__lsp_document_symbols on each newly-top-ranked file
     → topic-specific anatomy
4. For symbols recurring across files:
     mcp__ripvec__find_similar to discover the idiom's footprint
```

**Why it works**: Without focus, PageRank is uniform — every hub looks important from everywhere. The `focus_file` parameter is Polya's "auxiliary problem" applied to graph centrality. The skyline reorients dramatically — a file's rank can jump 10x when it becomes the focus.

**Example (codex)**: `focus_file=` on `CommandExecutionRequestApprovalParams.ts` jumps that file's PageRank from 0.066 unfocused to 0.627 focused. The same map, different question, different answer.

---

## Names as Latent Taxonomy *(meta-pattern)*

**When**: Discovering the de-facto vocabulary of a codebase. *Alexander: recurring forms are remembered solutions.*

**Chain**:
```
1. Pick a high-collision verb or suffix: handle, execute, *_handler, try_*, with_*
2. mcp__ripvec__lsp_workspace_symbols(query=verb)
     → all symbols matching, post-(name, kind) dedup
3. Read the SHAPE of the result, not just the contents:
     - Group by inferred module (top 2-3 path components)
     - Group by symbol_kind
4. For the dominant cluster, mcp__ripvec__find_similar from one canonical
   member → surface the unnamed siblings (code in the category without
   wearing its uniform)
```

**Why it works**: The corpus of names is a folk taxonomy programmers built without realizing it. Whether validators cluster by *domain* (`validate_email`, `validate_token`) or by *layer* (`Service::validate`, `Repo::validate`) reveals two different theories of the same system.

**Watch out**:
- `lsp_workspace_symbols` can include Python/TypeScript/JSON-schema entries on polyglot repos. Use `include_extensions` if you want language-scoped taxonomy.
- The dedup-delta (raw count vs post-dedup count) is the actual drift signal — but the current API only exposes post-dedup, so the drift index isn't directly measurable.

**Example (codex)**: `lsp_workspace_symbols(query="execute")` returns 14 entries across 4 modules. 9 of them live in `codex-rs/code-mode`. That's a strong signal: code-mode is the canonical "execute" namespace; a single entry `CodeModeExecuteHandler` in `core` bridges the two. The architectural fact extracted from one query.

---

## Cross-references

- For *what to do once you've mapped*, see [refactorer](refactorer.md), [detective](detective.md).
- For *teaching the map to another agent*, see [onboarder](onboarder.md).
- For the underlying composition algorithms, see [primitives](primitives.md).
