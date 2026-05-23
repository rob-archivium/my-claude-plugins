# Compositional primitives

The eight reusable algorithmic patterns that recur across orientations. Memorize their shapes; the orientation recipes are specializations.

---

## P1. Triangulation

> *No single view tells the truth; compose ≥3.*

Canonical form: **semantic** (`search`, `find_similar`, `find_duplicates`) ∩ **structural** (`get_repo_map`, `focus_file`) ∩ **precision** (every `lsp_*` tool).

A function whose `find_similar` neighbors are in `cache/` but whose `lsp_incoming_calls` are in `billing/` is either a sophisticated abstraction or a misplaced one — and the call graph tells you which. The semantic axis gives meaning; the structural axis gives importance; the precision axis gives ground truth.

**Pseudocode:**
```python
hits = search(query)                                    # meaning
ranks = get_repo_map(focus_file=hits[0].lsp_location.file_path)  # structure
for h in hits[:3]:
    hover = lsp_hover(location=h.lsp_location)          # precision (ground)
    refs = lsp_references(location=h.lsp_location)      # precision (usage)
    # Disagreement among the three is signal.
```

*Polya: look at the unknown; find a familiar problem with the same unknown.* The triangle is your similarity oracle.

---

## P2. Fixed-Point Expansion

> *Expand a symbol's blast radius until the working set stabilizes.*

Used by Cartographer (full blast radius), Detective (recursive caller climb), Onboarder (recursive narration descent), Refactorer (transitive dependent discovery).

**Pseudocode:**
```python
S = set(lsp_references(symbol))
W = symbols in files of S that wrap/re-export the original
while changed:
    next_S = S | union(lsp_references(w) for w in W)
    W = wrappers in next_S \ S
    if next_S == S: break  # fixed point
    S = next_S
return S
```

The fixed-point guarantee: you stop when you've found everything, not when you're tired. This catches transitive dependents (wrapper chains) that a single `lsp_references` call misses.

**Variants:**
- **Recursive Caller Climb**: same shape, but using `lsp_incoming_calls` and pruning callers whose preconditions exclude the symptom.
- **Recursive Narration Descent**: same shape, but using `lsp_outgoing_calls` until reaching primitives.

---

## P3. Sibling Diff

> *The codebase is its own oracle for "how X should look."*

**Pseudocode:**
```python
candidates = find_similar(location=suspect_lsp_location, top_k=8)
# OR: candidates = find_similar(symbol_name=suspect_symbol_name, top_k=8)
contexts = {c: lsp_hover(location=c.lsp_location) for c in candidates}
divergence = line_context(suspect) ⊖ line_context(c) for c in candidates
# The divergence pattern IS the bug shape OR the idiom variation.
```

Used heavily by Detective ("if 4 of 5 siblings work and 1 doesn't, the difference IS the bug") but also Cartographer (idiom variants), Refactorer (canonical-form discovery), Onboarder (concept-by-example triangulation).

*Polya: vary the problem. Three derivations reveal what one hides.*

**Watch out:** `find_similar` requires the cursor to be **inside an indexed chunk**. At `start_line, character=0` of a function header line, the cursor may be on whitespace or a keyword, not inside any chunk. Place the cursor a few lines into the function body. *(Empirical, post-codex exercise.)*

---

## P4. Duplicates as Taxonomy

> *find_duplicates is not a DRY hit list; it is the codebase's de-facto pattern language by frequency.*

**Pseudocode:**
```python
clusters = find_duplicates(threshold=0.5, intra_file=false, root=SCOPED_ROOT)
# Group by (file_a, file_b) pair
for cluster in clusters:
    canonical = cluster[0]
    variants = cluster[1:]
    # Name the cluster by intent (induced from canonical's content)
    drift = members semantically near but textually divergent
```

Used by:
- **Onboarder**: teach the codebase's vocabulary by NAMING each cluster.
- **Sentinel**: find unextracted abstractions (cluster + shared outgoing-call deps).
- **Cartographer**: absorb the codebase's culture before any code reading.
- **Refactorer**: with the False-Twins Test, distinguish shared-theory clusters (extract) from accidental-congruence clusters (rename).

**The False-Twins Test:**
```python
for (a, b) in cluster_pair:
    # Prepare call hierarchy first to get a typed item, then outgoing.
    hier_a = lsp_prepare_call_hierarchy(location=a.lsp_location)
    hier_b = lsp_prepare_call_hierarchy(location=b.lsp_location)
    out_a = lsp_outgoing_calls(item=hier_a.results[0])
    out_b = lsp_outgoing_calls(item=hier_b.results[0])
    if out_a ∩ out_b is substantial: # shared theory
        extract_method_correct(a, b)
    else: # false twins — different intentions, same shape
        rename_to_expose_divergence(a, b)
```

**Watch out:** `find_duplicates` silently caps at 10K chunks (R6.4). Always scope `root=` to a module-sized subtree on large codebases. *(See empirical-revisions.)*

