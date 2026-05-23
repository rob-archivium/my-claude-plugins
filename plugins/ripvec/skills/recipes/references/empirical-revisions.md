# Empirical revisions

Lessons from running the patterns against real codebases (codex 4.6K files, ripvec 0.5K files). Each revision is a pattern-level adjustment learned by encounter with reality.

---

## R1. Cursor positioning matters

**Affected patterns:** Sibling Diff (T4/P3), Recursive Caller Climb (T5/P2), Recursive Narration Descent, Fan-Out God-Function Probe, every recipe using `lsp_outgoing_calls`, `lsp_incoming_calls`, `find_similar`.

**Symptom:** Tool returns 0 results (find_similar) or wrong type (prepare_call_hierarchy returns a struct container instead of the intended function).

**Cause:** LSP tools resolve based on the cursor's exact byte position. At `line:0, character:0`, the cursor sits on:
- Whitespace at start of a line
- A keyword (`pub`, `fn`, `struct`)
- A non-identifier token

Not the symbol name itself. Many tools silently fall through.

**Remedy:** Before calling LSP precision tools, compute the **name character offset**:
```
name_char = source_line.find(symbol_name)
lsp_outgoing_calls(file, line, name_char)
```

For `find_similar`, place the cursor at least 2-3 lines into the function body to ensure the cursor is inside an indexed chunk (chunks typically span function bodies, not declarations).

---

## R2. Corpus cap is silent

**Affected patterns:** Duplicate-Anchored Extraction (T9), Duplication-as-Hidden-Module, Cohesion Refraction Test, every `find_duplicates` recipe.

**Symptom:** `find_duplicates` returns 0 pairs with no error. Pattern appears to indicate "no duplicates exist" when actually "no duplicates computed."

**Cause:** Post-R6.4, `find_duplicates` caps the corpus at MAX_CORPUS_FOR_DUPLICATES = 10,000 chunks. On a typical Rust repo, that's reached at ~3,000-4,000 source files. Beyond that, the tool returns an empty result.

**Remedy:** Always scope `root=` to a module-sized subtree:
```
mcp__ripvec__find_duplicates(
  root="/path/to/repo/specific-crate/src",
  threshold=0.55,
  intra_file=false
)
```

For Rust workspaces: scope to one crate. For TypeScript monorepos: scope to one package. **Iterate from small scopes outward, not whole-repo first.**

---

## R3. `get_repo_map` — RESOLVED in 4.0: now returns JSON

**Affected patterns:** Structural Spine, Top-N Architectural Tour, PageRank-Anchored Concept Tour, Topic-Sensitive Atlas, every recipe that chains `get_repo_map` into a downstream tool call.

**Status (4.0):** `get_repo_map` now returns a JSON object with a `files` array. Each entry carries `lsp_location`, `rank`, `content_kind`, `symbols` (each with `kind` and `lsp_location`), and `calls`. The prose atlas is gone from the tool response; the `ripvec://repo-map` MCP resource retains it for human consumption.

**Chain (post-4.0):**
```python
repo_map = get_repo_map(max_files=10)
top_file = repo_map["files"][0]  # already sorted by rank
syms = lsp_document_symbols(file_path=top_file["lsp_location"]["file_path"])
```

No regex parsing needed. Pass `files[N].lsp_location.file_path` directly.

**Legacy note:** If you're running a pre-4.0 ripvec, use the regex workaround:
```
file_rank_pattern = r'## (\S+) \(rank: ([0-9.]+)\)'
```

---

## R4. `chunk.kind` — RESOLVED in 4.0: correct LSP SymbolKind for Rust

**Affected patterns:** Trait Constellation Survey, Orphan-Trait Extinction Sweep, every recipe that filters `lsp_workspace_symbols` by kind.

**Status (4.0):** `chunk.kind` is now populated with the correct LSP `SymbolKind` for Rust declarations: struct=23, trait=11 (Interface), enum=10, fn=12 (Function), mod=2 (Module), const=14 (Constant), static=14, type_alias=26 (TypeParameter). `lsp_workspace_symbols` and `lsp_document_symbols` surface the correct `symbol_kind` values.

