# Changelog

## 4.1.10 (2026-05-24)

Knowledge-graph skill index: manifest bump + orchestration layer.

### Added — ripvec-orientation hub skill

New top-level hub skill (`skills/ripvec-orientation/SKILL.md`) mirroring
the swarm-orientation pattern. Triages between the 5 orientation hubs
(Cartographer / Detective / Refactorer / Onboarder / Sentinel) using the
decision tree from `SKILL_SEMANTIC_GRAPH.md §2`. Includes graph-preamble
frontmatter (`generalizes_to`, `specializes_into`, `cross_references`,
`escalate_to`) and dual-host tool surface (Claude Code ToolSearch path +
Codex bare-names path).

### Added — intent-routing skill

New lookup-table skill (`skills/intent-routing/SKILL.md`) condensing
`SKILL_TASK_INTENT_INDEX.md §§1-8` into verbatim phrasal triggers →
hub-skill → first recipe → ripvec MCP terminal. ~50 verbatim phrases
across 6 intent classes (orientation, debugging, refactoring, teaching,
sentinel, tool-meta). Full table with caveats lives in the index file;
this skill is the quick-access path.

### Added — 7 new commands

- `/orient` — top-level entry; triggers ripvec-orientation triage
- `/cartograph` — Cartographer hub; T1/T2/T5/C1 with optional
  `--focus-file` or `--concept`
- `/blast-radius $SYMBOL` — Refactorer T10 chain; P2 Fixed-Point
  Expansion via lsp_workspace_symbols → prepare_call_hierarchy →
  incoming_calls until quiescent
- `/dead-code` — Sentinel T16 sweep; confidence-band-aware; NC11
  fallback for `confidence=Low` clusters; NC15 response-size parameters
- `/audit` — Sentinel multi-cluster; C11 PageRank Polarity first,
  fans to dead-code / cohesion-refraction / naming-drift / orphan-trait
  per signal
- `/teach $CONCEPT` — Onboarder T13+T14; architectural tour +
  concept-by-example; P4 idiom crystallization; M7 prose-grade hover
  caveat
- `/trace $SYMBOL` — Detective T7 Recursive Caller Climb; Pearl
  do-calculus on call DAG; NC11 indirect-dispatch fallback

### Deleted — orientation.md command

Replaced by `orient.md`. The old command is gone; use `/orient` instead.

### Refreshed — 4 base skills with graph-preamble

- `skills/codebase-orientation/SKILL.md` — added `graph:` frontmatter
  (parent: cartographer; composes-into: semantic-discovery); §0 graph
  position section
- `skills/change-impact/SKILL.md` — added `graph:` frontmatter (parent:
  refactorer; composes-into: codebase-orientation); §0 graph position
- `skills/semantic-discovery/SKILL.md` — added `graph:` frontmatter
  (parent: cartographer; composes-into: change-impact); §0 graph position
- `skills/recipes/SKILL.md` — rewritten to bridge 3.1.2-era recipe
  names (T1-T18, C1-C12, P1-P10) to 4.1.x cluster taxonomy in
  `SKILL_SEMANTIC_GRAPH.md §4`; adds §0 graph position, decision table,
  primitives reference, scale discipline

### Bumped — plugin.json version 4.1.0 → 4.1.10

Description updated to mention knowledge-graph skill index, intent-routing,
5 orientations as hub skills, 7 per-language recipe skills (Track C),
executive-function subagents (Track D), and 7 new commands.

## 4.1.0 (2026-05-23)

Tracks ripvec engine v4.1.0 — minor-version feature release.

### Added — find_dead_code MCP tool

Cross-language detection of code unreachable from any entry point.
First user-visible consumer of the entry_points + dead-code substrate
landed dormant in 4.0.6.

Per-language entry-point detection (Rust/Python/Go via
`EntryPointDetector` trait), BFS reachability from entries, connected-
component clustering on the dead subgraph, sorted by size. Compose
with `lsp_references` to confirm a cluster is truly dead before
deleting.

