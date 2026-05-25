---
name: orient
description: Top-level ripvec entry point — triages which orientation (Cartographer / Detective / Refactorer / Onboarder / Sentinel) fits the task, then routes to the appropriate hub-skill and first recipe
arguments:
  - name: args
    description: Task description or question (e.g. "what matters in this codebase?", "before I rename EmbedBackend", "find dead code")
    required: false
---

Load the `ripvec:ripvec-orientation` skill, then route the user's args
to the matching orientation hub.

```
Skill("ripvec:ripvec-orientation")
```

## BPMN flow

```
flowchart LR
    A[/orient args/] --> B{ripvec-orientation triage}
    B -->|"What matters?"| C[Cartographer\nripvec:cartographer]
    B -->|"Wrong / invariant"| D[Detective\nripvec:detective]
    B -->|"Before I rename"| E[Refactorer\nripvec:refactorer]
    B -->|"Teach me / explain"| F[Onboarder\nripvec:onboarder]
    B -->|"Find dead code"| G[Sentinel\nripvec:sentinel]
    C --> H[get_repo_map / search]
    D --> I[find_similar / lsp_incoming_calls]
    E --> J[lsp_prepare_call_hierarchy]
    F --> K[get_repo_map + find_duplicates]
    G --> L[find_dead_code / get_repo_map]
```

## Triage rules (from `SKILL_SEMANTIC_GRAPH.md §2`)

1. If the args contain "what matters" / "how is organized" / "where lives"
   / "explain architecture" / "show structure" → **Cartographer**
   → first recipe: T1 Structural Spine via `get_repo_map(token_budget=2000)`

2. If the args contain "wrong" / "broken" / "invariant" / "isolation"
   / "fails in integration" → **Detective**
   → first recipe: T6 Sibling Diff via `find_similar` or T7 Recursive
   Caller Climb via `lsp_prepare_call_hierarchy` + `lsp_incoming_calls`

3. If the args contain "rename" / "blast radius" / "refactor" / "before I
   change" / "trait edit" / "extract" → **Refactorer**
   → first recipe: T10 Blast-Radius Manifest via `lsp_workspace_symbols`
   → `lsp_prepare_call_hierarchy` → `lsp_incoming_calls` (P2 fixed-point)

4. If the args contain "teach" / "explain" / "bring me up to speed"
   / "how does X work" / "architecture tour" → **Onboarder**
   → first recipe: T13 Top-N Architectural Tour via `get_repo_map`

5. If the args contain "dead code" / "drift" / "god-module" / "orphan"
   / "cohesion" / "duplicate" / "audit" → **Sentinel**
   → first recipe: C11 PageRank Polarity via `get_repo_map`, then fan out

6. If ambiguous: load `ripvec:intent-routing` and match the verbatim
   phrase against §§1-6 of the intent index.

## Tool access

Claude Code:
```
ToolSearch("ripvec")
```

Codex: bare names directly (`get_repo_map`, `search`, `find_dead_code`, etc.)