**Post-4.0 usage:**
```
mcp__ripvec__lsp_workspace_symbols(query="<trait name or keyword>")
# Now reliably returns kind=11 (Interface) for Rust trait declarations.
```

**Fallback (still reliable):** For trait enumeration when `symbol_kind` results are unexpected:
```
mcp__ripvec__search(
  query="pub trait <SymbolName>",
  corpus="code",
  include_extensions=["rs"]
)
```

Or scan `lsp_document_symbols` output and inspect the chunk content for the `trait` keyword.

---

## R5. Dedup-delta — RESOLVED in 4.0: pre_dedup_count + post_dedup_count exposed

**Affected patterns:** Names as Folk Taxonomy (P5), Naming Drift via Dedup-Delta.

**Status (4.0):** `lsp_workspace_symbols` response now includes `pre_dedup_count` and
`post_dedup_count` fields. The drift index is directly computable:
```
result = lsp_workspace_symbols(query=verb)
drift_index = result["pre_dedup_count"] - result["post_dedup_count"]
```

A high `drift_index` means the same symbol name appears many times across the corpus —
direct signal of naming fracture or code duplication.

---

## R6. find_duplicates non-source files — IMPROVED in 4.0

**Affected patterns:** Duplicates as Taxonomy (P4), Cohesion Refraction Test, Onboarder pattern-language discovery.

**Status (4.0):** `find_duplicates` now accepts `corpus` and `include_metadata` parameters.
`corpus="code"` (default) and `include_metadata=false` (default) filter out JSON schemas,
YAML configs, TOML, XML, lock files, and test snapshots by default.

**Post-4.0 usage:**
```python
# Default: code files only, no metadata flood
find_duplicates(threshold=0.55, intra_file=false, root=SCOPED_ROOT)

# To include config/schema files explicitly:
find_duplicates(threshold=0.55, include_metadata=true, corpus="all")
```

**Still relevant:** Markdown prompt templates (`.md`) are `corpus="docs"`, not Meta, so
`corpus="code"` already excludes them. Test snapshots (`.snap`) are now tagged Meta and
excluded by default.

---

## R7. Detective patterns reveal architecture even without a bug

**Affected patterns:** Sibling Diff (T4), Recursive Caller Climb (T5), Broken Contract Hunt (T6).

**Symptom:** Without a real bug, the detective patterns produce *architectural facts* (e.g., "these two modules are tightly coupled at sim=0.92"), not "fixed bugs."

**Cause:** The patterns' bug-hunting value emerges when a real bug exists. Speculative execution teaches the recipe shape, not its bug-finding power.

**Remedy:** Don't dismiss the architectural facts surfaced — they're valuable signal. But recognize that the patterns' *peak* value is in a bug-hunting moment.

---

## R8. Patterns are not model-tier-specific in practice

**Affected:** the original synthesis assumption that haiku/sonnet/opus tiers produce qualitatively different recipes.

**Symptom:** Empirically, the most actionable recipes (T2, T7, T9-scoped, T11, Semantic Hypothesis Triage) appeared independently across all three tiers — haiku tactical, sonnet operational, opus principle. The tier difference shows up in the *framing*, not the *recipe*.

**Cause:** The patterns are intrinsic to the tool surface. Different cognitive depths discover the same patterns from different angles.

**Remedy:** For production use, the haiku tier suffices. Reserve sonnet/opus for new pattern discovery and meta-reasoning.

---

## R9. Codebase discipline scales the patterns' value

**Affected:** all patterns.

**Symptom:** Codex (well-named, well-modularized) gave clean, high-signal results. A messier codebase would produce noisier results.

**Cause:** The patterns are extractors; they extract whatever signal exists. Disciplined codebases have more signal to extract.

**Remedy:** None — the patterns reward well-named code with sharper navigation. Use the patterns AS a discipline-improvement tool too: a codebase where the recipes work well is a codebase that has earned its naming and structure.

---

## Cross-references

- For the underlying patterns, see each orientation reference.
- For the synthesis source, see `docs/AGENTIC_PATTERNS.md` in the ripvec repo (~/src/mine/ripvec).
