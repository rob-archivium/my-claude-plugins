---
name: teach
description: Onboarder T13+T14 — architectural tour plus concept-by-example triangulation. Curates evidence that induces the right mental model.
arguments:
  - name: concept
    description: Concept, module path, or topic to teach (e.g. "the auth module", "how retry works", "EmbedBackend")
    required: true
---

Load the `ripvec:onboarder` skill, then execute the T13 Top-N
Architectural Tour followed by T14 Concept-by-Example Triangulation.

```
Skill("ripvec:onboarder")
```

## BPMN flow

```
flowchart LR
    A["/teach CONCEPT"] --> B[T13 Architectural Tour\nget_repo_map token_budget=2000]
    B --> C[identify top-3 files\nrelevant to CONCEPT]
    C --> D[T14 Concept-by-Example\nsearch CONCEPT corpus=code]
    D --> E[find_similar best_hit top_k=6]
    E --> F{P4: duplicates as idioms?}
    F -->|yes| G[find_duplicates root=module\nnear-dup clusters = idiom footprint]
    F -->|no| H[lsp_document_symbols\nbest_hit file]
    G --> H
    H --> I[T15 Recursive Narration optional\nlsp_outgoing_calls on entry symbol]
    I --> J[Narrate: examples before definitions\nBruner 1966]
```

## Execution

**Step 1: T13 Top-N Architectural Tour.**

```
get_repo_map(token_budget=2000)
```

Identify the top-3 to top-5 files most relevant to `<concept>`.
If `<concept>` names a specific module, use:

```
get_repo_map(focus_file="<module file>", token_budget=1500)
```

**Step 2: T14 Concept-by-Example Triangulation.**

```
search(query="<concept>", corpus="code")
```

Take the best-ranked hit as the canonical instance. Show the example
BEFORE the definition (Bruner 1966 — enactive before symbolic).

```
find_similar(symbol_name="<concept>", top_k=6)
```

The similar neighbors are the related instances. Together they form
the concept's empirical footprint in the codebase.

**Step 3: Idiom crystallization (P4, optional but recommended).**

```
find_duplicates(root="<relevant module>", threshold=0.75)
```

The near-duplicate clusters are the codebase's de-facto pattern language
(Wittgenstein §43 — meaning is use). Show these before explaining the
concept's design intent.

**Step 4: Outline the canonical instance.**

```
lsp_document_symbols(file_path="<best_hit file>")
```

Show every function, struct, field in the canonical file — gives the
student the shape before the prose.

**Step 5: T15 Recursive Narration Descent (optional, for entry points).**

If the concept has a clear entry symbol (e.g., `main`, `handle_request`,
a trait's primary method):

```
lsp_prepare_call_hierarchy(lsp_location=<entry symbol location>)
lsp_outgoing_calls(call_item)
```

Narrate the execution graph top-down. Stop when the callees are
leaf-level utilities (bottom of the conceptual layer cake).

## M7 prose-grade hover caveat

If `lsp_hover` returns rich doc comments for the concept's symbols, read
those first before doing T14. When hover is prose-grade (well-documented
codebase), F3 Theory-First Prose Probe fires instead of T14:

```
search(query="<concept>", corpus="docs", rerank="always")
```

Use the doc/prose result as the conceptual frame; then T14 as confirmation.

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search,mcp__ripvec__find_similar,mcp__ripvec__find_duplicates,mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_outgoing_calls,mcp__ripvec__lsp_hover")`
Codex: bare names directly.
