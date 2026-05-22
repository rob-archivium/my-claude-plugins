# Changelog

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
