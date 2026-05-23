# Detective recipes

> *The codebase is its own oracle; the bug is its theory hole.*
> *(Naur: programming as theory building. Pearl: every observation should shrink the hypothesis space.)*

Detective patterns chase symptoms to root causes. The bug is usually evidence that the programmer's *theory* of the program and the program itself have diverged.

---

## Sibling Diff

**When**: "This looks reasonable, but it's wrong."

**Chain**:
```
1. mcp__ripvec__find_similar(location=suspect_lsp_location)
     OR: mcp__ripvec__find_similar(symbol_name=suspect_symbol_name)
     → 5-8 doppelgangers from elsewhere in the codebase
2. For each sibling, mcp__ripvec__lsp_hover
     → contracts side by side
3. Diff the broken site's line-context against the working siblings.
     The divergence pattern IS the bug shape.
4. If multiple siblings are broken identically:
     mcp__ripvec__lsp_goto_definition on the common dependency
     → the shared upstream is the source of the bug
```

**Why it works**: Most bugs are not novel; they are *deviations* from a pattern the codebase already encodes correctly elsewhere. Polya: *"Vary the problem."* If 4 of 5 sibling locations work and 1 doesn't, the difference IS the bug.

**Watch out**:
- `find_similar(location=...)`: pass the `lsp_location` from a `search` result directly.
  `lsp_location.start_line` now points at the symbol identifier line (not the doc-comment
  chunk start), so cursor positioning is more reliable in 4.0.
- `find_similar(symbol_name=...)` resolves via the workspace symbol index — useful when you
  know the symbol name but don't have a search result to chain from.
- 0 results from `find_similar` usually means "no chunk at this cursor", not "no similar code." Re-target.

---

## Recursive Caller Climb

**When**: The function works in isolation (unit tests pass) but fails in integration — the bug is being *delivered*, not produced.

**Chain**:
```
1. mcp__ripvec__lsp_prepare_call_hierarchy(file, line, character)
     → overload-aware items (post-R2.1; filters non-callables)
2. mcp__ripvec__lsp_incoming_calls(item) on each
     → N immediate callers
3. For each caller C:
     - mcp__ripvec__lsp_hover(C) → read its precondition contract
     - Ask: "Could the precondition break here?"
       - If YES → recurse into lsp_incoming_calls(C) (climb)
       - If NO → rule C out (Bayesian elimination)
4. Termination:
     - Caller-bound trigger context found → repro is mechanical
     - All callers exhausted as safe → bug is INSIDE F, not injected
```

**Why it works**: Pearl's do-calculus on a DAG — each `incoming_calls` is an intervention point. Ruling callers out is as valuable as ruling them in. Simon's bounded rationality stops being a limitation when the posterior shrinks geometrically.

**Watch out**:
- `lsp_prepare_call_hierarchy` is overload-aware AND filters non-callables; but it can still return container types (structs, modules) when the cursor sits on them. Confirm the prepared item is a function (kind=12 in LSP), not a container (kind=5 Class / 11 Interface).
- Recursion can blow up on functions with many callers. Heuristic: cap depth at 3; if the trigger isn't bound, the bug is likely inside F.

---

## Broken Contract Hunt

**When**: Something violates an invariant and you can't tell where.

**Chain**:
```
1. mcp__ripvec__lsp_workspace_symbols(query="<invariant-related name or type>")
     → producer/consumer sites
2. mcp__ripvec__lsp_references on the type
     → partition write sites from read sites
3. For each write site, mcp__ripvec__lsp_hover
     → what does the producer CLAIM to guarantee?
4. mcp__ripvec__lsp_goto_implementation on the trait
     → find the impl that silently drops the invariant
5. mcp__ripvec__find_similar on the correct impl
     → make the divergence visible by diff
```

**Why it works**: Hoare's *"obviously no deficiencies"* — an incorrect contract is the proof the invariant was never actually enforced at that site. The composition produces a forensic chain rather than a single guess.

