---
name: go-recipes
description: >
  Use when working with Go code, especially the Go standard library or
  any monorepo-scale Go corpus. Triggers on: "find dead code in Go",
  "where does this interface get implemented", "platform-specific
  defs_linux_amd64 portability matrix", "generated zerrors hijacking
  PageRank", "Sprintf ambiguity across fmt/flag/go/types", "capital
  export convention", "go-stdlib at 11K files", "find_dead_code response
  too large", "rank-band cluster as find_duplicates substitute".
  Specializes the hub skills for Go idioms — capital-export discipline,
  build-tag portability matrices, interface satisfaction (no `implements`
  keyword), generated-file PageRank pollution.
graph:
  generalizes_to:
    - ripvec:cartographer
    - ripvec:detective
    - ripvec:refactorer
    - ripvec:onboarder
    - ripvec:sentinel
  specializes_into: []
  cross_references:
    - ripvec:ripvec-orientation
    - ripvec:intent-routing
    - ripvec:recipes
    - ripvec:c-recipes
  escalate_to: ripvec:sentinel
---

# go-recipes — Go as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` Parts VI-X (Go is the
go-stdlib scale stressor; see F4/F5/F6, NC5, H9, N1, MS1/M16) and
`docs/BUG_DATABASE.md` §1 + §8 by line. **Go is where M3 Style-
Discipline-Compresses-Triangulation was earned** (Part IX §IX.5
lines 2210-2218): gofmt + capital-export + suffix-taxonomy
discipline gives Go uniquely high recipe yield per tool call.

## §0 Graph position

Specializes the five hub orientations for Go. Triage
(`ripvec:ripvec-orientation` → `ripvec:intent-routing`) routes here
when `.go`-dominant. Go work most often escalates to
`ripvec:sentinel` (because go-stdlib's scale + style discipline
makes portability audits and PageRank-pollution diagnoses the
characteristic Go work).

## §1 Language character

What ripvec sees on a Go corpus:

