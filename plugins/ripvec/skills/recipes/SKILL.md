---
name: recipes
description: Named compositional patterns for ripvec MCP — the master programmer's recipe library for orientation, debugging, refactoring, teaching, and quality audits. Use when you have a non-trivial codebase task and want a battle-tested compositional pattern instead of one-tool-at-a-time exploration. Triggers include "orient me in this codebase", "find the root cause of X", "before I rename Y", "teach me how Z works", "what's wrong with this module", "find duplicates", "is this dead code", "what depends on this", "build the call graph", "find impl blocks for this trait", "is this a god-module", "what's the cohesion of this file".
graph:
  generalizes_to:
    - ripvec:ripvec-orientation
  specializes_into: []
  cross_references:
    - ripvec:intent-routing
    - ripvec:cartographer
    - ripvec:detective
    - ripvec:refactorer
    - ripvec:onboarder
    - ripvec:sentinel
  escalate_to: ripvec:intent-routing
---

# ripvec recipes

**§0 — Graph position.** This skill is the bridge from 3.1.2-era recipe
names (Structural Spine, Blast-Radius Manifest, etc.) to the 4.1.x
cluster taxonomy in `SKILL_SEMANTIC_GRAPH.md §4`. Recipe names are
stable; what changed is the routing graph above them. The authoritative
source for each recipe's tool sequence and heritage is
`docs/AGENTIC_PATTERNS_4_0.md` (Parts I-XI, ripvec engine repo).

