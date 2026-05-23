# Refactorer recipes

> *Make the change easy first; then make the easy change. (Cunningham.)*
> Refactor sizing becomes a query, not a vibe.

Mechanical refactors are cheap; *judgment* is the bottleneck. Ripvec composes evidence for those judgments.

---

## Blast-Radius Manifest Before Rename

**When**: Any non-trivial rename — public function, struct field, type — where blast radius is unknown.

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(query="<name>")
     → dedup-clean candidate list (post-R3.3, (name, kind) dedup)
     → catches overloads early (multiple results = separate manifests required)
2. mcp__ripvec__lsp_prepare_call_hierarchy(file, line, character)
     → overload-aware roots (post-R2.1)
3. mcp__ripvec__lsp_incoming_calls(item) for each root
     → concrete call-site manifest (file, line, from-symbol)
4. mcp__ripvec__lsp_hover at each unique calling symbol
     → group call sites by INVARIANT (same return-type expectation,
       same error-handling pattern)
5. Rename in batches per invariant group; compile-check between batches.
```

**Why it works**: Beck's small steps. Each invariant group becomes its own coherent, independently-compiling commit. The grouping is *derived from evidence*, not guessed.

**Watch out**:
- `lsp_workspace_symbols` returns post-dedup results; pre-dedup counts (where naming drift lives) aren't visible. Different cluster shapes = different rename plans.
- For Rust enums and struct fields, the chunk.kind may be tagged as "variable" — don't rely on kind alone to filter.

**Example (codex)**: `lsp_references` on `commands_for_exec_policy` returned 38 references across 21 files. Grouping by file gives the batch plan directly — ~21 commits if each file is its own invariant group, fewer if invariants cluster.

---

## Impl Survey Before Trait Edit (Contract Survey)

**When**: Editing a trait's method signature, adding a required method, or changing a bound.

**Chain**:
```
1. mcp__ripvec__lsp_goto_implementation(file, line, character)
     → real `impl Trait for T` blocks (post-R3.1; was returning trait
       declarations before)
2. mcp__ripvec__lsp_document_symbols on each impl file
     → surrounding context: private helpers, test modules, informal contracts
3. mcp__ripvec__find_similar from one impl body, top_k=8
     → are most impls near-identical? → candidate for `default fn`
4. mcp__ripvec__lsp_hover on the trait method
     → if doc-comment contradicts the edit's intent, UPDATE THE DOC FIRST
       as a separate commit (Cunningham: make the change easy first)
```

**Why it works**: Liskov substitution applied empirically — the trait's *real* contract is the union of what its implementors do. The edit is contract-extending (safe), contract-narrowing (requires impl updates), or contract-replacing (requires migration).

**Watch out**:
- `lsp_goto_implementation` on a NON-trait (struct, enum) silently falls back to goto_definition. Confirm the target is a trait first via text-grep `pub trait <Name>` or by checking the chunk content.

---

## Duplicate-Anchored Extraction with Shared-Dep Intersection

**When**: Suspicion that a module has copy-evolved logic; DRY pressure without knowing what the common abstraction is.

**Chain**:
```
1. mcp__ripvec__find_duplicates(threshold=0.55, intra_file=false, max_pairs=20)
     SCOPED to a module-sized root (the 10K-chunk cap applies)
2. Cluster results by (file_a, file_b) pair.
3. For each high-cohesion pair, mcp__ripvec__lsp_outgoing_calls on both
   duplicate sites.
4. INTERSECT the outgoing-call sets:
     intersection = dependencies the extracted function must accept
     union − intersection = parameters that differ between the two
     sites → the extraction's parameter set
5. mcp__ripvec__lsp_hover on each intersected dependency
     → verify none carry hidden mutable state (would make extraction
       unsafe without a signature change)
