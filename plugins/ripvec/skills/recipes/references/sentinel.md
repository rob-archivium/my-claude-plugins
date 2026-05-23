# Sentinel recipes

> *Quality is conserved; every reduction of accidental complexity must come from somewhere; prove where.*
> *(Brooks, Cunningham, Hickey, Lampson.)*

Sentinel patterns hunt drift, debt, leaks, dead code, hidden coupling. Every diagnosis must be **falsifiable** — observation, not vibe.

---

## Dead-Code Sweep

**When**: Suspected orphan functions, unreachable helpers, abandoned utilities.

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(query="<peripheral name or suffix>")
     → candidate symbols (NOT central concepts; everything central
       will have refs by construction)
2. For each candidate, mcp__ripvec__lsp_references(file, line, character,
                                                   include_declaration=false)
     → zero refs = dead-code candidate
3. Cross-check: filter out test-only references.
     Code referenced ONLY by tests, never by production, is doubly suspect.
```

**Why it works**: Lampson — *leave it out unless you can't.* An unimplemented or unreferenced symbol earns no keep.

**Watch out**:
- **Target peripheral names.** Querying for central terms like `handler` will return only high-ref-count symbols by construction. The dead code lives in the long tail. Try one-off names like specific internal helper names.
- For Rust, `lsp_references` may miss macro-generated callers. A zero-ref result on a function that's invoked via macro will be a false positive. Cross-check with `search` for the macro invocation pattern.

---

## Orphan-Trait Extinction Sweep

**When**: Auditing for abstractions that exist but have no implementors.

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(query="") filtered by kind="Trait"
     (OR text-grep `^pub trait` if kind tagging is unreliable for the
     language)
2. For each trait T:
     impls = mcp__ripvec__lsp_goto_implementation(file, line, character)
       (post-R3.1 returns real impl blocks)
3. Bucket:
     - 0 impls → ORPHAN candidate
     - 1 impl identical in shape to the trait → VESTIGIAL candidate
     - ≥ 2 impls → LOAD-BEARING (keep)
4. For orphans:
     refs = mcp__ripvec__lsp_references on the trait name
     - If refs == 0 → safe to delete
     - If refs > 0 but impls == 0 → LATENT PANIC SITE
       (the trait is used as a bound with nothing satisfying it at
        runtime → real bug)
```

**Why it works**: Liskov — substitution requires at least *two* substitutable things; one is not polymorphism. The bucketing makes the diagnosis falsifiable.

**Watch out**:
- `chunk.kind` now maps correctly to LSP SymbolKind in 4.0 (Rust traits → kind=11). If results are unexpected, fall back to: `search(query="pub trait <Name>", corpus="code", include_extensions=["rs"])`.
- Post-R3.1, `lsp_goto_implementation` on a non-trait silently falls back to goto_definition. Verify the target IS a trait before treating the result as an impl count.

---

## Naming Drift via Dedup-Delta

**When**: Hunting for Naur theory fracture — same concept under multiple names.

**Chain**:
```
1. Pick high-collision verbs: handle, execute, send, parse, build, process.
2. For each verb:
     mcp__ripvec__lsp_workspace_symbols(query=verb)
     → post-(name, kind)-dedup result set
3. Within each result set, count:
     - Total entries (post-dedup)
     - Distinct file modules they span
     - Names appearing in multiple distinct symbols (name collisions
       after dedup-by-(name,kind))
4. For high-collision names, mcp__ripvec__find_similar on one variant:
     - If similarity > 0.7 across collisions AND outgoing-call sets
       overlap → same abstraction under multiple names (DRIFT)
     - If similarity is low or outgoing-call sets disjoint → legitimate
       polymorphism that shares a verb
```

**Why it works**: The vocabulary fracture is the lexical signature of complected concepts. *Hickey: simple is decomplected; vocabulary fracture is the syntactic evidence.* The diagnosis is falsifiable: high overlap + high similarity = drift; otherwise not.

**Watch out**:
- The current ripvec API exposes only post-dedup counts. The pure "dedup-delta" (raw count − dedup count) cannot be measured without an API change. Until then, use the multi-file-spread heuristic: a name spanning 6+ modules with high outgoing-call overlap is drift evidence.

---

## Duplication-as-Hidden-Module *(composition pattern)*

**When**: Looking for unextracted abstractions.

