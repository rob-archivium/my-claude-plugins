---
name: intent-routing
description: >
  Use when you have a concrete codebase task and need to know which ripvec
  orientation, cluster, and first recipe to fire. Triggers on verbatim
  phrasal matches including: "what matters in this codebase", "how is this
  project organized", "where should I start", "show me the architectural
  spine", "find the auth/cache/retry logic", "find the code that handles X",
  "this looks reasonable but it's wrong", "works in isolation fails in
  integration", "something violates an invariant", "before I rename X",
  "what's the blast radius", "before I edit this trait", "should I extract
  these", "teach me how Z works", "bring me up to speed", "explain the
  architecture", "find dead code", "is X dead", "what's wrong with this
  module", "find god-modules", "find dead islands", "audit this codebase
  for drift", "find unused traits", "find files that need splitting".
  Also triggers on tool-surface meta-questions: "which ripvec tools are
  available", "find_dead_code says X is dead but I don't believe it",
  "which corpora should I validate against".
graph:
  generalizes_to:
    - ripvec:ripvec-orientation
  specializes_into: []
  cross_references:
    - ripvec:cartographer
    - ripvec:detective
    - ripvec:refactorer
    - ripvec:onboarder
    - ripvec:sentinel
    - ripvec:recipes
  escalate_to: ripvec:ripvec-orientation
---

# intent-routing

**Lookup table.** Intent phrase → hub-skill → cluster → first recipe →
ripvec MCP terminal.

Source: `docs/SKILL_TASK_INTENT_INDEX.md §§1-9` (ripvec engine repo).
This skill lifts the high-volume rows and compresses the meta-structure;
the full table (all rows with caveats and citation line-ranges) lives in
that file.

---

## §1 — Orientation intents

| Verbatim intent phrase | Hub-skill | First recipe | Terminal tool |
|---|---|---|---|
| "What matters in this codebase?" | `ripvec:cartographer` | **T1 Structural Spine** | `get_repo_map(token_budget=2000)` |
| "How is this project organized?" | `ripvec:cartographer` | **T1 + AST Priority** (type tier only) | `get_repo_map` |
| "Where should I start reading?" | `ripvec:cartographer` | **T1 + T13** (top-5 narrate) | `get_repo_map` → `search` |
| "Show me the architectural spine." | `ripvec:cartographer` | **T1** | `get_repo_map(token_budget=2000)` |
| "Where is the auth / cache / retry logic?" | `ripvec:cartographer` | **T2 Intent First, Text Second** | `search(corpus="code")` |
| "Find the code that handles X." | `ripvec:cartographer` | **T2** then **T5** (rebias) | `search` → `get_repo_map(focus_file=anchor)` |
| "What lives near concept X?" | `ripvec:cartographer` | **C1 PageRank-Anchored Concept Tour** | `search` → `get_repo_map(focus_file=anchor)` → `find_similar` |
| "How does X actually work?" / "Why does the codebase do Y?" | `ripvec:cartographer` | **F3 Theory-First Prose Probe** | `search(corpus="docs", rerank="always")` |
| "What's this module's true topic?" | `ripvec:cartographer` | **C2 Focus-Delta Topic Fingerprinting** | `get_repo_map` (global) → `get_repo_map(focus_file=module)` |
| "Does file A depend on file B?" | `ripvec:cartographer` | **NC4 Focus-Delta Dependency Direction** | `get_repo_map(focus_file=A)` vs `get_repo_map(focus_file=B)` |
| "Show me all traits / interfaces." | `ripvec:cartographer` | **T3 Trait Constellation Mapping** | `lsp_workspace_symbols(kind=11/22)` |
| "Top PageRank is generated files / monorepo illegible." | `ripvec:cartographer` | **F5 Recursive Cartography** | `get_repo_map(root=subtree)` repeated |

Full table with caveats: `SKILL_TASK_INTENT_INDEX.md §1` (lines 38-56).

---

## §2 — Debugging intents

