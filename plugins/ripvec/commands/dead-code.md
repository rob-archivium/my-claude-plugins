---
name: dead-code
description: Sentinel dead-code sweep — confidence-band-aware, with NC11 fallback when find_dead_code disagrees with LSP
arguments:
  - name: summary_only
    description: Show summary only, not member_defs per cluster (default true)
    required: false
  - name: min_cluster_size
    description: Minimum cluster size to report (default 1; raise to 3+ for large codebases)
    required: false
  - name: max_clusters
    description: Maximum clusters to return (default 50; lower to 20 for large corpora)
    required: false
---

Load the `ripvec:sentinel` skill, then execute the T16 Dead-Code Sweep
(confidence-band-aware).

```
Skill("ripvec:sentinel")
```

## BPMN flow

```
flowchart LR
    A[/dead-code/] --> B[find_dead_code\nwith parameters]
    B --> C{capped=true?}
    C -->|yes| D[NC15: scope to subdirectory\nfind_dead_code root=subtree]
    C -->|no| E{any confidence=Low?}
    E -->|yes| F[NC11 fallback\nlsp_incoming_calls on Low clusters]
    E -->|no| G[Report clusters\nby size descending]
    F --> H{LSP confirms dead?}
    H -->|yes| G
    H -->|no| I[Flag as indirect dispatch\ncheck closure / fn-ptr / decorator]
    D --> E
```

## Execution

**Step 1: Run the sweep.**

Claude Code:
```
ToolSearch("select:mcp__ripvec__find_dead_code")
mcp__ripvec__find_dead_code(
  include_test_paths=false,
  max_clusters=<max_clusters or 50>,
  min_cluster_size=<min_cluster_size or 1>
)
```

Codex: `find_dead_code(include_test_paths=false, max_clusters=50, min_cluster_size=1)`

**Step 2: Check for corpus cap.**

If `capped=true` in the response, the corpus exceeded the internal limit.
Scope to a subdirectory and re-run (NC15):

```
find_dead_code(root="src/", min_cluster_size=3, max_clusters=20)
```

**Step 3: Confidence-band triage.**

- `confidence=High`: reliable. Confirm with `lsp_incoming_calls` before
  deleting; accept the finding if incoming is empty.
- `confidence=Medium`: likely true. `lsp_incoming_calls` + `lsp_references`
  to confirm; check for test-only callers.
- `confidence=Low`: mostly false positives (fn-ptr / closure / decorator
  dispatch). Fire NC11 Closure-Attributed Call-Edge Lookup:

```
lsp_prepare_call_hierarchy(lsp_location=<root_node of Low cluster>)
lsp_incoming_calls(call_item)
```

If `lsp_incoming_calls` returns callers: the node is live; the static
analyzer has a gap (I#55 fn-ptr struct-init edges). Flag as
indirect-dispatch boundary, not dead code.

**Step 4: N2 Wired-Stub check before deletion.**

Public symbols with no callers may be intentional API surface (N2
Wired-Stub Anti-Pattern). Annotate as TODO-wire / TODO-remove /
deliberately-dead before deleting.

## Reading the result

| Field | Meaning |
|---|---|
| `dead_clusters[].root_node` | Highest-PageRank node in the cluster — start here |
| `dead_clusters[].size` | Number of unreachable definitions |
| `dead_clusters[].total_lines` | LOC in cluster |
| `dead_fraction` | Fraction of total defs unreachable — use as relative signal, not absolute (I#49/I#50 over-report) |
| `entry_points_detected` | How many entry points were used for reachability |

## Caveats

- **I#49**: Rust LibraryExport detection misses `pub use` re-export chains —
  `dead_fraction` over-reports until 4.2.0 fix.
- **I#73**: C `int main()` false positive.
- **I#74**: Response size limit on large corpora — use NC15 parameters.
- **I#76**: OOM on full Linux kernel root — use sub-root mandatory.

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__find_dead_code,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_references")`
Codex: bare names directly.
