---
name: trace
description: Detective T7 Recursive Caller Climb — Pearl do-calculus on the call DAG. Traces why a symbol is reachable from a particular entry path. Use when "works in isolation, fails in integration".
arguments:
  - name: symbol
    description: Symbol name or location to trace callers of (required)
    required: true
---

Load the `ripvec:detective` skill, then execute the T7 Recursive Caller
Climb (Pearl do-calculus on a DAG).

```
Skill("ripvec:detective")
```

## BPMN flow

```
flowchart LR
    A["/trace SYMBOL"] --> B[lsp_workspace_symbols\nquery=SYMBOL]
    B --> C[P10 chunk-align\nlsp_document_symbols file]
    C --> D[lsp_prepare_call_hierarchy\nchunk-aligned location]
    D --> E[lsp_incoming_calls\ncall_item]
    E --> F{new callers found?}
    F -->|yes - P2 fixed-point| G[lsp_prepare_call_hierarchy\non each new caller]
    G --> E
    F -->|quiescent| H{reaches entry point?}
    H -->|yes| I[trace complete\nreport call chain]
    H -->|no| J[T9 fallback: search for\npossible indirect dispatch]
    J --> K[NC11 closure/fn-ptr check\nfind_dead_code to compare]
```

## Execution

**Step 1: Locate the symbol.**

```
lsp_workspace_symbols(query="<symbol>")
```

Pick the exact match. If multiple candidates, present them and ask which.

**Step 2: P10 chunk-align (mandatory).**

Route the `lsp_location` from workspace symbols through
`lsp_document_symbols(file_path=...)` to get chunk-aligned coordinates
before calling the hierarchy.

**Step 3: Build the hierarchy and climb (P2 Fixed-Point).**

```
lsp_prepare_call_hierarchy(lsp_location=<chunk-aligned>)  → call_item
lsp_incoming_calls(call_item)                              → callers[]
```

For each caller in `callers[]`:
```
lsp_prepare_call_hierarchy(lsp_location=<caller.lsp_location>)
lsp_incoming_calls(call_item)
```

Continue recursively until:
- A known entry point is reached (main, request handler, test, etc.), OR
- No new callers appear (fixed-point reached — symbol is not transitively
  reachable from any named entry).

**Step 4: Causal intervention (when the call chain looks surprising).**

If the chain reveals an unexpected caller, apply C3 Causal Subsystem
Isolation to confirm causality vs correlation:

```
log_level(filter="<suspect module>=trace")
# reproduce the failure
debug_log()
log_level(previous_filter=true)  # reversible
```

**Step 5: NC11 indirect-dispatch fallback.**

If `lsp_incoming_calls` returns sparse or empty results but the codebase
is known to use callbacks, fn-pointers, decorators, or closures:

```
find_dead_code(root="<relevant subtree>", min_cluster_size=1)
```

If `find_dead_code` marks the symbol as dead but `lsp_incoming_calls` is
empty, the gap is the indirect-dispatch boundary (NC11). File as
fn-ptr/closure attribution gap, not a real dead-code finding.

## Reading the result

The call chain is the "do-calculus path" (Pearl 2009): following callers
up the DAG shows which component CAUSES the symbol to execute, not just
which component correlates with the failure.

Report format:
> "Traced `<symbol>` via T7 Recursive Caller Climb. Call chain:
> `<symbol>` ← `<caller_1>` ← `<caller_2>` ← `<entry point>`.
> Intervention point: `<caller_N>` — this is the component controlling
> whether `<symbol>` is invoked in the failing integration context."

## Caveats

- **I#38**: Python `prepare_call_hierarchy` resolved in 4.1.3; update
  to latest ripvec before tracing Python code.
- **I#69**: Python `lsp_outgoing_calls` may return empty. Use semantic
  search as supplement: `search(query="<symbol>", corpus="code")`.
- For JS/React callbacks (I#70-72): NC11 fallback is the primary path.

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__log_level,mcp__ripvec__debug_log,mcp__ripvec__find_dead_code")`
Codex: bare names directly.
