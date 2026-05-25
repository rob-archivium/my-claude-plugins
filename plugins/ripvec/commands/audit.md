---
name: audit
description: Sentinel multi-cluster audit — runs C11 PageRank Polarity Probe first, then fans to dead-code sweep, cohesion refraction, naming drift, and orphan trait per signal
arguments:
  - name: module
    description: Module path or file to audit (optional — runs at root if not specified)
    required: false
---

Load the `ripvec:sentinel` skill, then execute the full multi-cluster
Sentinel audit. C11 PageRank Polarity fires first; per-signal fan-out
follows.

```
Skill("ripvec:sentinel")
```

## BPMN flow

```
flowchart LR
    A[/audit module?/] --> B[C11 PageRank Polarity\nget_repo_map root=module]
    B --> C{god-module?\nrank gt mu+2σ, breadth gt 40%}
    B --> D{dead islands?\nrank lt 0.1σ, zero refs}
    B --> E{CL-COHESION signal?\nsize gt 30 symbols}
    C -->|yes| F[T18 Cohesion Refraction\nfind_duplicates intra_file=true\n+ lsp_document_symbols]
    D -->|yes| G[T16 Dead-Code Sweep\nfind_dead_code root=module]
    E -->|yes| F
    B --> H{naming drift signal?}
    H -->|yes| I[T11 Drift Index Audit\nlsp_workspace_symbols pattern]
    B --> J{traits with few impls?}
    J -->|yes| K[T17 Orphan-Trait Extinction\nlsp_goto_implementation per trait]
    F --> L[Synthesis: findings with falsification rules]
    G --> L
    I --> L
    K --> L
```

## Execution

**Step 1: C11 PageRank Polarity Probe (mandatory first step).**

```
get_repo_map(root="<module or root>", token_budget=2000)
```

Compute rank statistics from the result:
- **God-module signal**: `rank > μ + 2σ` AND module breadth > 40% of
  total files touched → fire T18 Cohesion Refraction.
- **Dead-island signal**: `rank < 0.1σ` AND zero non-test references
  → fire T16 Dead-Code Sweep on the low-rank cluster.

**Step 2: Per-signal fan-out.**

**T16 Dead-Code Sweep** (when dead-island signal fires):
```
find_dead_code(root="<module>", min_cluster_size=1, max_clusters=50)
```
Confidence-band triage per `/dead-code` discipline.

**T18 Cohesion Refraction** (when god-module or >30 symbols):
```
find_duplicates(root="<module>", intra_file=true)
lsp_document_symbols(file_path="<god-module file>")
```
Intra-file duplicate clusters pre-draw the split lines.

**T11 Drift Index Audit** (when naming pattern looks heterogeneous):
```
lsp_workspace_symbols(query="<common prefix>")
```
Compute dedup-delta; `drift_quotient ≥ 0.45` = theory fracture.

**T17 Orphan-Trait Extinction** (when traits have few or zero impls):
```
lsp_goto_implementation(lsp_location=<trait location>)
lsp_references(lsp_location=<trait location>)
```
(impls=0, refs=0) = orphan; (impls=1, refs=sparse) = vestigial;
(impls>1) = load-bearing.

**Step 3: Corpus-cap check (C12).**

If `find_duplicates` or `find_dead_code` returns `capped=true`, partition
by top-level subdirectory and re-run per partition.

## Report format

Every finding MUST declare its falsification rule:

> "I ran a *PageRank Polarity Probe* on `<module>`; finding: `<file>`
> is rank μ+2.4σ with 47% module breadth → god-module candidate.
> Falsification: if `find_duplicates(intra_file=true)` returns ≤2 clusters,
> the breadth is earned centrality, not cohesion failure."

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__find_dead_code,mcp__ripvec__find_duplicates,mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_goto_implementation,mcp__ripvec__lsp_references,mcp__ripvec__lsp_document_symbols")`
Codex: bare names directly.
