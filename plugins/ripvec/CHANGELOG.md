# Changelog

## 0.13.18 (2026-04-25)

### Fixed
- MCP launcher now resolves the plugin root correctly on both Claude Code
  and Codex. The previous shim relied on `${CLAUDE_PLUGIN_ROOT}` being
  exported as an env var, but Claude only substitutes that token in
  `.mcp.json` field values — it does not export it to the MCP child. The
  shim therefore fell through to `$PWD` (the project directory) and tried
  to exec `./bin/ensure-ripvec-mcp.sh` from a path that does not exist,
  producing `Failed to reconnect to plugin:ripvec:ripvec`. Now passes the
  substituted path through an `env.PLUGIN_ROOT_HINT` field; bash uses it
  if it looks like a real path, else falls back to `$PWD` (which Codex
  rewrites to the plugin root via `cwd:"."`).

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
