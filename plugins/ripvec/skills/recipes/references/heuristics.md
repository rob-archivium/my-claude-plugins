# Heuristics — when to reach for which composition

The eight principles that govern *when* to compose, *which* tools, *in what order*. These are not recipes; they are the decision rules for selecting recipes.

---

## H1. The map you don't summon costs nothing.

*(Simon: bounded rationality. Maintain a cheap procedure for re-summoning the parts you need.)*

Don't build a mental map of code you might not touch. The map is a *conversation* with the codebase, not a once-and-done memorization. Every `search` is a question whose answer reshapes the next question. Stop confusing comprehension with completeness.

**Applied:** Before reading code, ask "do I need this map right now?" If no, defer. If yes, summon the minimum.

---

## H2. Triangulate before trusting.

*(Brooks: conceptual integrity emerges from multiple measurement points.)*

A search hit may be famous-but-irrelevant. A PageRank hub may hide three concepts. An LSP definition may capture author intent but not system usage. Compose ≥3 views before forming an opinion.

**Applied:** When you're tempted to act on a single tool's output, instead run two more queries that test the result against a different axis (semantic / structural / precision).

---

## H3. The codebase is its own oracle.

*(Polya: vary the problem.)*

When something is wrong, find where it is right. `find_similar` from a known-good site surfaces the comparison set. Bugs as deviations are cheaper to identify than bugs as novel constructions.

**Applied:** Before guessing why something is wrong, find the version that's working. The diff is the diagnosis.

---

## H4. The instrument's distortions encode the specimen's pathologies.

*(Pirsig: every anomaly is data. Tukey: the unexpected observation is the richest one.)*

When ripvec is confused, the codebase is confused. Duplicates that "shouldn't exist" reveal genuine structural coupling. Ambiguous `lsp_goto_definition` surfaces overload-shadowing the team hasn't acknowledged. `lsp_workspace_symbols` returning the same name in 6 modules is theory fracture, not a ripvec bug.

**Applied:** When ripvec's results surprise you, ask why ripvec *thinks* what it thinks. The answer is usually a real architectural fact.

---

## H5. Names are theory; symbols are evidence; structure is consequence.

*(Naur: programming as theory building.)*

`lsp_workspace_symbols` reveals what programmers *thought* the system was. `lsp_references` reveals what they *built*. `get_repo_map` reveals what *emerged*. Disagreement among the three is the most valuable signal.

**Applied:** Cross-reference all three views before pronouncing on architecture. A function whose name (theory) says "utility" but whose references (evidence) cluster in the auth layer is auth code wearing a costume.

---

## H6. Hide is the dual of expose.

*(Parnas: judge a module by what it hides, not what it exposes.)*

`lsp_outgoing_calls` reveals what a module *chose not to encapsulate* — every external reach is a leaked dependency. Audit hiding through its inverse.

**Applied:** Information-hiding audits become continuous, not archaeological. Set a budget: "no module reaches into more than 3 peer subsystems." Measure compliance via `lsp_outgoing_calls` grouped by target module.

---

## H7. Every diagnosis must be falsifiable.

*(Popper: falsifiability as the criterion of science.)*

"This seems smelly" is not actionable. "If `lsp_goto_implementation(T)` returns zero AND `lsp_references(T)` is non-zero, T is a latent panic site" is. Compose tools to *prove* the diagnosis, not just to seek confirmation.

**Applied:** Every Sentinel finding should be expressible as a conditional. "IF X THEN Y" with X and Y both computable from ripvec calls. If you can't state the condition, you don't have a diagnosis yet.

---

## H8. Scope before similarity at scale.

*(Empirical, post-codex exercise.)*

`find_duplicates` silently hits the 10K-chunk corpus cap on large monorepos. The result: zero pairs returned with no error. The pattern looks like "no duplicates exist" when actually "no duplicates were computed."

Same logic applies to `find_similar` on very large indexed corpora — its top_k results may be drowned out by irrelevant matches if the corpus is too broad.

**Applied:** Before any similarity-based tool call on an unknown-size repo:
1. Check the repo size (file count, language mix).
2. If >5K source files: scope `root=` to a single crate or module.
3. Iterate from small scopes outward, not whole-repo first.

This heuristic was learned the hard way during the codex exercise (4633 files; `find_duplicates` returned 0 pairs with no error; scoping to `codex-rs/core` returned 10 pairs including a clear extract-method candidate).

---

## When in doubt: which heuristic applies?

| Symptom | Heuristic to consult |
|---|---|
| "I want to read more of the codebase" | H1 — defer; summon minimum |
| "I'm going to act on this one result" | H2 — triangulate first |
| "I don't know why this is wrong" | H3 — find where it's right |
| "Ripvec returned something weird" | H4 — that weirdness is signal |
| "The names tell one story, the code another" | H5 — cross-reference all three views |
| "This module seems to know about everything" | H6 — measure outgoing-call diversity |
| "I think there's a smell here" | H7 — turn it into a falsifiable IF/THEN |
| "find_duplicates returned 0 on a huge repo" | H8 — you hit the cap; scope down |

---

## Cross-references

- See each recipe's "Watch out" notes for tactical applications.
- See [empirical-revisions](empirical-revisions.md) for the codex-derived adjustments.