---

## P5. Names as Folk Taxonomy

> *The corpus of names is a folk taxonomy programmers built without realizing it.*

**Pseudocode:**
```python
results = lsp_workspace_symbols(query=verb)  # post-(name, kind) dedup
modules = group_by(top-level path component of result.file)
# Read the SHAPE:
#   - dominant module = canonical namespace for this verb
#   - cross-module appearance = bridges or fracture
canonical_members = top-N by file count
for cm in canonical_members:
    unnamed_siblings = find_similar(cm.file, cm.line)
    # Code in the category without wearing its uniform.
```

The drift-index measurement (theoretically: raw count − dedup count, normalized) would quantify naming fracture. The current API exposes only post-dedup counts, so the formal drift-index requires an API extension. As a workaround, use the multi-module spread of a single name as a fracture signal: a name spanning 6+ modules with high outgoing-call overlap is drift.

*Alexander: recurring forms are remembered solutions. Wirth: Algorithms + Data Structures = Programs. Names are how data structures advertise their algorithms.*

---

## P6. Causal Intervention via Tooling

> *log_level as Pearl's do-operator; previous_filter makes interventions reversible.*

**Pseudocode:**
```python
prev = log_level(level=f"ripvec_{suspect}=trace,others=warn").previous_filter
# Run the repro
captured_1 = debug_log(lines=200)
# Flip the intervention
log_level(level=f"ripvec_{other_suspect}=trace,ripvec_{suspect}=warn")
captured_2 = debug_log(lines=200)
# Diff the captures
log_level(level=prev)  # restore — experiment, not vandalism
```

Reading logs is observation: `P(symptom | code)`. Toggling filters is intervention: `P(symptom | do(component isolated))`. Same symptom under two interventions tells you which layer owns the bug.

**Constraint (post-R6.2):** `log_level` accepts only `ripvec`, `ripvec_mcp`, `ripvec_core` prefixes. This is by design — privacy/security contract.

---

## P7. Trait Constellation Survey

> *Post-R3.1, lsp_goto_implementation returns real impl blocks. Contract audits, orphan detection, default-method extraction all become tractable.*

**Pseudocode:**
```python
for T in lsp_workspace_symbols(query="", kind_filter="Trait"):
    impls = lsp_goto_implementation(T.file, T.line, T.name_char)
    if len(impls) == 0:
        # ORPHAN: verify with lsp_references
        if lsp_references(T) is empty:
            ORPHAN_CANDIDATE.add(T)
        else:
            LATENT_PANIC.add(T)  # used as bound but unsatisfiable at runtime
    elif len(impls) == 1:
        # VESTIGIAL: check if impl is structurally identical to trait
        VESTIGIAL_CANDIDATE.add(T)
    else:
        bodies = [lsp_document_symbols(impl.file) for impl in impls]
        if find_similar(bodies) shows convergence:
            DEFAULT_FN_EXTRACTION_CANDIDATE.add(T)
        else:
            LOAD_BEARING.add(T)
```

Used by Cartographer (constellation mapping), Refactorer (contract survey before edit), Sentinel (orphan extinction sweep).

**Watch out (4.0):** `chunk.kind` now maps correctly to LSP SymbolKind for Rust traits (kind=11).
If results are unexpected, fall back to: `search(query="pub trait <Name>", corpus="code", include_extensions=["rs"])`.

---

## P8. PageRank Polarity

> *Outliers in BOTH tails are drift signals.*

**Pseudocode:**
```python
# 4.0: get_repo_map returns JSON with files[].rank — no parsing needed
repo_map = get_repo_map(max_files=50)
ranks = [(f["lsp_location"]["file_path"], f["rank"]) for f in repo_map["files"]]
mu, sigma = mean_and_std(ranks)
top_outliers = [f for f in ranks if f.rank > mu + 2*sigma]
bottom_outliers = [f for f in ranks if f.rank < 0.1*sigma and not is_utility(f)]

for f in top_outliers:
    incoming_sources = unique modules of lsp_incoming_calls(f.exports)
    if breadth > 40% of all modules:
        GOD_MODULE_CANDIDATE.add(f)  # over-fan-in: too many things depend
                                       # on it because they have nowhere else
                                       # to go

for f in bottom_outliers:
    refs = lsp_references(f.exports)
    if non_test_count(refs) == 0:
        DEAD_ISLAND.add(f)  # code that exists but participates in nothing
```

Both diagnoses come with their evidence pre-attached. Falsifiable: PageRank >2σ above mean AND incoming spans >40% of modules → god-module candidate. PageRank <0.1σ AND non-test references zero → dead file.

---

## Cross-references

- See each orientation's specializations: [cartographer](cartographer.md), [detective](detective.md), [refactorer](refactorer.md), [onboarder](onboarder.md), [sentinel](sentinel.md).
- See [empirical-revisions](empirical-revisions.md) for cursor-positioning, corpus-cap, and kind-tagging caveats that affect every primitive.