| Verbatim intent phrase | Hub-skill | First recipe | Terminal tool |
|---|---|---|---|
| "This looks reasonable but it's wrong." | `ripvec:detective` | **T6 Sibling Diff** | `find_similar(symbol_name=X, top_k=8)` |
| "Why does X work and Y break?" | `ripvec:detective` | **T6 + P3** | `find_similar` → `lsp_hover` per sibling |
| "Works in isolation, fails in integration." | `ripvec:detective` | **T7 Recursive Caller Climb** | `lsp_prepare_call_hierarchy` → `lsp_incoming_calls` (fixed-point) |
| "Is component X causal, or just nearby?" | `ripvec:detective` | **C3 Causal Subsystem Isolation** | `log_level(suspect=trace)` → `debug_log` → `log_level(previous_filter)` |
| "I have a symptom and no stack trace." | `ripvec:detective` | **T9 Symptom→Suspect Triage** | `get_repo_map` + `search` + `lsp_document_symbols` + `log_level` |
| "Something violates an invariant." | `ripvec:detective` | **T8 Broken Contract Hunt** | `lsp_workspace_symbols` → `lsp_references` → `lsp_goto_implementation` → `lsp_hover` |
| "`find_dead_code` says X is dead but I don't believe it." | `ripvec:detective` | **NC11 Closure-Attributed Call-Edge Lookup** | `lsp_prepare_call_hierarchy` + `lsp_incoming_calls` vs `find_dead_code` cluster |
| "Static analyzer disagrees with LSP." | `ripvec:detective` | **NC11** (divergence IS the diagnostic) | `find_dead_code` + `lsp_incoming_calls` — compare call graphs |

Full table: `SKILL_TASK_INTENT_INDEX.md §2` (lines 62-78).

---

## §3 — Refactoring intents

| Verbatim intent phrase | Hub-skill | First recipe | Terminal tool |
|---|---|---|---|
| "Before I rename X." | `ripvec:refactorer` | **T10 Blast-Radius Manifest** | `lsp_workspace_symbols(X)` → `lsp_prepare_call_hierarchy` → `lsp_incoming_calls` (P2 fixed-point) |
| "What's the blast radius of changing X?" | `ripvec:refactorer` | **T10 + P2** | same chain |
| "How big is this refactor going to be?" | `ripvec:refactorer` | **C6 Prerequisite-Cleanup Sizing** | T10 result → (incoming, outgoing, strong, weak) signature |
| "Before I edit this trait." | `ripvec:refactorer` | **T12 Impl Survey Before Trait Edit** | `lsp_goto_implementation` → `lsp_hover` per impl |
| "Should I Extract Method on these two?" | `ripvec:refactorer` | **False-Twins Test** | `find_similar` pair → `lsp_outgoing_calls` intersection ≥70% ⇒ extract |
| "Where can I unify these N similar impls?" | `ripvec:refactorer` | **C5 Duplicate-Anchored Extraction** | `find_duplicates` → outgoing intersection = natural API |
| "Is this module a leaky abstraction?" | `ripvec:refactorer` | **C7 Gini-Coefficient Hide Metric** | `lsp_references` fan-out → breadth across subsystems |
| "Six functions named `process_*` — theory fracture?" | `ripvec:refactorer` | **T11 Drift Index Audit** | `lsp_workspace_symbols("process_")` → dedup-delta (threshold 0.45) |

Full table: `SKILL_TASK_INTENT_INDEX.md §3` (lines 83-99).

---

## §4 — Onboarding & teaching intents

| Verbatim intent phrase | Hub-skill | First recipe | Terminal tool |
|---|---|---|---|
| "Bring me up to speed on this codebase." | `ripvec:onboarder` | **T13 Top-N Architectural Tour** | `get_repo_map(token_budget=2000)` → top-5 files |
| "Teach me how Z works." | `ripvec:onboarder` | **T14 Concept-by-Example Triangulation** | `search(Z)` → `find_similar` on best hit |
| "Explain this codebase's idioms." | `ripvec:onboarder` | **C9 Idiom Crystallization** | `find_duplicates` → top-10 clusters |
| "What patterns recur in this codebase?" | `ripvec:onboarder` | **P4 Duplicates as Taxonomy** | `find_duplicates` BEFORE the tour |
| "Walk me through how main() works." | `ripvec:onboarder` | **T15 Recursive Narration Descent** | `lsp_goto_definition(main)` → `lsp_outgoing_calls` recursively |
| "What does this code protect against?" | `ripvec:onboarder` | **C8 Invariant Layer Cake** | DATA → FLOW → INVARIANTS → CORNERS order |