```

**Why it works**: Pearl's hidden-common-cause pattern. Duplicates are *evidence*, not the problem; the cause is the shared concept. The outgoing-call intersection is a mechanical derivation of the extracted function's natural API — no guessing.

**Watch out**:
- **Scope the root**. find_duplicates silently caps at 10K chunks. On large monorepos, a whole-repo call returns 0 pairs with no error.
- The intersection may reveal the extraction belongs in a SHARED CRATE, not in either caller crate. Refactor scope expands accordingly.

**Example (ripvec-on-codex)**: `find_duplicates(threshold=0.55, intra_file=false)` scoped to `codex-rs/core` surfaced **three identical 30-line code regions** across `read_mcp_resource.rs`, `list_mcp_resources.rs`, `list_mcp_resource_templates.rs` — classic Extract Method target, surfaced by one tool call.

---

## False-Twins Test *(meta-pattern, applied to extraction)*

**When**: Duplicates found — but should they actually be merged?

> *Hickey: duplicates are evidence of complecting; the fix is decomplecting.*
> *But text-similar code is not the same as semantically equivalent code.*

**Chain**:
```
1. For each candidate duplicate pair from find_duplicates:
     mcp__ripvec__lsp_outgoing_calls on both sides
2. Diff the qualified-path sets of outgoing calls.
3. Verdict:
     - HIGH OVERLAP in outgoing-call sets → shared theory
       → Extract Method is correct
     - DISJOINT outgoing-call sets → FALSE TWINS
       → syntactically congruent code expressing different
         intentions → DO NOT EXTRACT
       → instead, RENAME to expose the divergence
```

**Why it works**: Two functions with identical control flow may encode genuinely different theories of the program. Merging them produces a worse codebase that hides its own confusion behind shared structure — Hickey's complecting in its purest form. The outgoing-call intersection test catches this.

---

## Definition-Jump Verification After Large Rename

**When**: Post-rename or post-move verification. Want a falsifiable invariant.

**Chain**:
```
1. BEFORE rename: capture call-site manifest via Blast-Radius Manifest.
   Note total reference count R₀.
2. AFTER rename:
     a. mcp__ripvec__lsp_workspace_symbols(new_name)
        → confirms unique under the new name
     b. Sample one call site per crate from the pre-rename manifest
     c. mcp__ripvec__lsp_goto_definition(sampled_file, new_name)
        → exact-name preference (post-R3.2) returns the def directly
        → verify each returned location is the NEW definition site
     d. mcp__ripvec__lsp_references(new_definition_file, new_name)
        → count must equal R₀. Discrepancy = orphaned reference.
```

**Why it works**: The reference-count invariant is a regression gate — purely numeric, easy to automate. Lampson: *measure, don't guess.*

**Watch out**:
- Pre-R3.2, exact-name preference was dead code (`chunk.name` was always empty). Post-R3.2, it's live — this recipe relies on that fix.

---

## Overload-Safe Method Consolidation

**When**: Collapsing N near-identical methods (`load_v1`, `load_v2`, `load_latest`) into one with a parameter.

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(prefix) → all N variants (post-dedup).
2. mcp__ripvec__lsp_prepare_call_hierarchy on each variant (overload-aware).
3. mcp__ripvec__lsp_incoming_calls per variant:
     - Zero callers → dead variant → REMOVE FIRST (no-op pre-step)
     - Live → keep
4. For live variants, lsp_outgoing_calls each → diff the outgoing sets.
   The diff = what the new parameter must encode.
5. If diff is too large → consolidation is premature. Refactor stops here.
6. Otherwise: introduce consolidated function; re-run lsp_incoming_calls
   on each old variant; count must reach 0 before deleting.
```

**Why it works**: Dead-code removal (step 3) is non-breaking, shrinks the risk surface. The outgoing-call diff (step 4) is a quantitative complexity signal — *discovering the consolidation is premature before writing any code is the pattern's chief value*.

---

## Cross-references

- For *triggering refactor recipes*, see [cartographer](cartographer.md) (to find candidates).
- For the False-Twins outgoing-call algorithm, see [primitives](primitives.md#p4-duplicates-as-taxonomy).
- For Cunningham/Beck/Fowler heritage, see [heuristics](heuristics.md).
