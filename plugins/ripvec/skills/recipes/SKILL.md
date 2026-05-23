---
name: ripvec-recipes
description: Named compositional patterns for ripvec MCP — the master programmer's recipes for orientation, debugging, refactoring, teaching, and quality audits. Use when you have a non-trivial task on an unfamiliar codebase and want to reach for a battle-tested compositional pattern instead of one-tool-at-a-time exploration. Triggers include "orient me in this codebase", "find the root cause of X", "before I rename Y", "teach me how Z works", "what's wrong with this module", "find duplicates", "is this dead code", "what depends on this", "build the call graph", and "find the impl blocks for this trait".
---

# ripvec recipes — the uber-power programmer's pattern language

A curated library of **named compositional patterns** for ripvec MCP tools. Each pattern is a specific tool sequence with a specific cognitive payoff, named so you can invoke it by referring to it ("run a *PageRank-Anchored Concept Tour* on the auth module").

The recipes assume ripvec 3.1.2 semantics:
- All LSP tools work without an explicit `root` parameter.
- `lsp_goto_implementation` returns real impl blocks (not the trait declaration).
- `lsp_workspace_symbols` dedups by `(name, kind)`.
- `lsp_prepare_call_hierarchy` is overload-aware and filters non-callable kinds.
- `find_duplicates` default `threshold=0.5`, `intra_file=false`, 10K-chunk corpus cap.
- Chunks carry populated `name` field.

**Core invariant: ripvec composes.** Every tool returns LSP-shaped grounding (`{file_path, line, character}`) so the output of any tool can feed any other. The patterns exploit this — they are *not* checklists of which tool to call, they are *chains* where each tool's output reshapes the next tool's input. Single-tool use produces shallow results; the recipes' value emerges in composition.

---

## When to reach for which pattern

| Situation | Reach for | Reference |
|---|---|---|
| Landing in an unfamiliar codebase | **Structural Spine**, **PageRank-Anchored Concept Tour**, **Names as Latent Taxonomy** | [cartographer](references/cartographer.md) |
| Symptom but no stack trace | **Semantic Hypothesis Triage** | [detective](references/detective.md) |
| Working in isolation, broken in integration | **Recursive Caller Climb** | [detective](references/detective.md) |
| "This looks reasonable but is wrong" | **Sibling Diff** | [detective](references/detective.md) |
| Before renaming any symbol | **Blast-Radius Manifest** | [refactorer](references/refactorer.md) |
| Before editing a trait | **Impl Survey**, **Contract Survey** | [refactorer](references/refactorer.md) |
| Suspicion of DRY violation | **Duplicate-Anchored Extraction**, **False-Twins Test** | [refactorer](references/refactorer.md) |
| Teach another agent a codebase | **Top-N Architectural Tour**, **Concept-by-Example Triangulation**, **Recursive Narration Descent** | [onboarder](references/onboarder.md) |
| Audit for dead code / drift | **Dead-Code Sweep**, **Orphan-Trait Extinction**, **Cohesion Refraction Test** | [sentinel](references/sentinel.md) |
| Measure coupling / fan-out | **Fan-Out God-Function Probe**, **PageRank Polarity** | [sentinel](references/sentinel.md) |
| Find naming drift | **Names as Latent Taxonomy** (dedup-delta probe) | [cartographer](references/cartographer.md), [sentinel](references/sentinel.md) |

---

## The eight compositional primitives

Reusable algorithmic patterns that recur across orientations. Memorize their shapes; the recipes above are specializations.

1. **Triangulation** — semantic + structural + precision; never trust one view.
2. **Fixed-Point Expansion** — recursive LSP traversal until quiescent.
3. **Sibling Diff** — `find_similar` from a known location; the codebase is its own oracle.
4. **Duplicates as Taxonomy** — `find_duplicates` reveals the codebase's de-facto pattern language.
5. **Names as Folk Taxonomy** — `lsp_workspace_symbols` dedup-delta measures theory fracture.
6. **Causal Intervention via Tooling** — `log_level` as Pearl's do-operator; `previous_filter` makes interventions reversible.
7. **Trait Constellation Survey** — `lsp_goto_implementation` (post-R3.1) enables contract audit, orphan detection, default-method extraction.
8. **PageRank Polarity** — outliers in BOTH tails are drift signals.

