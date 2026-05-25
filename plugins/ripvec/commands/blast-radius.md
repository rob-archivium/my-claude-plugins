---
name: blast-radius
description: Refactorer T10 chain — compute the blast radius of changing a symbol before any rename, signature change, or trait edit
arguments:
  - name: symbol
    description: Symbol name to compute blast radius for (required)
    required: true
---

Load the `ripvec:refactorer` skill, then execute the T10 Blast-Radius
Manifest (P2 Fixed-Point Expansion).

```
Skill("ripvec:refactorer")
```

## BPMN flow

```
flowchart LR
    A[/blast-radius SYMBOL/] --> B[lsp_workspace_symbols\nquery=SYMBOL]
    B --> C{exact match?}
    C -->|yes| D[P10 chunk-align\nlsp_document_symbols file]
    C -->|no| E[pick closest match\nfrom candidates]
    E --> D
    D --> F[lsp_prepare_call_hierarchy\nlsp_location from chunk-aligned]
    F --> G[lsp_incoming_calls\ncall_item]
    G --> H{new callers?}
    H -->|yes - P2 fixed-point| F
    H -->|quiescent| I[lsp_outgoing_calls\ncall_item]
    I --> J[get_repo_map\nfocus_file=SYMBOL file]
    J --> K[Report: incoming count,\nfile spread, weak/strong]
```

## Execution

**Step 1: Locate the symbol.**

Claude Code:
```
ToolSearch("select:mcp__ripvec__lsp_workspace_symbols")
mcp__ripvec__lsp_workspace_symbols(query="<symbol>")
```

Codex: `lsp_workspace_symbols(query="<symbol>")`

**Step 2: Chunk-align (P10 — mandatory before cross-tool composition).**

Take the `lsp_location` from the workspace symbol result. Route through
`lsp_document_symbols` on the file to get a chunk-aligned coordinate
before calling the call hierarchy.

**Step 3: Build call hierarchy and expand (P2 Fixed-Point).**

```
lsp_prepare_call_hierarchy(lsp_location=<chunk-aligned location>)
→ call_item

lsp_incoming_calls(call_item)   # repeat until no new callers appear
lsp_outgoing_calls(call_item)   # what this symbol depends on
```

Recurse `lsp_incoming_calls` on each new caller until quiescent. The
quiescent set IS the blast radius.

**Step 4: Structural neighborhood.**

```
get_repo_map(focus_file=<symbol's file>, token_budget=1500)
```

Confirms which files are structurally coupled to the symbol's file.

## Reading the result

| Signal | Interpretation |
|---|---|
| Blast radius ≤5 files, all same module | Low-cost rename |
| Blast radius 6-20 files, 2-3 modules | Medium cost; plan in phases |
| Blast radius >20 files, cross-module | High cost; check drift_quotient (T11) first |
| `drift_quotient ≥ 0.45` | Theory fracture — rename + conceptual clarification both needed |

## Caveats

- **I#69 Python silent-empty**: `lsp_outgoing_calls` may return empty on
  Python. Use semantic search as a supplement:
  `search(query="<symbol>", corpus="code")` to find additional callers.
- **I#50 location-coord mismatch**: prefer `symbol_name=` input over raw
  location when calling `find_similar` downstream.

## Tool access

Claude Code: `ToolSearch("select:mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_document_symbols,mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls,mcp__ripvec__get_repo_map")`
Codex: bare names directly.