**Chain**:
```
1. mcp__ripvec__find_duplicates(threshold=0.55, intra_file=false, max_pairs=20)
   SCOPED to a module (the 10K cap).
2. Cluster results by (file_a, file_b) pair. File-pairs with ≥3 duplicate
   pairs are a coupling signal.
3. For each high-cluster pair, mcp__ripvec__lsp_outgoing_calls on both sides.
4. If both A and B call into a third file C → C is the NATURAL HOME of
   the missing abstraction.
5. mcp__ripvec__search(query="<inferred concept name>") → semantic
   confirmation that no existing module already owns this concept.
6. mcp__ripvec__get_repo_map → check PageRank weight of C:
     - High PageRank → already load-bearing → absorb the duplicates into C
     - Low PageRank → the missing module is invisible to the graph
       → introduce a new module to own the concept
```

**Why it works**: File-pair duplicate density is a measurable coupling proxy. The "third file" pattern is falsifiable: if both duplicates call into C, C should absorb them. *Hickey — duplicates are evidence of complecting; the cure is decomplecting via the shared dep.*

---

## Fan-Out God-Function Probe *(composition pattern)*

**When**: Hunting for accidental complexity — functions that know too much.

**Chain**:
```
1. mcp__ripvec__get_repo_map → high-PageRank files (top-10)
2. For each high-PageRank file F:
     mcp__ripvec__lsp_document_symbols(F)
     → enumerate every function/method definition
3. For each definition D:
     calls = mcp__ripvec__lsp_outgoing_calls(F, D.line, D.name_character)
     mods = distinct top-2 path-components of {c.file_path for c in calls}
4. Fan-out > 8 distinct modules = FALSIFIABLE THRESHOLD for god-fn.
5. Cross-check: mcp__ripvec__lsp_hover(D)
     - High fan-out AND no doc-comment → doubly suspect (does too much,
       explains nothing).
```

**Why it works**: Brooks — *accidental complexity accretes at integration points.* Cross-module fan-out separates "central coordinator by design" from "accumulated god function by history."

**Watch out**:
- **Cursor positioning matters here.** `lsp_outgoing_calls` at `line:0` often returns nothing. Compute the function's name-character offset and pass that. Otherwise the probe silently underperforms (returns "0 outgoing for every function" — clearly wrong).

---

## Cohesion Refraction Test *(composition pattern, meta)*

**When**: Hunting internal drift — the same idea written multiple ways within a single module.

> *Cunningham named technical debt; he did not name internal debt — the drift that lives within a single file.*

**Chain**:
```
1. Identify candidate files: PageRank > top-quintile AND LOC > 300.
2. mcp__ripvec__find_duplicates(threshold=0.5, intra_file=true)
   SCOPED to the candidate file's parent module.
3. For each file with ≥3 intra-file duplicate clusters:
     → COHESION HAS REFRACTED. The author held multiple theories
       of the same concept within one housing.
4. The split lines for module extraction are pre-drawn by the
   duplicate clusters themselves.
```

**Why it works**: Naur's theory hole made visible at the file scope. The diagnosis is falsifiable AND the remediation (where to split) is pre-derived from the evidence.

**Example (codex)**: Cohesion Refraction Test on `codex-rs/core/` surfaced 20 intra-file duplicates. The biggest offenders were Markdown prompt templates and test files (content/test drift, not source drift), but one real source candidate emerged: `read_mcp_resource.rs` with 2 identical intra-file clusters — a refactor target derived from one tool call.

---

## PageRank Polarity Probe *(meta-pattern)*

**When**: Identifying structural outliers in BOTH tails.

**Chain**:
```
1. mcp__ripvec__get_repo_map → PageRank distribution
2. Compute μ and σ from the distribution.
3. Identify outliers:
     TOP tail (rank > μ + 2σ):
       mcp__ripvec__lsp_incoming_calls on the file's exported symbols
       → if call-source distribution spans >40% of modules
         → GOD-MODULE candidate (over-fan-in)
     BOTTOM tail (rank < 0.1σ, non-utility):
       mcp__ripvec__lsp_references on the file's symbols
       → if non-test references == 0
         → DEAD-ISLAND candidate
```

**Why it works**: Brooks — *accidental complexity has structural fingerprints.* Outliers in both tails are drift signatures: too-central files have over-fan-in; too-isolated files have zero callers. Both diagnoses come with evidence pre-attached.

---

## Cross-references

- For *what to do with the refactor candidates Sentinel surfaces*, see [refactorer](refactorer.md).
- For False-Twins verification before extraction, see [refactorer](refactorer.md#false-twins-test).