**Watch out**:
- `lsp_workspace_symbols` includes test files and generated SDK files on polyglot repos. The chain may flag a noise entry as a "producer." Filter by extension or file-path glob.

---

## Semantic Hypothesis Triage *(composition pattern)*

**When**: Bug report with symptom but no stack trace, no reproduction, just "X doesn't work."

**Chain**:
```
1. mcp__ripvec__get_repo_map → prior probability by structural centrality
2. mcp__ripvec__search(query="<symptom in behavioral terms>", top_k=10)
     → ranked candidates by semantic relevance
3. mcp__ripvec__lsp_document_symbols on the top-3 ranked files
     → structure without speculative reading
4. mcp__ripvec__lsp_references on the most-mentioned type
     → execution surface
5. mcp__ripvec__log_level("<suspected-component>=trace") + repro
   + mcp__ripvec__debug_log
     → convert hypothesis to observed fact
```

**Why it works**: You arrive at the first `Read` call with a ranked, evidence-weighted suspect list rather than a guess. Lampson's hints: *make the common case fast, the rare case correct.* Hypothesis triage makes the investigation efficient before the fix.

**Example (codex)**: Hypothesis "wrong path returned" → search ranks 5 path-handling functions: `normalize_path_for_sandbox`, `resolve_manifest_path`, `display_path_for`, `plugin_version_base`, `normalize_remote_plugin_subdir`. All in `codex-rs/sandboxing/` and `codex-rs/core-plugins/`. If the bug exists, these are the suspects — no file reads needed for the ranking.

---

## Do-Calculus by Log Level *(meta-pattern)*

**When**: Need to causally isolate which subsystem owns a bug.

> *Pearl, Causality. The do-operator distinguishes seeing (observation) from doing (intervention).*

**Chain**:
```
1. prev = mcp__ripvec__log_level(level="ripvec_<suspect>=trace,others=warn")
     → response includes previous_filter (post-R8.2); intervention is reversible
2. Run the repro
3. capture = mcp__ripvec__debug_log(lines=200)
4. Flip: mcp__ripvec__log_level("ripvec_<other-suspect>=trace,ripvec_<suspect>=warn")
5. Re-run repro, capture again
6. Diff the two captures. The interval where logs disappear (or
   appear) under one filter but not the other is the locus.
7. mcp__ripvec__log_level(level=prev)  # restore
```

**Why it works**: Reading logs is observation; toggling filters is intervention. The `previous_filter` return makes interventions reversible — experiments, not vandalism. Same symptom under two interventions tells you which layer owns the bug.

**Watch out**:
- The `log_level` allowlist (post-R6.2) accepts only `ripvec`, `ripvec_mcp`, `ripvec_core` prefixes. You cannot use this to surface tokio/hyper internals; that's the privacy/security contract.

---

## Ripvec as Indirect Microscope *(meta-pattern)*

**When**: Ripvec itself behaves anomalously on your codebase.

When `find_duplicates` reports clusters that "shouldn't exist," ask why ripvec *thinks* they're duplicates. The answer often reveals genuine structural coupling invisible to humans — two files implementing the same protocol with subtly different invariants.

When `lsp_goto_definition` resolves ambiguously, the codebase has overload-shadowing the team hasn't yet acknowledged.

When `lsp_workspace_symbols` returns a name in 6 modules, ask whether those 6 are really the same concept (Naur theory fracture) or distinct uses sharing a verb (legitimate polymorphism).

> *Pirsig: diagnostic logic treats every anomaly as data. Tukey: the unexpected observation is the richest one.*

The instrument's distortions encode the specimen's pathologies.

---

## Cross-references

- For *what to do once you've located the bug*, see [refactorer](refactorer.md).
- For the recursive caller-climb's full Bayesian framing, see [primitives](primitives.md#p2-fixed-point-expansion).