Full table: `SKILL_TASK_INTENT_INDEX.md §4` (lines 104-117).

---

## §5 — Quality / sentinel intents

| Verbatim intent phrase | Hub-skill | First recipe | Terminal tool |
|---|---|---|---|
| "Find dead code." | `ripvec:sentinel` | **T16 Dead-Code Sweep** | `find_dead_code` (confidence-band-aware) |
| "Is X dead?" | `ripvec:sentinel` | **T16 + NC11** if LSP disagrees | `find_dead_code` → `lsp_incoming_calls` confirm |
| "Cluster output looks huge / suspicious." | `ripvec:sentinel` | **NC15 Response-Size Budget** | `find_dead_code(min_cluster_size=N, max_clusters=M)` |
| "Find unused traits / interfaces." | `ripvec:sentinel` | **T17 Orphan-Trait Extinction** | `lsp_goto_implementation` + `lsp_references` → (impls, refs) trichotomy |
| "Is this file doing too many things?" | `ripvec:sentinel` | **T18 Cohesion Refraction** | `find_duplicates(intra_file=true)` + `lsp_document_symbols` |
| "Find god-modules." | `ripvec:sentinel` | **C11 PageRank Polarity Probe** | `get_repo_map` → rank > μ+2σ + module breadth > 40% |
| "Find dead islands." | `ripvec:sentinel` | **C11** (bottom outliers) | `get_repo_map` → rank < 0.1σ + zero non-test refs |
| "Audit this whole module for drift." | `ripvec:sentinel` | **C11 first** → fan out | `get_repo_map` → `find_dead_code` / `find_duplicates` / `lsp_workspace_symbols` |
| "find_duplicates returned a small list — am I missing things?" | `ripvec:sentinel` | **C12 Corpus-Cap Blind-Spot Audit** | check `capped=true`; re-run with `root=subdirectory` |

Full table: `SKILL_TASK_INTENT_INDEX.md §5` (lines 122-139).

---

## §6 — Tool-surface / meta intents

| Verbatim intent phrase | Action | Terminal |
|---|---|---|
| "Which ripvec tools are available?" | **NC6 Tool Availability Probe** | `ToolSearch("ripvec")` |
| "My MCP call returned an unexpected error shape." | **M2 Ambiguity Payload** — the candidate list IS the result | (read the error payload) |
| "`calls[]` looks sparse but I know there are more edges." | **M16 Truncation-Scale-Amplification** | `lsp_outgoing_calls` per symbol (ground truth vs rendered summary) |
| "find_dead_code crashed / response too large." | **NC15** parameters | `find_dead_code(min_cluster_size=3, max_clusters=20)` |

Full table: `SKILL_TASK_INTENT_INDEX.md §§7-8` (lines 155-173).

---

## §7 — Anti-patterns: when the lookup table doesn't apply

| Phrasing that should make you stop | Redirect |
|---|---|
| "Top PageRank is `tests/test_*.py`." | H1′: strip `*/tests/*`, apply H9 sub-root |
| "I'm about to delete a public function it looks unused." | N2 Wired-Stub: wire / remove / annotate per resolution tree |
| "Trusting `find_dead_code` with `confidence=Low`." | NC11 first; check M1 Late-Binding Budget |
| "My drift quotient is 0.15." | Falsified threshold; use 0.45 |
| "Running `find_duplicates` at root on 10K+ files." | H9 sub-root mandatory |

Full anti-pattern table: `SKILL_TASK_INTENT_INDEX.md §9` (lines 179-190).

---

## §8 — How this skill is meant to be used

1. Agent says something. Match closest phrase in §§1-6.
2. Row gives the hub-skill. Open it to verify the stance fits.
3. Row gives the first recipe. Run it.
4. First recipe doesn't fit? Check `SKILL_SEMANTIC_GRAPH.md §4` — each
   cluster body names 2-5 recipes ranked; try the next.
5. Cluster doesn't fit? Each cluster names `composes-into` neighbors.
   Follow the edge.
6. Nothing fits? Fall back to primitives P1-P10 (see `ripvec:recipes`).

Cite every finding with its falsification rule (Popper / H7): "I ran a
*PageRank Polarity Probe*; finding: `core::cache` is rank μ+2.4σ + 47%
module breadth ⇒ god-module candidate" beats "looks load-bearing".