```
find_dead_code(
  root, include_test_paths=false, max_clusters=50, min_cluster_size=1
)
→ {
  dead_clusters: [{root_node, size, total_lines, member_defs}],
  total_dead_defs, total_live_defs, dead_fraction,
  entry_points_detected, capped
}
```

### Known caveat: dead_fraction over-reports

Live ripvec self-test reports `dead_fraction = 0.982`. Two root
causes — both filed as 4.1.1 follow-up:

- **I#49**: RustEntryDetector LibraryExport detection only fires on
  direct `pub fn` in `lib.rs`/`mod.rs`; misses `pub use` re-export
  chains. Needs widening to follow re-exports.
- **I#50**: call-resolver `def_callees` edge coverage is sparse,
  under-propagating reachability.

Use `dead_fraction` as a *relative ordering signal* (cluster sizes
are meaningful, member_defs lists are useful) until 4.1.1 closes
both. Real findings include `pagerank_lookup`, `RepoConfig`,
`BlasKind`, and other already-known wired stubs.

### Substrate (4.0.7 + earlier)

ripvec engine 4.1.0 builds on the substrate fixes from 4.0.7 (I#37
document_symbols Python classes, I#38 cross-corpus position-scoped
LSP resolver, I#39 Python decorator over-tagging logic, I#40
lsp_references char-tolerance), which are all required for
find_dead_code to compose correctly across corpora.

See engine CHANGELOG for full per-issue detail.

## 4.0.7 (2026-05-23)

