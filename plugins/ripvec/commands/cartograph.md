---
name: cartograph
description: Cartographer hub — build a structural and conceptual map of the codebase. Routes to T1/T2/T5/C1 recipes.
arguments:
  - name: focus_file
    description: File to focus the topic-sensitive PageRank on (optional)
    required: false
  - name: concept
    description: Concept to find and tour around (optional — e.g. "auth", "retry", "cache")
    required: false
---

Load the `ripvec:cartographer` skill, then execute the Cartographer
orientation sequence based on the provided arguments.

```
Skill("ripvec:cartographer")
```

## BPMN flow

```
flowchart LR
    A[/cartograph/] --> B{args?}
    B -->|no args| C[T1 Structural Spine\nget_repo_map token_budget=2000]
    B -->|--concept X| D[T2 Intent First\nsearch corpus=code]
    B -->|--focus-file F| E[T5 Topic-Sensitive Rebias\nget_repo_map focus_file=F]
    C --> F[lsp_document_symbols\non top-3 files]
    D --> G[T5 rebias on best hit\nget_repo_map focus_file=anchor]
    G --> H[C1 PageRank-Anchored Tour\nfind_similar on recurring symbols]
    E --> H
```

## Execution

**No args — T1 Structural Spine:**

```
get_repo_map(token_budget=2000)
```

Read the top-3 files; they give ~80% of system shape. Apply
`lsp_document_symbols` on each for full outlines.

**With `--concept X` — T2 then T5 (C1 PageRank-Anchored Concept Tour):**

```
search(query="<concept>", corpus="code")
```

Take the best-ranked hit's `lsp_location.file_path` as `anchor`:

```
get_repo_map(focus_file=anchor, token_budget=1500)
```

The rising files in the focused map ARE the topic's structural footprint.
Optionally:

```
find_similar(symbol_name="<concept>", top_k=8)
```

The similar clusters are the codebase's idiom footprint for this concept.

**With `--focus-file F` — T5 Topic-Sensitive Rebias:**

```
get_repo_map(focus_file="<F>", token_budget=1500)
```

Compares global ranks to focused ranks; rising files = topic neighborhood.

## Scale caveat (H9)

If the codebase has >5K files, the global map may be illegible (N1
generated-file hijack or test-hijack). Use sub-root:

```
get_repo_map(root="src/", token_budget=2000)
```

Then recurse per subdirectory if still illegible (F5 Recursive Cartography).

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search,mcp__ripvec__find_similar")`
Codex: bare names directly.
