# Onboarder recipes

> *Teach the program's theory, not its surface. (Naur.)*
> *Definitions are compressions of examples; concept formation runs example-first. (Bruner.)*

The teacher is no longer the bottleneck — LLMs narrate fluently. The bottleneck is *which narration induces the right mental model*. The Onboarder recipes shape narration through evidence selection.

---

## Top-N Architectural Tour

**When**: "Show me the structure of this codebase."

**Chain**:
```
1. mcp__ripvec__get_repo_map(max_tokens=4000)
     → PageRank-ranked top files
2. mcp__ripvec__lsp_document_symbols on the top 5
     → outline per file, "what each owns"
3. Narrate top-down:
     "This codebase has 5 load-bearing files. File-1 owns X. File-2
      delegates Y to file-3 via trait Z. Here's how they compose."
```

**Why it works**: Brooks's surgical team — one pilot. PageRank gives the learner's mental anchor: the most central code. Subsequent learning expands outward from that anchor.

**Watch out**:
- The rendered atlas can put protocol-schema or test-snapshot files at the top — these may not be the most *pedagogically* central. Skip past schemas/snapshots to find the first source-code file in the ranking.

---

## Concept-by-Example Triangulation

**When**: "How does this codebase handle [error propagation / retry / caching]?"

**Chain**:
```
1. mcp__ripvec__search(query="<concept>", top_k=5, corpus="code")
     → 3 semantically distinct hits
2. For each hit, mcp__ripvec__find_similar(file, line, top_k=3)
     → siblings of that hit
3. mcp__ripvec__lsp_hover on the key symbol in each example
     → contract per variant
4. Present "the same idea three ways":
     "Variant A does it via mechanism X.
      Variant B does it via mechanism Y.
      Variant C does it via mechanism Z.
      The differences expose the principle's range."
```

**Why it works**: Polya — *vary the problem*. Bruner — enactive → iconic → symbolic; concept formation runs example-first. Three derivations reveal what one hides.

**Example (codex)**: For "sandbox command exec" → three top hits in `core/exec.rs:908`, `unified_exec/mod.rs`, `unified_exec/process_manager.rs:1021`. The third's `find_similar` shows sim=0.92 with `tools/handlers/shell.rs:160` — surfacing that `process_manager` and `shell.rs` are tightly coupled. Real architectural fact emerges from teaching.

---

## Topic-Sensitive Atlas

**When**: "Orient me — but anchored on this topic."

**Chain**:
```
1. mcp__ripvec__search(query="<topic>", top_k=3)
     → identify the highest-signal file for this topic
2. mcp__ripvec__get_repo_map(max_tokens=2000, focus_file=anchor)
     → PageRank rebiased toward the topic's neighborhood
3. mcp__ripvec__lsp_document_symbols on the top-3 newly-weighted files
     → topic-specific anatomy
4. Narrate as:
     "The topic lives in `anchor`. Its structural siblings are X, Y, Z.
      X handles A; Y owns B; Z is the test surface."
```

**Why it works**: Polya — *restrict the problem space*. The `focus_file` parameter is Polya's "auxiliary problem" applied to graph centrality. The learner experiences the codebase as a *parameterized* object whose shape responds to what is being asked.

**Watch out**:
- The focus-file's rank can jump dramatically (codex example: 0.066 → 0.627), giving the impression that almost nothing else matters for the topic. Adjust max_tokens upward (3000-4000) to see the full neighborhood, not just the anchor.

---

## Recursive Narration Descent *(composition pattern)*

**When**: "Explain how X works end-to-end."

**Chain**:
```
1. mcp__ripvec__search(query="<X>") → identify the canonical entry function E
2. mcp__ripvec__lsp_hover(E) → narrate intent
3. mcp__ripvec__lsp_outgoing_calls(E) → enumerate direct callees
4. For each callee C:
     - mcp__ripvec__lsp_hover(C) → narrate sub-contract
     - If C is in-repo (not stdlib/third-party): recurse into
       lsp_outgoing_calls(C)
5. Stop at standard-library or third-party boundaries (quiescent)
6. Assemble BOTTOM-UP: primitives first, composers second, entry last.
```

**Why it works**: Feynman — *if you can't explain it, you don't understand it.* The recursion follows the conceptual decomposition. The narration mirrors the invariant-preservation chain. There is no magic because nothing was skipped.

**Watch out**:
- Recursion termination matters. Stop at the **first** non-in-repo callee per branch; don't try to descend into stdlib internals.
- For functions with very high fan-out (god functions), the recursion explodes. Consider breadth-limiting to 5 callees per level.

---

## Invariant Layer Cake *(composition pattern)*

**When**: "I need to understand this module deeply enough to modify it safely."

**Chain (four layers):**
```
LAYER 1 — Data ("what shapes exist here"):
  mcp__ripvec__lsp_document_symbols(file)
  → outline all types and functions

LAYER 2 — Flow ("what enters, leaves, transforms"):
  mcp__ripvec__lsp_outgoing_calls + lsp_incoming_calls on public API
  → map the flow boundary

LAYER 3 — Invariants ("what must always be true"):
  mcp__ripvec__search(query="assert OR debug_assert OR invariant OR must",
                      include_extensions=["rs"])
  → find invariant enforcement sites
  mcp__ripvec__lsp_hover at each → enrich

LAYER 4 — Corner cases ("where the invariants have been tested adversarially"):
  mcp__ripvec__find_similar from the first invariant-enforcement site
  → other invariant patterns across the codebase
```

**Why it works**: Dijkstra — *a program is only understood when its invariants are understood.* The layers are Dijkstra's precondition reasoning made navigable. The learner who reads in order cannot make certain classes of modification mistake — they know what the code protects before they touch it.

---

## The Codebase Speaks Its Own Pattern Language First *(meta-pattern)*

**When**: Onboarding someone — agent or human — to the codebase's dialect.

> *Alexander: a pattern language exists before anyone names it; the recurring forms are the vocabulary.*

**Chain**:
```
1. mcp__ripvec__find_duplicates(threshold=0.55, intra_file=false)
   BEFORE any code tour. Scope to a module if the repo is large.
2. Cluster results by similarity score. Each cluster is a PATTERN in
   the Alexandrian sense.
3. Name each cluster ("the borrow-then-release dance", "the staged-init
   guard", "the error-passthrough idiom"). Only after the learner can
   produce the NAME on demand:
4. mcp__ripvec__lsp_hover on a canonical instance per pattern.
   The instance illustrates the name.
```

**Why it works**: Vocabulary-first pedagogy compresses along the codebase's own axes, not Wikipedia's. The learner reads new code by *recognizing* — they see a cluster member and predict the rest of the file.

**Watch out**:
- Test files and prompt templates often dominate find_duplicates output. Filter to source files when the pedagogical goal is the production codebase's dialect, not its test discipline.

---

## Concept-by-Example Before Concept-by-Definition *(meta-pattern)*

> *Bruner: enactive → iconic → symbolic. Concept formation runs example-first.*

When introducing a new abstraction:
- **Do not** start with `lsp_hover` on the trait/interface.
- Start with `mcp__ripvec__find_similar` anchored on one concrete implementation.
- Show 3-4 sibling implementations. Ask the learner: *what do these have in common?*
- Let them articulate the contract in their own words.
- *Then* show `lsp_hover` on the abstract definition — the formal statement of what they just induced.

The definition lands as confirmation, not imposition. The learner owns it.

---

## Cross-references

- For *what to navigate AFTER the tour*, see [refactorer](refactorer.md), [detective](detective.md).
- For pattern-language theory, see [primitives](primitives.md#p4-duplicates-as-taxonomy).
