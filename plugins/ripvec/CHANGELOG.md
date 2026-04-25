# Changelog

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