For **orientation triage** (which of the 5 orientations fits my task?),
load `ripvec:ripvec-orientation` first. For **phrasal lookup** ("I have
a task phrased as X; which recipe fires first?"), load
`ripvec:intent-routing`.

---

## 4.1.x cluster taxonomy — recipe cross-reference

The 4.1.x graph has 5 hub-orientations, ~15 clusters, ~55 recipes.
This table maps the 3.1.2-era recipe names to their cluster home.

| 3.1.2 recipe name | 4.1.x cluster | Hub | Part cite |
|---|---|---|---|
| **Structural Spine** (T1) | CL-STRUCTURAL-SPINE | Cartographer | Part I §1 (96-104) |
| **Intent First, Text Second** (T2) | CL-CONCEPT-TOUR | Cartographer | Part I §1 (106-114) |
| **Trait Constellation Mapping** (T3) | CL-NAMES-TAXONOMY | Cartographer | Part I §1 (116-127) |
| **Top-N Hot Functions Per File** (T4) | CL-STRUCTURAL-SPINE | Cartographer | Part I §1 (129-139) |
| **Topic-Sensitive Rebias** (T5) | CL-CONCEPT-TOUR | Cartographer | Part I §1 (141-148) |
| **Sibling Diff** (T6) | CL-SIBLING-DIFF | Detective | Part I §2 (268-277) |
| **Recursive Caller Climb** (T7) | CL-CAUSAL-INTERVENTION | Detective | Part I §2 (279-292) |
| **Broken Contract Hunt** (T8) | CL-CONTRACT-AUDIT | Detective | Part I §2 (294-306) |
| **Symptom→Suspect Triage** (T9) | CL-CAUSAL-INTERVENTION | Detective | Part I §2 (307-315) |
| **Blast-Radius Manifest** (T10) | CL-BLAST-RADIUS | Refactorer | Part I §3 (415-426) |
| **Drift Index Audit** (T11) | CL-NAMING-DRIFT | Refactorer | Part I §3 (428-435) |
| **Impl Survey Before Trait Edit** (T12) | CL-CONTRACT-SURVEY | Refactorer | Part I §3 (437-446) |
| **Top-N Architectural Tour** (T13) | CL-ARCHITECTURAL-TOUR | Onboarder | Part I §4 (559-566) |
| **Concept-by-Example Triangulation** (T14) | CL-CONCEPT-BY-EXAMPLE | Onboarder | Part I §4 (568-577) |
| **Recursive Narration Descent** (T15) | CL-RECURSIVE-NARRATION | Onboarder | Part I §4 (581-594) |
| **Dead-Code Sweep** (T16) | CL-DEAD-CODE-SWEEP | Sentinel | Part I §5 (691-701) |
| **Orphan-Trait Extinction** (T17) | CL-ORPHAN-TRAIT | Sentinel | Part I §5 (704-715) |
| **Cohesion Refraction** (T18) | CL-COHESION-REFRACTION | Sentinel | Part I §5 (718-727) |
| **PageRank-Anchored Concept Tour** (C1) | CL-CONCEPT-TOUR | Cartographer | Part I §1 (150-165) |
| **Focus-Delta Topic Fingerprinting** (C2) | CL-FOCUS-DELTA | Cartographer | Part I §1 (167-184) |
| **Causal Subsystem Isolation** (C3) | CL-CAUSAL-INTERVENTION | Detective | Part I §2 (317-338) |
| **Normalization Contract Audit** (C4) | CL-CONTRACT-AUDIT | Detective | Part I §2 (340-356) |
| **Duplicate-Anchored Extraction** (C5) | CL-DUPLICATE-ANCHORED-EXTRACTION | Refactorer | Part I §3 (448-460) |
| **Prerequisite-Cleanup Sizing** (C6) | CL-BLAST-RADIUS | Refactorer | Part I §3 (462-476) |
| **Gini-Coefficient Hide Metric** (C7) | CL-HIDE-VS-EXPOSE | Refactorer | Part I §3 (498-519) |
| **Invariant Layer Cake** (C8) | CL-INVARIANT-LAYER | Onboarder | Part I §4 (614-627) |
| **Idiom Crystallization** (C9) | CL-IDIOM-CRYSTALLIZATION | Onboarder | Part I §4 (599-611) |
| **Duplication-as-Hidden-Module** (C10) | CL-DUPLICATION-AS-MODULE | Sentinel | Part I §5 (729-744) |
| **PageRank Polarity Probe** (C11) | CL-PAGERANK-POLARITY | Sentinel | Part I §5 (746-766) |
| **Corpus-Cap Blind-Spot Audit** (C12) | CL-CORPUS-CAP-AUDIT | Sentinel | Part I §5 (768-781) |

---

## When to reach for which pattern (quick decision table)

| Situation | Recipe | Hub-skill |
|---|---|---|
| Landing in an unfamiliar codebase | **T1 + T13** | `ripvec:cartographer` |
| Symptom but no stack trace | **T9** | `ripvec:detective` |
| Works alone, broken in integration | **T7 Recursive Caller Climb** | `ripvec:detective` |
| "Looks reasonable but is wrong" | **T6 Sibling Diff** | `ripvec:detective` |
| Before renaming any symbol | **T10 Blast-Radius Manifest** | `ripvec:refactorer` |
| Before editing a trait | **T12 Impl Survey** | `ripvec:refactorer` |
| Suspicion of DRY violation | **C5 Duplicate-Anchored Extraction** | `ripvec:refactorer` |
| Teach a codebase to another agent | **T13 + T14 + T15** | `ripvec:onboarder` |
| Audit for dead code / drift | **T16 + C11** | `ripvec:sentinel` |
| Find god-modules / dead islands | **C11 PageRank Polarity** | `ripvec:sentinel` |

---

## The 10 compositional primitives (P1-P10)

Reusable cross-hub shapes. When a recipe doesn't fit, fall back to the
primitive — it's the more general form.

| ID | Primitive | Cluster edge it provides |
|---|---|---|
| P1 | Triangulation | semantic ∩ structural ∩ precision |
| P2 | Fixed-Point Expansion | recursive LSP traversal until quiescent (blast radius, dead-code) |
| P3 | Sibling Diff | `find_similar` from a known location; divergence IS the finding |
| P4 | Duplicates as Taxonomy | largest near-dup clusters = de-facto idioms |
| P5 | Names as Folk Taxonomy | dedup-delta ≥0.45 = theory fracture |
| P6 | Causal Intervention via Tooling | `log_level` = Pearl do-operator; `previous_filter` = reversibility |
| P7 | Trait Constellation Survey | (impls, refs) trichotomy: orphan / vestigial / load-bearing |
| P8 | PageRank Polarity | top/bottom outliers + breadth check = god-module / dead-island |
| P9 | Inheritance-Aware Recall Bridge | refs/incoming ratio > 5× ⇒ MRO/mixin dispatch |
| P10 | Chunk-Align Before Cross-Tool | route `lsp_workspace_symbols` location through `lsp_document_symbols` before cross-tool composition |

Full definitions and worked examples: [primitives](references/primitives.md)

---

## Scale discipline (H8: scope before similarity)

`find_duplicates` and `find_dead_code` silently hit the 10K-chunk corpus
cap on large repos. Sub-root scoping is mandatory above ~5K files.

| Corpus size | Approach |
|---|---|
| <5K files | Full root OK |
| 5K-10K | Sub-root recommended |
| 10K-50K | Sub-root mandatory |
| >50K | Sub-root for everything; H9 tier table |

---

## Heritage

Recipe language descended from a 15-agent (5 orientations × 3 model
tiers) brainstorm synthesized into `docs/AGENTIC_PATTERNS_4_0.md`
(Parts I-XI, ~3,400 lines). Master citations: Brooks, Hickey, Naur,
Pearl, Alexander, Polya, Parnas, Cunningham, Liskov, Popper, Knuth,
Pirsig, Haveliwala, Reynolds, Cantrill.

The per-orientation reference files contain the full long-form
tool sequences and heritage anchors:
[cartographer](references/cartographer.md) |
[detective](references/detective.md) |
[refactorer](references/refactorer.md) |
[onboarder](references/onboarder.md) |
[sentinel](references/sentinel.md)

Primitives: [primitives](references/primitives.md) |
Heuristics: [heuristics](references/heuristics.md) |
Empirical revisions: [empirical-revisions](references/empirical-revisions.md)