Tracks ripvec engine v4.0.7 — substrate fixes from the third 5-corpus
pattern revalidation campaign. Closes 4 critical bugs (I#37, I#38,
I#39, I#40) plus the SQL suffix-match landed earlier this cycle.

This is a deliberate substrate-only release before the forthcoming
4.1.0 `find_dead_code` MCP tool. The 4.1.0 substrate (X1 entry-point
detection in `entry_points.rs`) landed dormant in 4.0.6; X2 (BFS
algorithm) and X3 (MCP tool wrapper) ship in 4.1.0 on top of a
substrate-clean foundation.

### Fixed

- **I#38 (biggest fix)**: Every position-scoped LSP tool
  (`lsp_hover`, `lsp_goto_definition`, `lsp_goto_implementation`,
  `lsp_prepare_call_hierarchy`, `lsp_references`) silently returned
  empty when called with `root=None` against a corpus other than
  `project_root`. Root cause: `resolve_lsp_file_lite` joined the
  relative `file_path` from a search result against `project_root`,
  producing a bogus absolute path. Fix: `resolve_lsp_file_lite`
  is now `async` and probes the session's indexed roots
  (`ripvec_indices`, `root_indices`, `root_graphs`) to find a root
  that actually contains the file. The bug was the same root-class
  as I#13/I#15 but in a different code path.
- **I#37**: `lsp_document_symbols` now emits multi-inherited Python
  classes (Flask, MnemosyneApp). Root cause: 4096-byte chunk-size
  cap split large classes into anonymous chunks filtered by kind.
  Fix: `document_symbol` uses unbounded `ChunkConfig` so the outline
  path never window-splits.
- **I#39 (partial)**: Python `@classmethod`, `@staticmethod`, and
  arbitrary decorators no longer over-classified as Property
  (kind=7). New `lsp_symbol_kind_for_node` function with decorator-
  aware logic. Wiring into projection sites deferred to 4.0.8.
- **I#40**: `lsp_references` is position-tolerant within a def's
  identifier line. Pre-fix on flask: char=0 → 0 refs, char=4 → 48.
  Post-fix: char=0/4/7/8/12/15/23 → all return the def's references.
- **SQL bare-name suffix resolution** (committed earlier this cycle):
  aurora's gold → silver → bronze dbt/sqlmesh lineage composes
  through `get_repo_map.calls[]` via underscore-boundary suffix
  matching.

### Documentation

- AGENTIC_PATTERNS_4_0.md Part VIII added: cross-corpus revalidation
  findings (ripvec 68%, mnemosyne 70%, flask 63%, aurora 88%);
  drift threshold recalibration table (0.15 → 0.45+); new patterns
  P10/F7/F8/N3; N1 generalization to "PageRank Hijack."
- RIPVEC_IMPROVEMENTS.md I#37 — I#48 appended with cross-corpus
  reproduction evidence.
- docs/I38_DIAGNOSIS.md added: root-cause walkthrough for the
  position-scoped LSP empty-results bug class.

### Deferred to 4.0.8 / 4.1.0

- 4.0.8: F1 decorator wiring at projection sites + wiring-gap
  cleanup pass.
- 4.1.0: `find_dead_code` MCP tool (X2 BFS + X3 tool wrapper).

## 4.0.6 (2026-05-23)

Tracks ripvec engine v4.0.6 — second cross-corpus substrate-fix
wave. Closes 17 issues (I#19 — I#36) across 4 waves of fronts:
kind taxonomy completion, dedup math, cursor resilience, reranker
discipline, focus_file fix (T1), Go inverse call-graph (P1),
Python MRO/mixin dispatch (Q1), HCL engine extensions (Cluster R:
qualified_name, terraform_remote_state edges, module DAG, locals
expansion, content_kind tagging, symbol-grade references), SQL
FROM/JOIN/CTE extraction (Cluster S).

Companion: X1 substrate for the forthcoming 4.1.0 find_dead_code
tool — `crates/ripvec-core/src/entry_points.rs` (746 lines)
implementing `EntryPointDetector` trait + Rust/Python/Go detectors.
Six pub items intentional Type-B wired-stubs annotated for X2.

See engine CHANGELOG for full per-issue detail.

## 4.0.5 (2026-05-23)

Tracks ripvec engine v4.0.5 — substrate fixes from the 5-corpus pattern
validation campaign. Five engine bugs surfaced by exercising the
AGENTIC_PATTERNS_4_0 recipes against mnemosyne, flask, go-stdlib,
aurora, and ripvec, each reproduced on multiple corpora:

- **Cross-root contamination on workspace_symbols and call hierarchy**
  — `root` parameter is now an enforced filter, not a hint. Eliminates
  the worst class of 4.0.x bugs (results from project A leaking into
  project B's tool calls).
- **Python and Go call-graph extraction** — `lsp_incoming_calls` and
  `lsp_outgoing_calls` now return non-empty results on Python (`self.method()`,
  `instance.method()` after `instance = ClassName(...)`) and Go
  (receiver methods, pointer receivers). Python inheritance chains
  (Flask-style `Flask` extends `App`) still partially unresolved —
  full MRO traversal is a separate effort.
- **Topic-sensitive PageRank fix** — `focus_file` now applies
  Haveliwala 2002 soft personalization (α=0.15 on focus, 0.85/(n-1)
  uniform elsewhere) instead of a near-Dirac delta. Result: meaningful
  neighborhood rebias instead of focus-dominance with everything else
  collapsed to a uniform floor.
- **Kind taxonomy fixes** — Python `@property` → Property (kind=7),
  Go `interface` → Interface (kind=11), HCL block labels (`aws_iam_role.loader`)
  → symbol name correctly extracted, `symbol_kind_int` field added for
  numeric LSP-integer access alongside the friendly string.
- **`post_dedup_count` uncapped** — was previously capped at 20 (the
  result list size), making drift-index math systematically wrong.

The plugin binary auto-updater fetches the latest GitHub release;
existing plugin users get 4.0.5 on next bootstrap.

## 4.0.4 (2026-05-22)

Tracks ripvec engine v4.0.4 — function-tier promotion via corpus-relative rank thresholds.

The 4.0.3 release enriched def-level PageRank via improved call-edge extraction
(qualified-path capture, method receiver heuristics, impl→trait edge linking),
delivering 18.8× variance and 265 distinct nonzero ranks on the ripvec corpus.
However, the 4.0.2 AST-priority sort (types before functions) was hiding that
variance: types would fill the per-file token budget before high-rank functions
could surface.

4.0.4 adds corpus-relative tier promotion to `get_repo_map`:

- Defs whose `def_rank` exceeds 4× the corpus 75th percentile get +1 sort tier.
- Defs that exceed 16× get +2 sort tiers.
- Thresholds are computed from the corpus 75th percentile of nonzero def-ranks
  (self-calibrating): flat distributions see no promotions; informative
  distributions surface load-bearing defs proportionally.
- Attenuation tier tracking uses the original AST priority (not the promoted
  value) to preserve the 4.0.2 logarithmic cutoff invariants.

## 4.0.3 (2026-05-22)

Tracks ripvec engine v4.0.3 — call-edge extractor enrichment.

The 4.0.2 release surfaced (via live MCP verification) that def-level
PageRank was effectively flat across the corpus because the call-edge
extractor captured only a fraction of true Rust dispatch edges.
4.0.3 ships three layered improvements:

- **G1 qualified-path capture.** Scoped calls (`mod::foo()`) now retain
  the full path rather than collapsing to the bare name; resolve_calls
  uses the qualifier for module disambiguation.
- **G2 method receiver heuristic.** AST walk infers receiver types for
  `self.method()`, typed parameters, and constructor let-bindings.
- **G3 impl→trait edges.** Bidirectional weighted edges between trait
  method signatures and overriding impl methods so PageRank propagates
  through trait dispatch.

Measured variance lift on the ripvec corpus: G1 delivers 18.8× max/min
ratio and 265 distinct nonzero ranks (vs 4.0.2's effectively-flat
distribution). G2/G3 are inert on this specific corpus due to
external-library-heavy method calls and shallow trait hierarchies, but
unit-tested and architecturally sound for codebases with heavier
internal dispatch.

## 4.0.2 (2026-05-22)

Tracks ripvec engine v4.0.2 — three corrections to the 4.0.1 token-budget
allocator surfaced by live MCP verification:

- Floor-first admission so low-rank files don't crowd out content for top
  files. Eligible-but-can't-fit files surface in `total_files` and
  `budget_exhausted` but are not included as empty envelopes.
- AST kind priority (trait/struct/enum > function/impl > const > field)
  with def-rank as within-tier tiebreaker. Surfaces a file's *shape*
  before its *behaviors* — meaningful when def-rank distribution is
  degenerate (most defs at near-zero rank).
- 30% calls budget reserve per file. Symbol leftover flows into calls;
  call leftover flows to the next file.

The plugin binary auto-updater fetches the latest GitHub release; existing
plugin users get 4.0.2 on next bootstrap.

## 4.0.1 (2026-05-22)

Tracks ripvec engine v4.0.1 — token-budget allocation for `get_repo_map`.

### Breaking changes

- `get_repo_map` parameter `max_files` removed. Replaced by `token_budget` (default 4000 tokens).
  Callers that pass `max_files` will have it silently ignored (serde unknown-field behaviour);
  response size is now controlled by `token_budget` instead of a file count.

### New capabilities

- `token_budget` parameter controls `get_repo_map` response size. Budget is allocated across
  files by `PageRank` share (40% cap per file, 200-byte envelope floor). Symbols within each
  file fill the allocation in def-rank descending order with a logarithmic attenuation cutoff.
- `RepoMapSymbol.rank` — definition-level `PageRank` from `RepoGraph.def_ranks`. Consumers
  can now prioritise symbols by structural importance.
- `RepoMapCall` — outgoing call-edges are now objects with `lsp_location` and `rank` (target
  file `base_rank`), sorted by rank descending. Previously calls were bare `lsp_location` objects.
- `RepoMapFile.truncated_symbols` + `truncated_calls` — count of omitted entries per file.
- `GetRepoMapResponse.estimated_bytes`, `budget_bytes`, `budget_exhausted` — real-time budget
  telemetry. `budget_exhausted == (total_files > files.len())`.
- `capped` field retained as a synonym for `budget_exhausted` for backward compatibility.

## 4.0.0 (2026-05-22)

Tracks ripvec engine v4.0.0 — LSP-shaped composability release.

### Breaking changes (mirrors engine)

- `search_code` and `search_text` tools removed. Use `search(corpus="code"|"docs"|"all")`.
  The `scope` parameter is gone; use `corpus` + `rerank` + `include_metadata` instead.
- `get_repo_map` now returns JSON with a `files` array (lsp_location, rank, symbols, calls
  per file), not rendered prose. Pass `files[N].lsp_location.file_path` to downstream tools.
- Position-scoped LSP tools (`lsp_hover`, `lsp_goto_definition`, `lsp_goto_implementation`,
  `lsp_references`, `lsp_prepare_call_hierarchy`) accept `location` objects, not a
  `(file_path, line, character)` triple. Pass `results[N].lsp_location` directly.
- `find_similar` accepts `location` (pass `results[0].lsp_location` directly) or
  `symbol_name`. The legacy `(file_path, line)` pair is removed.

### New capabilities

- Zero-destructure composability: chain tools by passing `lsp_location` objects directly —
  `search → get_repo_map → lsp_document_symbols → lsp_prepare_call_hierarchy → lsp_outgoing_calls`
  with no field extraction at any handoff.
- `lsp_incoming_calls` and `lsp_outgoing_calls` `item` parameter is now typed `object`;
  pass the `lsp_prepare_call_hierarchy` result directly without JSON-stringifying.
- `chunk.kind` now reflects the correct LSP `SymbolKind` for Rust (struct, trait, enum,
  fn, mod, const, static, type_alias); `kind=Variable` no longer used as a catch-all.
- `lsp_workspace_symbols` response includes `pre_dedup_count` and `post_dedup_count` fields.
- `find_duplicates` response includes `corpus_chunk_count` and `capped` fields.
- `search` results `lsp_location.start_line` points at the symbol identifier line
  (not the chunk start, which may be a doc-comment).

### Recipes and skills updated

- All recipes updated: `scope=` replaced with `corpus=` / `rerank=` / `include_metadata=`.
- `find_similar(file_path=..., line=...)` examples replaced with `find_similar(location=...)`.
- Composability chain examples updated to reflect zero-destructure pattern.
- `get_repo_map` recipes updated for JSON output format.

## 3.1.2 (2026-05-22)

Tracks ripvec engine post-v3.1.1 audit (28 findings closed across 16 MCP entry points).

### LSP correctness
- LSP tools (`lsp_references`, `lsp_workspace_symbols`, `lsp_goto_definition`, `lsp_goto_implementation`, `lsp_hover`) now work correctly without an explicit `root` parameter — previously they silently returned empty results when `root` was omitted.
- `lsp_goto_implementation` now resolves to impl blocks for Rust traits; previously it returned the trait declaration itself.
- `lsp_prepare_call_hierarchy` returns all overlapping definitions at the cursor (overload-aware) and filters out non-callable symbols.
- `lsp_workspace_symbols` deduplicates by `(name, kind)` instead of by location, eliminating spurious duplicate entries.
- Outgoing call resolution preserves qualified-path scope (e.g. `std::io::Read` is no longer flattened to `Read`).

### find_duplicates calibration
- Default similarity threshold recalibrated from 0.85 → 0.5 to match the Model2Vec static encoder's cosine range (0.005–0.07 on code at 0.85 was matching nothing).
- New `intra_file: bool` parameter (default `false` = cross-file only) controls whether same-file chunk pairs are included.
- Corpus cap added at 10K chunks to prevent runaway memory use on large repos.

### Input validation and robustness
- `log_level` input is capped at 1024 chars and allowlisted to `ripvec`/`ripvec_mcp`/`ripvec_core` log prefixes; tokio/hyper internals are rejected. Response now includes `previous_filter` for revertibility.
- `get_repo_map` with an ambiguous `focus_file` now returns a `candidates: [...]` list instead of silently picking the first match.
- `up_to_date` no longer infinite-loops on symlink cycles; includes `Cargo.lock` in the scan; distinguishes `no_source_found` from "up to date".
- Chunks now carry a populated `name` field from tree-sitter (was always empty).

### Observability
- `debug_log` logs relative paths instead of absolute paths for privacy.

### Internal (non-user-visible)
- Async-safe RwLock migration, `apply_diff` idempotency hardening, manifest touch-refresh persistence.

## 3.1.1 (2026-05-22)

### Changed
- Tracks ripvec engine v3.1.1.
- Online reconcile now **selectively rebuilds** the in-memory index instead of doing a full
  rebuild on every detected change. Warm-dirty cost on a 5K-chunk corpus drops from
  ~270 ms–1 s (3.1.0 full rebuild) to ~50–100 ms (3.1.1 selective). Cold-start unchanged.

### Yanked upstream
- ripvec engine 3.1.0 is yanked on crates.io — superseded by 3.1.1 (same correctness, worse
  perf on every change). The plugin's auto-updater fetches the latest GitHub release binary,
  which is now 3.1.1, so existing plugin users get the fix transparently on next bootstrap.

## 3.1.0 (2026-05-22)

### Changed
- Tracks ripvec engine v3.1.0.

### Added
- Online reconciliation on every search. The engine auto-detects file changes (added,
  modified, deleted) via blake3-confirmed mtime/size/inode diff before returning results.
  No manual reindex step needed after editing files. Reconcile cost scales with corpus size;
  very large corpora (~50K+ files) pay ~100 ms per query.

### Removed
- `reindex` MCP tool — superseded by online reconciliation.
- `index_status` MCP tool — superseded by online reconciliation; the server is always ready.
- `/ripvec:repo-index` command — documented the `reindex` tool, which is now gone.

## 3.0.4 (2026-05-22)

### Removed
- `hooks/SessionStart` hook and `hooks/scripts/check-install.sh`. The hook printed a one-line status message at every session start ("ripvec-mcp X.Y.Z ready." or "ripvec-mcp will auto-install on first use.") that was pure noise — install/launch is handled inline by `bin/ensure-ripvec-mcp.sh` invoked from `.mcp.json`, which is the actual bootstrap path. The SessionStart message added nothing the user needed.

## 3.0.3 (2026-05-22)

### Changed
- Bumped to track ripvec engine v3.0.2 (the recovery release after a CI-trigger mishap published `ripvec` 3.0.1 to crates.io while iterating on cleanup commits). 3.0.1 is yanked on crates.io; 3.0.2 is the recommended version. The plugin's user-facing surface is unchanged — this bump exists to refresh the marketplace cache so the auto-installer picks up the v3.0.2 release binaries via `ensure-ripvec-mcp.sh`.

## 3.0.2 (2026-05-21)

### Changed
- Bumped to track ripvec engine v3.0.1 (the full-repo CUDA/Metal/MLX vestige sweep that closed the audit gap from v3.0.0). The plugin's user-facing surface is unchanged; this bump exists to refresh the marketplace cache so the auto-installer picks up the v3.0.1 release binaries via `ensure-ripvec-mcp.sh`.

## 3.0.1 (2026-05-21)

### Changed
- `commands/orientation.md` documents the v3.0.0 removal of the `threshold` parameter and the calibrated relative noise-floor filter (0.10 × top_score when rerank is off, 0.30 × top_score when rerank fires). Calibration provenance: 2,250 LLM-judge verdicts on 45 queries across 3 corpora. The plugin's bare-name tool references (`search`, `get_repo_map`, etc.) were already correct; only the orientation prose needed updating.

### Notes
- No behavior change in the plugin itself. The ripvec engine v3.0.0 ships with the calibrated internal cutoff regardless of which plugin version users have. This patch release exists to keep the orientation command in sync with the engine surface so users don't see a "threshold" parameter that doesn't exist.

## 3.0.0 (2026-05-21)

### Breaking changes (matches ripvec core v3.0.0)
- Removed the ModernBERT and BGE-small transformer bi-encoders. ripvec now ships as a single cacheless engine: Model2Vec static encoder + TinyBERT-L-2-v2 cross-encoder reranker, CPU-only.
- Removed the `--model bert`, `--model modernbert`, `--fast`, `--text`, `--modern`, `--backend`, `--device`, `--batch-size`, `--max-tokens`, `--model-repo`, `--interactive` CLI flags. They were tied to the doomed transformer engines.
- Removed `RIPVEC_MCP_ENGINE` env var (the MCP server is unconditionally ripvec-engine).
- Removed the `legacy-transformer-mcp` Cargo feature.
- Removed the `metal`, `cuda`, `mlx` Cargo features and their dep stacks (cudarc, mlx-rs, metal, objc2-metal, objc2-metal-performance-shaders, nvrtc).
- The `.ripvec/cache/` repo-local index directory was tied to the transformer engines and is gone. The ripvec engine builds its index in memory on first query and keeps it for the MCP process lifetime.
- See the [ripvec v3.0.0 release notes](https://github.com/fnordpig/ripvec/blob/main/CHANGELOG.md) for the full surgery scope (-25,000+ LOC).

### Plugin changes
- New `/ripvec:orientation` command — single-page overview of when to use which tool, how to compose MCP results with LSP, how to scope and filter searches. The recommended starting point.
- All skills (`codebase-orientation`, `semantic-discovery`, `change-impact`) rewritten to:
  - Use bare tool names in prose (`search`, `get_repo_map`, `lsp_hover`) instead of host-specific prefixed names (`mcp__ripvec__search`), which broke Codex tool resolution.
  - Call out both invocation paths: Claude Code (`ToolSearch` + `mcp__ripvec__*` / `mcp__plugin_ripvec_ripvec__*` namespace) and Codex (bare names, no prefix).
  - Direct Claude Code users to the **native `LSP()` tool** as the preferred grounding path; ripvec MCP `lsp_*` tools are the fallback when no native LSP is configured.
  - Direct Codex users to ripvec MCP `lsp_*` tools as the primary LSP path (Codex has no native LSP integration).
- Agent `tools:` frontmatter (Claude-Code-specific) now lists the LSP-shaped MCP tools alongside the semantic tools, so the dispatched agent has access to both surfaces under both namespaces.
- All commands updated to use bare tool names and reference `/ripvec:orientation` for the broader decision tree.
- README rewritten to reflect the v3.0.0 surface: removed Metal/CUDA/MLX performance tables; added the LSP-shaped MCP tools reference; added an explicit Codex vs Claude Code comparison.
- Verified post-surgery: full 63-repo semble bench shows bit-identical NDCG@10 across all repos (0.803461 macro), p50 -2.28% (within +/-5% threshold). The cross-encoder reranker auto-path on prose corpora is empirically preserved.

## 0.13.27 (2026-05-13)

### Fixed
- Fixed MLX driver unpadded batching so token tensors remain flat while
  attention masks stay padded, resolving reshape failures in BGE-small model
  tests.
- Fixed MLX layer normalization affine parameter shape handling for
  `mlx_rs::fast::layer_norm`.

## 0.13.26 (2026-05-13)

### Fixed
- Release includes the live 3D atlas rotation fix so the index dashboard keeps
  rotating after indexing completes.

## 0.13.25 (2026-05-13)

### Added
- ripvec skills now document native LSP and ripvec MCP LSP interoperability.
  Semantic search, repo-map, and similar-code results should be grounded by
  passing `results[].lsp_location` to native Claude Code LSP tools or Codex's
  ripvec MCP LSP tools before making symbol-sensitive edits.

## 0.13.24 (2026-05-13)

### Added
- ripvec can now exclude indexed files with `--exclude-extensions=jsonl,md`
  and repo-local `.ripvec/config.toml` `[ignore]` patterns using
  `.gitignore` syntax.

## 0.13.18 (2026-04-25)

### Fixed
- MCP launcher now resolves the plugin root correctly on both Claude
  Code and Codex.

  **Root cause.** The previous shim used
  `root="${CLAUDE_PLUGIN_ROOT:-$PWD}"` inside the bash `-lc` string.
  Claude's preprocessor substitutes `${VAR}` patterns in `args` *before*
  bash runs, but it only knows about `${CLAUDE_PLUGIN_ROOT}` as a bare
  token — when given a `${VAR:-default}` form it appears to emit the
  default verbatim. So Claude substituted the whole expression to the
  literal string `$PWD`, bash then evaluated `$PWD` = the project
  working directory (Claude does not rewrite `cwd:"."` to plugin root
  the way Codex does), and `./bin/ensure-ripvec-mcp.sh` failed to
  resolve. Visible symptom: `Failed to reconnect to
  plugin:ripvec:ripvec` with stderr
  `bin/ensure-ripvec-mcp.sh: No such file or directory` rooted at the
  user's project dir.

  **Fix.** Use the bare token `${CLAUDE_PLUGIN_ROOT}` and do the
  fallback in a separate bash statement that Claude's preprocessor
  doesn't touch:

  ```bash
  set -eo pipefail
  root="${CLAUDE_PLUGIN_ROOT}"
  case "$root" in ''|*'$'*) root="$PWD" ;; esac
  cd "$root"
  exec ./bin/ensure-ripvec-mcp.sh "$@"
  ```

  - **Claude:** preprocessor substitutes `${CLAUDE_PLUGIN_ROOT}` → real
    plugin path; bash's `case` falls through; `cd` lands at plugin root.
  - **Codex:** no preprocessor; bash expands the literal
    `${CLAUDE_PLUGIN_ROOT}` against the child env (Codex's stdio
    launcher uses `env_clear()` and does not pass `CLAUDE_PLUGIN_ROOT`)
    → empty; `case ''` arm fires → `root=$PWD`; Codex has rewritten
    `cwd:"."` to the plugin root, so `$PWD` is correct.

  `set -u` removed deliberately — Codex's empty-env expansion of
  `${CLAUDE_PLUGIN_ROOT}` would abort under `-u`. The `case '*'$'*'`
  arm is a belt-and-suspenders fallback for the unlikely case where
  Claude ever passes the token through literally.

## 0.12.0 (2026-04-07)

### LSP Server
- **NEW**: ripvec-mcp now serves LSP over stdio (`--lsp` flag)
- 10 LSP operations: documentSymbol, workspaceSymbol, goToDefinition, goToImplementation, findReferences, hover, publishDiagnostics, prepareCallHierarchy, incomingCalls, outgoingCalls
- Code intelligence for 21 languages (26 file extensions) — no separate language server needed
- Tree-sitter syntax diagnostics after every edit
- `.lsp.json` plugin config for Claude Code LSP integration

### Function-Level PageRank
- **NEW**: PageRank computed per-function from call graph edges (not per-file from imports)
- Call expression extraction for 15 tree-sitter grammars
- Name-based resolution: same-file → imported-file → unresolved
- File-level rank derived as aggregate of definition ranks
- Log-saturated boost prevents top-heavy distortion

### Languages
- **NEW**: 7 languages added — bash, ruby, HCL/Terraform, kotlin, swift, scala, TOML
- Added `.bats` (bash test) and `.tfvars` (terraform vars) extension mappings
- 21 languages total, 26 file extensions

### Search
- PageRank boost now uses per-function rank with file-level fallback
- Log-saturated formula: `score * (1 + α · ln(1+β·rank)/ln(1+β))`
- Fixed hardcoded alpha in LSP workspace_symbol — now uses auto-tuned graph.alpha

### Distribution
- **NEW**: Auto-install binary — detects platform (macOS/Linux, x86/ARM) and CUDA (via nvidia-smi)
- **NEW**: cargo-binstall metadata for pre-built binary installation
- 5-target release builds: x86+ARM Linux CPU, x86+ARM Linux CUDA, macOS ARM
- `/ripvec:repo-index` command for repo-level indexing

### CI/CD
- Fixed tree-sitter ABI mismatch (bumped to 0.26)
- Fixed MSRV toolchain (1.88.0)
- Multi-arch release pipeline with CUDA containers

## 0.2.0 (2026-04-03)

- Add `root` parameter to all MCP tools
- Indexing progress indicators
- repo-level cache indices (`.ripvec/cache/`)

## 0.1.0 (2026-03-31)

- Initial marketplace release
- 3 skills: codebase-orientation, semantic-discovery, change-impact
- 2 commands: /find, /map
- 1 agent: code-explorer
- Install hook checks for ripvec-mcp in PATH