Full definitions and worked examples: [primitives](references/primitives.md)

---

## The eight heuristics (when to reach for which composition)

The principles that govern *when* to compose, *which* tools, *in what order*.

1. The map you don't summon costs nothing. *(Simon, bounded rationality.)*
2. Triangulate before trusting. *(Brooks: conceptual integrity.)*
3. The codebase is its own oracle. *(Polya: vary the problem.)*
4. The instrument's distortions encode the specimen's pathologies. *(Pirsig: every anomaly is data.)*
5. Names are theory; symbols are evidence; structure is consequence. *(Naur.)*
6. Hide is the dual of expose. *(Parnas.)*
7. Every diagnosis must be falsifiable. *(Popper.)*
8. **Scope before similarity at scale.** `find_duplicates`/large-corpus tools silently hit the 10K cap; scope `root=` to a module-sized subtree first. *(Empirical, post-codex exercise.)*

Full discussion: [heuristics](references/heuristics.md)

---

## How to use this skill in practice

When you reach for ripvec on a non-trivial task, the workflow is:

```
1. Identify the orientation (cartography / detective / refactor / onboard / sentinel)
2. Pick a named pattern from that orientation
3. Execute the chain, capturing LSP-shaped grounding at each step
4. If the chain hits a dead-end, apply a primitive (e.g., Triangulate by
   adding a third view; or Fixed-Point Expand by recursing)
5. Cite the pattern by name in your report — it becomes shared vocabulary
   for the team
```

Cite patterns by name in PR descriptions, ADRs, and tickets. "I ran a
*Blast-Radius Manifest* on the symbol; 38 refs across 21 files; the rename
will land in 4 commits per the invariant grouping" is more useful than "I
looked at where it's used."

---

## Known gaps and pitfalls (empirical)

Patterns that need adaptation, learned from running them against real
codebases (codex 4.6K files, ripvec 0.5K files):

- **Cursor positioning matters.** `lsp_outgoing_calls`, `lsp_incoming_calls`,
  `find_similar` all silently underperform if the cursor isn't on the symbol's
  name identifier. Compute the name-character offset before calling.
- **Corpus cap is silent.** `find_duplicates` on a >10K-chunk corpus returns 0
  pairs with no error. Always scope `root=` to a module first when the repo
  is large.
- **`get_repo_map` returns prose.** Programmatic composition needs to parse
  the rendered atlas. A future ripvec version with JSON output would unlock
  the orientation patterns at full power.
- **`chunk.kind` is unreliable for Rust traits/enums.** kind=Interface/Trait
  may report as kind=variable for declarations. Prefer text-grep `^pub trait`
  or `find_similar` from a known-good trait declaration.
- **Dedup-delta needs both pre- and post-dedup counts.** Current API exposes
  only post-dedup; the naming-drift index can't be computed without an
  API change.

Full empirical-revisions catalog: [empirical-revisions](references/empirical-revisions.md)

---

## Heritage and full reference

The patterns descend from a 15-agent (5 orientations × 3 model-tier) brainstorm
synthesized into the canonical pattern language document. The full long-form
reference, including the master-programmer citations (Brooks, Hickey, Naur,
Lampson, Cunningham, Polya, Alexander, Pearl, Parnas, Knuth, et al.) for each
pattern, lives in the ripvec repo at `docs/AGENTIC_PATTERNS.md`. The references
in this skill are condensed extracts; the full doc is the canonical authority.

When the patterns evolve through use, evolve `docs/AGENTIC_PATTERNS.md` first;
the skill references are downstream.