- **Inverse call-graph index works.** B-0012 (I#22) closed 4.0.6:
  Go method bodies resolve `lsp_incoming_calls` correctly via
  `collect_go_receiver_types`. Wave 4 confirmed BFS terminates on
  11K-file go-stdlib with `confidence=high`.
- **Type aliases historically miscoded.** B-0039 (I#23) closed
  4.0.6: `type Foo = Bar` no longer kind=26 (TypeParameter).
- **Capital-export convention IS the index.** Per M3 (Part IX §IX.5,
  lines 2210-2218), Go's style discipline means one lens often
  suffices where three were needed in undisciplined corpora. The
  `EXPORTED` vs `unexported` boundary is a hard signal — combine
  with `lsp_workspace_symbols(query="Capital*")` for high-precision
  public-API audits.
- **Build-tag / platform suffix files cluster naturally.** F4 (Part
  VI lines 1159-1194): `defs_freebsd_*.go`, `defs1_netbsd_*.go`,
  `defs_linux_*.go`, `*_amd64.go`, `*_arm.s` form portability
  matrices visible via `find_duplicates`. `_EINTR` cluster at
  threshold 0.85 is the canonical example; sim 0.82 inside the
  cluster = platform divergence worth investigating.
- **PageRank is hijacked by generated files at scale.** N1 (Part VII
  lines 1361-1377): top-9 of go-stdlib top-level is 100%
  generated (`zerrors_windows.go`, `opGen.go`, `bindata_*`). Per
  F5 / H9, partition by sub-root or filter generated extensions
  before reading the structural spine.
- **NC1a ambiguity payloads are folk taxonomies on Go.** `Mutex` →
  4 candidates (`sync.Mutex`, `runtime.mutex`, `internal/sync.Mutex`,
  `lockedfile.Mutex`); `Sprintf` → 5 (`fmt`, `flag`, `go/types`,
  `cmd/compile/internal/types2`). The ambiguity IS the cluster
  (M2).
- **M14 status:** go-stdlib (11,321 files) is the *scale stressor +
  style discipline oracle* (Part X §X.7 line 2877). Reproduces
  MS1 / M16 (truncation-scale amplification) and F4 (portability
  matrices) as no other corpus can.

## §2 Working recipes (Go earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **Recursive Cartography (F5 + H9)** | "Orient me in this monorepo" | Probe corpus chunk count first; if > 10K, `mcp__ripvec__get_repo_map(focus_file=src/<subdir>)` per top-level subdirectory; filter generated suffixes (`*generated*`, `zerrors_*`, `*_test.go` of suspicious size) | Per H9 scale tier table: < 5K full root; 5-10K sub-root recommended; > 10K sub-root mandatory; > 50K sub-root for everything | Part VI F5 lines 1197-1237; Part VII H9 lines 1336-1359 |
| **Build-Matrix Portability Audit (F4)** | "What changed across linux vs freebsd vs darwin?" | `mcp__ripvec__find_duplicates(threshold=0.85, intra_file=false, root=arch_subdir)` then group by file stem with per-platform suffix | Sim 0.82 inside a portability cluster = platform-specific divergence; gap in a cluster = missing port | Part VI F4 lines 1159-1194 |
| **Cross-Vendoring Duplicates (F6)** | "Is http2 deliberately vendoring ASCII helpers?" | F4 chain, then identify cluster members where the replication axis is a vendoring decision (`internal/ascii ↔ internal/http2/ascii`) | Detection-identical to F4; intent (vendoring vs platform) reads from the path structure | Part VII F6 lines 1303-1312 |
| **Ambiguity-Payload as Cluster (NC1a)** | "Find all Mutex implementations" | `mcp__ripvec__find_similar(symbol_name="Mutex")` → 4-candidate ambiguity payload IS the cluster | The "error" is the highest-bandwidth result (M2 / Pike "errors are values") | Part IX §IX.4 NC1a lines 1919-1948 |
| **Rank-Band Clustering as find_duplicates Substitute (NC5)** | "find_duplicates is capped or unavailable; I need the portability matrix anyway" | `mcp__ripvec__get_repo_map(focus_file=parent_subdir, token_budget=2000)` then group files by rank equality | Identical PageRank ≈ identical structural role (same import depth, same caller-set shape). Gap vs real find_duplicates: no per-pair similarity, intra-cluster drift invisible | Part IX §IX.4 NC5 lines 2039-2052 |
| **Generated-File Hijack Detection (N1)** | "Why is my top-9 PageRank all `zerrors_*`?" | Read the top-N of `get_repo_map`; if files match `*generated*`, `zerrors_*`, `*_test.go`, `vendor/`, `third_party/`, `node_modules/` you've hit N1 | Partition by sub-root or filter extensions; never read N1-polluted maps as the structural spine | Part VII N1 lines 1361-1377 |
| **Scale-Aware Dead-Code Sweep (M16)** | "find_dead_code on go-stdlib" | `mcp__ripvec__find_dead_code(root=corpus, summary_only=true, min_cluster_size=50, max_clusters=5)` | I#65/I#74 closed 4.1.4 via `summary_only`; without it the response exceeds MCP transport at 11K files. Treat rendered `calls[]` as summary, hop one level inward for ground truth | Part X §X.4 NC15 lines 2686-2699; M16 lines 2808-2828 |
| **Capital-Export Public-API Audit** | "Show me the public API surface of this package" | `mcp__ripvec__lsp_workspace_symbols(query="^[A-Z]", root=pkg)` — Go's style discipline makes capital-prefix the hard signal | Per M3, this is the lens that suffices alone — no triangulation needed for the public-API question | Part IX §IX.5 M3 lines 2210-2218 |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0012** (I#22) Go inverse call-graph | Closed 4.0.6 | Pre-fix: `lsp_incoming_calls` on Go method bodies returned empty | Verify post-4.0.6 substrate; `confidence=high` on BFS termination | BUG_DATABASE §1 lines 327-334 |
| **B-0039** (I#23) Go type-alias kind | Closed 4.0.6 | `type Foo = Bar` reported kind=26 | None needed | BUG_DATABASE §9 lines 788-794 |
| **B-0025** (I#45/I#51a/I#51b) Generated-file PageRank pollution | Closed 4.1.8 (architectural fix) | Pre-fix: `zerrors_windows.go` and other generated files dominated top-10 | Verify by `get_repo_map` top-N being non-generated; N1 still applies to mixed-language and very-young corpora | BUG_DATABASE §7 lines 589-611 |
| **B-0033** (I#65/I#74) `find_dead_code` response-size at scale | Closed 4.1.4 | Pre-fix: 1.36M chars on 11K go-stdlib exceeded MCP transport | Always pass `summary_only=true` on corpora > 5K files | BUG_DATABASE §8 lines 710-724 |
| **B-0059** (I#60/I#68) rendered `calls[]` cap | Closed def-level (I#60); **file-level Partial fix** | Top-30 non-table files at go-stdlib scale show `truncated_calls ≥ 2` | Per M16: rendered `calls[]` is summary; LSP per-symbol queries are ground truth; hop one inward at scale | BUG_DATABASE §1 + §11 lines 960-985 |

## §4 Language-specific BPMN — the Go scale + portability flow

```mermaid
flowchart TD
  U[User: "orient me in this Go repo" or<br/>"audit cross-platform behaviour"] --> P[Probe corpus chunk count]
  P --> S{Scale tier per H9?}
  S -->|< 5K chunks| FR[mcp__ripvec__get_repo_map<br/>token_budget=2000<br/>full root]
  S -->|5-10K chunks| SR[Sub-root recommended<br/>per top-level subdirectory]
  S -->|> 10K chunks| ME[Sub-root MANDATORY<br/>+ filter generated suffixes]
  FR --> RT[Read top-N PageRank]
  SR --> RT
  ME --> RT
  RT --> N1{Top-N matches<br/>zerrors_* / *generated*<br/>/ vendor/ / *_test.go ?}
  N1 -->|Yes — N1 hijack| PG[Partition by sub-root;<br/>or filter generated extensions]
  N1 -->|No| AS{Asking about portability?}
  AS -->|Yes| F4[**F4 Build-Matrix Audit**<br/>mcp__ripvec__find_duplicates<br/>threshold=0.85 intra_file=false<br/>root=arch_subdir]
  AS -->|No — asking about public API| CE[**Capital-Export Audit**<br/>mcp__ripvec__lsp_workspace_symbols<br/>query=^[A-Z] root=pkg]
  AS -->|No — finding dead code| DC[mcp__ripvec__find_dead_code<br/>summary_only=true<br/>min_cluster_size=50]
  F4 --> FC[Group by file stem suffix<br/>e.g., defs_*_amd64 / *_linux]
  FC --> SI{Sim 0.82 within<br/>same-suffix cluster?}
  SI -->|Yes — platform divergence| PD[Investigate the divergent member;<br/>route to ripvec:detective]
  SI -->|No — uniform cluster| OK[Portability is consistent;<br/>report cluster as the matrix]
  DC --> RC[Read clusters semantically;<br/>per M16 treat rendered calls[]<br/>as summary not truth]
  PG --> RT
```

## §5 Cross-corpus calibration

Go is exercised primarily by **go-stdlib** (the M19 dipole pristine
half; Part XI §XI.4 line 3175 names `kubernetes` as the
kernel-equivalent saturated partner — Phase 2 rotation target):

- **go-stdlib** (11,321 files) — scale stressor + style discipline
  oracle (M13 entry per Part X §X.7 line 2877). Diagnoses MS1/M16
  truncation-scale amplification, F4 portability matrices, F6
  cross-vendoring duplicates, N1 generated-file hijack.
- **kubernetes** (planned dipole partner) — would surface
  large-codebase-with-generated-clients scale at the framework
  layer. Phase 2 target.
- **Diagnostic rule:** a Go bug on go-stdlib at < 5K-file sub-root
  scope but NOT at full-root scope is a **scale-driven bug** (M16
  territory). A bug across BOTH scales is **Go-general**.

## §6 Heritage citations

Go's earned heritage (verbatim from Part IX/X bibliographies):

- **Pike, R.** *Notes on Programming in C* (1989); *Errors are
  Values* (2015) — ambiguity-as-result; the engine's "error" is
  the highest-bandwidth result (NC1a / M2). **Go-anchor for the
  ambiguity-as-cluster recipe.**
- **Cox, R.** *Why Generics?* (2019); various Gophercon talks;
  *"Codebase Refactoring (with help from Go)"* (2016) — Go's
  standard library is the style guide; `z*.go` segregated-
  generated-code convention. **M3 anchor.**
- **Cheney, D.** *Practical Go Patterns* — *"If gofmt formats it,
  it's correct"*; style discipline as the H4 instrument-distortion
  partner. **M3 anchor.**
- **Cheney, J.** *Compiling with Continuations* (1991) — never
  trust the cached summary when the source is one hop away. **M16
  anchor (truncation-scale-amplification).**
- **Pike & Thompson** Plan 9 orthogonality — naming as substrate;
  M3 reframe: the convention is the substrate; the engine is the
  index. **M16 anchor.**
- **Brooks, F.** *No Silver Bullet* — accidental complexity
  concentrates at integration points; cross-platform support IS an
  integration point at the source level (F4 heritage).
- **Polya, G.** — solve a related, simpler problem; sub-root scope
  IS the related-simpler problem when full-root is intractable (F5
  heritage).
- **Lampson, B.** — make the common case fast; for monorepos the
  common case is "find me the canonical code in this subsystem,"
  not "rank the universe" (F5 heritage).
- **Simon, H.** — bounded rationality; match the query scope to the
  cognitive budget (H9 heritage).
