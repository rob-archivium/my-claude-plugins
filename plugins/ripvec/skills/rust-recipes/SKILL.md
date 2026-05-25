---
name: rust-recipes
description: >
  Use when working with Rust code. Triggers on: "trait constellation",
  "impl survey", "blast radius before rename", "find_dead_code on this
  Rust crate", "rayon closure attribution", "tokio::spawn dead caller",
  "ripvec self-corpus", "test boilerplate floor in find_duplicates",
  "trait dyn dispatch unresolved", "default trait method overridden".
  Specializes the hub skills for Rust idioms — trait/impl constellations,
  closure-bounded call attribution (the canonical I#57 site), high-
  precision LSP blast-radius for renames.
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
  escalate_to: ripvec:refactorer
---

# rust-recipes — Rust as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` (especially Part X §X.7
where ripvec-self is named the closure / hub-truncation oracle) and
`docs/BUG_DATABASE.md` §1 by line. **Rust is the language ripvec
self-tests on** — the M14 pristine substrate for closure-attributed
call-edge bugs and the canonical site where I#57 was discovered
(NC11, Part IX §IX.4 lines 2128-2182).

## §0 Graph position

Specializes the five hub orientations for Rust. Triage
(`ripvec:ripvec-orientation` → `ripvec:intent-routing`) routes here
when `.rs`-dominant. Rust work most often escalates to
`ripvec:refactorer` (because Rust's strong type system makes T10
Blast-Radius Manifest produce *exact* counts; renames are tractable
with high precision).

## §1 Language character

What ripvec sees on a Rust corpus:

- **Closures used to swallow call attribution.** B-0004 (I#57) closed
  4.1.2: root cause was BFS reading `def_callees`/`def_callers`
  truncated at `MAX_NEIGHBORS=5`, not a graph schism. Ripvec self-
  corpus `live_defs` 893→983 (Wave 4) → 1010 (Wave 5) over the
  4.1.2 → 4.1.3 arc, then ADR-validated to 5/5 agreement between
  LSP and BFS paths.
- **Closures within `rayon::iter().for_each(...)`,
  `.par_iter().for_each(|| ...)`, `tokio::spawn(async { ... })`,
  `.map(|x| ...)` were the canonical sites.** NC11 recipe codifies
  the diagnostic: when `find_dead_code` and `lsp_incoming_calls`
  disagree, the divergence IS the bug location.
- **Trait constellations.** T3 historically blocked by BM25 ranking
  trait impls above the trait declaration (Part VII line 1498-1502);
  the META cycle 9/10 finding flagged Rust trait-impl helper BFS
  gap (`dyn` dispatch). Still investigate via
  `lsp_goto_implementation` AND `lsp_workspace_symbols(kind=11)`
  combined.
- **`#[cfg(test)] mod tests { ... }` boilerplate forms a similarity
  floor.** B-0026 (I#47) Open: 4-line test-mod headers match across
  every test file at sim ≥ 0.99. Mitigation: pass `intra_file=false`
  AND ignore clusters whose preview is `mod tests` boilerplate.
- **Strong-type call graph → high T10 precision.** Renames have
  *exact* counts. Heritage: Pierce (TaPL) — the type system IS the
  refactoring oracle.
- **M14 status:** ripvec-self is the *closure / hub-truncation
  oracle* (Part X §X.7, line 2876) AND the mid-scale Rust pristine
  pristine (Part XI §XI.6, line 3262). The constitutional
  self-test corpus.

## §2 Working recipes (Rust earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **Closure-Attributed Call-Edge Lookup (NC11)** | "Why does find_dead_code say X is dead when I know G calls it?" | `mcp__ripvec__find_dead_code` reports F dead → `mcp__ripvec__lsp_prepare_call_hierarchy(F)` → `mcp__ripvec__lsp_incoming_calls(item)` → if caller G found, inspect G's source around `fromRanges[].start.line` for `.for_each(|| ...)` / `.map(|x| ...)` / `tokio::spawn` | Post-4.1.2 the original I#57 is fixed; NC11 still applies for residual closure-bounded bugs and as a diagnostic technique | Part IX §IX.4 NC11 lines 2128-2182 |
| **Trait Constellation Survey (T3)** | "Find all impls of RerankBackend" | `mcp__ripvec__lsp_goto_implementation` on the trait + `mcp__ripvec__lsp_workspace_symbols(query="RerankBackend", kind=11)` then intersect | T3 historically blocked because BM25 ranks impls above the trait declaration; cross-check both result sets | Part VII lines 1498-1502; META Cycle 9/10 Rust dyn-dispatch gap |
| **Blast-Radius Manifest (T10)** | "Before renaming this fn, who's affected?" | `mcp__ripvec__lsp_prepare_call_hierarchy(location)` → `mcp__ripvec__lsp_incoming_calls(item)` for ALL callers; supplement with `mcp__ripvec__lsp_references` | Rust's strong typing produces *exact* counts; you can size the PR per invariant grouping (4 commits for 38 refs across 21 files style) | Recipes library T10 |
| **Sibling Diff (C3)** | "This impl looks right but tests fail" | `mcp__ripvec__find_similar(location=current_impl)` returns sibling implementations; diff against the known-good | Closure-attributed bugs (NC11) often surface as "this is identical to X but X works" | Part X §X.4 (sibling-diff family) |
| **CALL_GRAPH_UNIFICATION ADR Validation** | "Verify LSP path and BFS path agree" | Pick 5 non-trivial fns; chain `lsp_prepare_call_hierarchy → lsp_incoming_calls` AND `find_dead_code` per fn | Post-4.1.3 ripvec-self shows 5/5 = 100% agreement (Part XI §XI.1 lines 3008-3014); this is the constitutional sentinel | Part XI §XI.1 Finding 4 |
| **Confidence-Band Validation** | "How confident is this dead-code report?" | Read `confidence` field from `find_dead_code` response on Rust | On ripvec-self post-4.1.3, confidence climbed Low → Medium then held; a regression means new closure-bounded edges entered | M1 (Part IX §IX.5), CALL_GRAPH_UNIFICATION.md |
| **Test-Boilerplate Floor Mitigation** | "find_duplicates buries my signal in mod tests headers" | `mcp__ripvec__find_duplicates(threshold=0.85, intra_file=false)` then filter results where `preview` starts `#[cfg(test)] mod tests` | Open bug B-0026; until min-chunk-LOC param lands, filter client-side | BUG_DATABASE §7 lines 613-622 |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0004** (I#57) Rust closure call-edge attribution | Closed 4.1.2 | Pre-fix: closures inside `rayon::iter().for_each(|| ...)` swallowed call attribution; `find_dead_code` and `lsp_incoming_calls` disagreed | Verify via NC11 recipe; if reproduces, you're on pre-4.1.2 substrate | BUG_DATABASE §1 lines 156-167 |
| **B-0026** (I#47) Rust test-boilerplate sim floor | Open (P3) | `#[cfg(test)] mod tests {` 4-line headers cluster at sim ≥ 0.99 across every test file | Client-side filter on `preview` prefix; or add `min_chunk_loc=8` once it lands | BUG_DATABASE §7 lines 613-622 |
| **B-0032** (I#52) `find_similar` cosine > 1.0 | Open (P3 cosmetic) | sim 1.0000001 on F2 duplicates | Clamp client-side to [0.0, 1.0] | BUG_DATABASE §7 lines 688-704 |
| **META Cycle 9/10 Rust dyn-dispatch helper BFS gap** | Open (under investigation) | T3 Trait Constellation incomplete for `dyn Trait` dispatch sites | Combine `lsp_goto_implementation` AND `lsp_workspace_symbols(kind=11)` and `find_similar(symbol_name=TraitName)`; treat as triangulation | Part VII T3 + META Cycle 9/10 notes (project state) |
| **B-0054** (I#26/I#50) `find_similar(location=…)` absolute-path asymmetry | Partial fix | Absolute path returns silent empty; relative succeeds | Strip root prefix from `location.file_path` before calling | BUG_DATABASE §11 lines 903-925 |

## §4 Language-specific BPMN — the Rust closure-edge diagnosis flow

```mermaid
flowchart TD
  U[User: "find_dead_code reports X dead<br/>but I know it's called"] --> S[mcp__ripvec__find_dead_code<br/>summary_only=true]
  S --> FD{Dead cluster includes<br/>functions you believe live?}
  FD -->|No| RR[Trust the report; route to<br/>ripvec:refactorer for removal]
  FD -->|Yes| PH[mcp__ripvec__lsp_prepare_call_hierarchy<br/>on suspect dead fn F]
  PH --> IC[mcp__ripvec__lsp_incoming_calls<br/>item=that CallHierarchyItem]
  IC --> CR{Callers returned?}
  CR -->|No| ACT[F may be genuinely dead;<br/>or trait-dyn-dispatched<br/>route to Trait Constellation T3]
  CR -->|Yes — caller G found| RD[Read G source around<br/>fromRanges[].start.line]
  RD --> CL{Call inside .for_each / .map /<br/>tokio::spawn / .par_iter closure?}
  CL -->|Yes| NC[**NC11 confirmed**<br/>closure-bounded call attribution<br/>missing from BFS]
  CL -->|No| OT[Other engine gap;<br/>file via BUG_DATABASE template]
  NC --> SU{Post-4.1.2 substrate?}
  SU -->|Yes| RS[Regression — file new bug<br/>cycle B-0004 was closed]
  SU -->|No| WK[Pre-4.1.2 substrate;<br/>NC11 diagnostic is the workaround]
  ACT --> T3[**T3 Trait Constellation**<br/>lsp_goto_implementation<br/>+ lsp_workspace_symbols kind=11]
```

## §5 Cross-corpus calibration

Rust is exercised primarily by **ripvec-self** (per M19 dipole, the
pristine half; Part XI §XI.4 line 3175 names `rust-analyzer` as the
saturated dipole partner — Phase 2+ rotation target):

- **ripvec-self** (~500 files at audit time) — M14 pristine
  substrate. Closure / hub-truncation oracle (M13 entry per Part X
  §X.7 line 2876). Validates the CALL_GRAPH_UNIFICATION ADR
  empirically each cycle.
- **rust-analyzer** (planned dipole partner) — would surface
  dyn-dispatch scale-mass and the trait constellation gap at
  language-server-internals scale.
- **Cycle 10 W1 success:** Python/JS def-query scoping fix landed,
  with Rust acting as the regression sentinel (the fix did not
  break ripvec-self).
- **Diagnostic rule:** a Rust bug on ripvec-self is **almost
  certainly engine-load-bearing** because ripvec-self is the
  closure / hub-truncation oracle — that is its diagnostic
  speciality.

## §6 Heritage citations

Rust's earned heritage:

- **Pierce, B.** *Types and Programming Languages* (2002) — the type
  system IS the refactoring oracle. T10 Blast-Radius derives its
  precision from Rust's static guarantees. **Rust-T10 anchor.**
- **Reynolds, J.** *Types, Abstraction and Parametric Polymorphism*
  (1983); *Definitional Interpreters* (1972) — what fn-ptr tables /
  trait objects give up at static-analysis layer; every late-bound
  dispatch is morally a closure. **NC11 + MK-4 shared anchor.**
- **Cantrill, B.** DTrace papers (2006) — runtime observability as
  the answer to vtable-dispatched systems; the same gap as M1 LBB.
- **Hickey, R.** *Are We There Yet?* (2009); *Simple Made Easy*
  (2011) — place-oriented programming as the engineering choice
  Rust's interior-mutability-with-locks makes deliberately. M1 LBB
  anchor for Rust's closure / async story.
- **Cheney, J.** *Compiling with Continuations* (1991) — never trust
  the cached summary when the source is one hop away; heritage for
  M16 truncation-scale-amplification (which broke I#57 on Rust
  ripvec-self specifically because rayon closures fanned past
  MAX_NEIGHBORS=5).
- **Brooks, F.** *No Silver Bullet* — essence vs accident; the
  rendering cap on `def_callees` was accident, the reachability was
  essence (M12 use-mention, fixed in 4.1.3).
- **Quine, W.V.O.** *Mathematical Logic* §4 (1940); *Two Dogmas*
  (1951) — use-mention discipline (M12). The I#57 instance is
  literally a Quinean slip materialized in Rust code.
