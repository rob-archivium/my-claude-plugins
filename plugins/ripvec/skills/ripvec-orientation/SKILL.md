---
name: ripvec-orientation
description: >
  Use when starting any non-trivial codebase task — orientation, debugging,
  refactoring, teaching, or quality audit. Triages which ripvec orientation
  (Cartographer / Detective / Refactorer / Onboarder / Sentinel) fits the
  task and routes to the corresponding hub-skill. Fires before narrower
  ripvec skills to prevent picking the wrong orientation mid-stream. Load
  early in any codebase session.
graph:
  generalizes_to: []
  specializes_into:
    - ripvec:cartographer
    - ripvec:detective
    - ripvec:refactorer
    - ripvec:onboarder
    - ripvec:sentinel
  cross_references:
    - ripvec:intent-routing
    - ripvec:recipes
    - ripvec:codebase-orientation
    - ripvec:change-impact
    - ripvec:semantic-discovery
  escalate_to: null  # terminal hub — escalation routes through specializes_into
---

# ripvec-orientation

**Be terse. Tokens cost.** Sections cite the graph; don't restate it.

Top-level entry point for the ripvec plugin. Triage which orientation
fits the task, locate the right hub-skill, and route to its first recipe.

The territory this skill teaches: `docs/SKILL_SEMANTIC_GRAPH.md` (the
graph layer) and `docs/SKILL_TASK_INTENT_INDEX.md` (the inverse
intent→recipe lookup). Both live in the ripvec engine repo.

---

## §1 — The 5 orientations: decision tree

| Trigger phrasing | Hub | Hub-skill | Specializes into |
|---|---|---|---|
| "What matters?" / "How is this organized?" / "Where does X live?" | **Cartographer** | `ripvec:cartographer` | CL-STRUCTURAL-SPINE, CL-CONCEPT-TOUR, CL-FOCUS-DELTA, CL-NAMES-TAXONOMY, CL-RECURSIVE-CARTOGRAPHY |
| "This looks wrong." / "Works in isolation, fails in integration." / "Invariant violated." | **Detective** | `ripvec:detective` | CL-SIBLING-DIFF, CL-CAUSAL-INTERVENTION, CL-CONTRACT-AUDIT, CL-INDIRECT-DISPATCH-DIAGNOSIS |
| "Before I rename X." / "What's the blast radius?" / "Should I extract these?" | **Refactorer** | `ripvec:refactorer` | CL-BLAST-RADIUS, CL-CONTRACT-SURVEY, CL-FALSE-TWINS, CL-HIDE-VS-EXPOSE, CL-NAMING-DRIFT, CL-DUPLICATE-ANCHORED-EXTRACTION |
| "Teach me how Z works." / "Bring me up to speed." / "Explain the architecture." | **Onboarder** | `ripvec:onboarder` | CL-ARCHITECTURAL-TOUR, CL-CONCEPT-BY-EXAMPLE, CL-RECURSIVE-NARRATION, CL-IDIOM-CRYSTALLIZATION, CL-INVARIANT-LAYER |
| "Find dead code." / "What's wrong with this module?" / "Find god-modules." | **Sentinel** | `ripvec:sentinel` | CL-DEAD-CODE-SWEEP, CL-ORPHAN-TRAIT, CL-COHESION-REFRACTION, CL-DUPLICATION-AS-MODULE, CL-PAGERANK-POLARITY, CL-CORPUS-CAP-AUDIT |

The five stances from `SKILL_SEMANTIC_GRAPH.md §2` (HUB-C through HUB-S).

---

## §2 — When to use which sub-skill

**Cartographer** — you don't know the territory. First call is structural
(`get_repo_map`), then semantic to anchor, then precision to confirm.

**Detective** — you have a symptom. Use the codebase as its own oracle.
The divergence IS the diagnostic (Naur 1985; Pearl 2009 do-calculus).

**Refactorer** — you're about to change something. Quantify before moving.
Blast radius is a number, not a guess.

**Onboarder** — you're teaching (yourself or another agent). Curate
evidence that induces the right mental model. Examples before definitions
(Bruner 1966).

**Sentinel** — you're auditing. Start with a probe; the probe's polarity
decides what it found. Every finding declares its falsification rule in
advance (Popper 1934).

---

## §3 — Tool surface

**Claude Code** — MCP tools are deferred; load via `ToolSearch`:

```
ToolSearch("ripvec")
ToolSearch("select:mcp__ripvec__get_repo_map,mcp__ripvec__search,mcp__ripvec__find_similar,mcp__ripvec__find_duplicates,mcp__ripvec__find_dead_code")
ToolSearch("select:mcp__ripvec__lsp_prepare_call_hierarchy,mcp__ripvec__lsp_incoming_calls,mcp__ripvec__lsp_outgoing_calls,mcp__ripvec__lsp_workspace_symbols,mcp__ripvec__lsp_goto_implementation")
```

The namespace is `mcp__ripvec__*` (project `.mcp.json`) or
`mcp__plugin_ripvec_ripvec__*` (plugin binary). Prefer the **native
`LSP()` tool** in Claude Code for call hierarchy and references when
a language server is configured; use ripvec MCP `lsp_*` as fallback.

**Codex** — bare names directly. No `ToolSearch`, no prefix. The ripvec
MCP `lsp_*` tools ARE the LSP path (Codex has no native LSP).

**Index lifecycle.** Auto-reconcile on every search (blake3-confirmed
mtime/size/inode diff). No manual reindex needed. CPU-only Model2Vec;
no on-disk cache.

---

## §4 — Plugin surface (4.1.10)

### Skills (this plugin — 4.1.10)

| Skill | Role |
|---|---|
| `ripvec:ripvec-orientation` | This skill — entry point and triage |
| `ripvec:intent-routing` | Phrasal intent → hub/cluster/first-recipe lookup table |
| `ripvec:cartographer` | Map-building orientation hub (Track B) |
| `ripvec:detective` | Debugging orientation hub (Track B) |
| `ripvec:refactorer` | Refactoring orientation hub (Track B) |
| `ripvec:onboarder` | Teaching orientation hub (Track B) |
| `ripvec:sentinel` | Quality-audit orientation hub (Track B) |
| `ripvec:codebase-orientation` | Structural spine entry (legacy; still fires on phrasing) |
| `ripvec:change-impact` | Blast radius entry (legacy; still fires on phrasing) |
| `ripvec:semantic-discovery` | Semantic search entry (legacy; still fires on phrasing) |
| `ripvec:recipes` | Graph-bridged recipe index (3.1.2-era names → 4.1.x clusters) |
| Language skills (7) | `c-recipes`, `javascript-recipes`, `python-recipes`, `rust-recipes`, `go-recipes`, `jvm-recipes`, `polyglot-recipes` (Track C) |

### Commands

| Command | When to invoke |
|---|---|
| `/orient` | Top-level entry — triggers this triage then routes |
| `/cartograph` | Cartographer hub — T1/T2/T5/C1 with optional --focus-file or --concept |
| `/blast-radius $SYMBOL` | Refactorer T10 chain — lsp_workspace_symbols → call hierarchy fixed-point |
| `/dead-code` | Sentinel T16 sweep — confidence-band-aware |
| `/audit` | Sentinel multi-cluster — C11 PageRank Polarity first, fans out |
| `/teach $CONCEPT` | Onboarder T13+T14 — architectural tour + concept-by-example |
| `/trace $SYMBOL` | Detective T7 Recursive Caller Climb |
| `/map` | Quick `get_repo_map` with optional focus |
| `/find` | `search` shorthand |
| `/similar` | `find_similar` shorthand |
| `/hotspots` | Top-PageRank functions |
| `/duplicates` | `find_duplicates` shorthand |

### Agents (executive-function specialists, 4.1.10)

| Agent | Hub | When to escalate |
|---|---|---|
| `ripvec:refactor-planner` | Refactorer | Long-running, multi-file refactor where T10 blast-radius needs invariant-grouped commit plan |
| `ripvec:bug-detective` | Detective | Root-cause investigation needing Pearl do-calculus + log_level intervention |
| `ripvec:codebase-teacher` | Onboarder | Inducing mental model in a learner agent via curated evidence (T13+T14+C9) |
| `ripvec:drift-auditor` | Sentinel | Multi-cluster quality probe with falsifiable findings (C11 → fan-out) |
| `ripvec:code-explorer` | Cartographer+Onboarder | Broad exploration when no specific hub dominates |
| `ripvec:duplicate-detector` | Sentinel+Refactorer | Duplication-focused; feeds both audit and extract decisions |

---

## §5 — When NOT to use this plugin

- You need an **exact string** → `Grep` / `rg`
- You need a **regex match** → `Grep`
- You need **file paths matching a glob** → `Glob`
- You **know the file** you need → `Read` it directly
- You have a **known symbol** → native `LSP() go_to_definition`

This plugin is for the "I don't know where to start" moment and
for structured compositional work (blast radius, sibling diff,
dead-code sweep, etc.). Once oriented, switch to precise tools.

---

## §6 — Recommended entry: `/orient`

`/orient` wraps this triage. Pass args:

```
/orient "what matters in this codebase?"     → routes to Cartographer → T1
/orient "why does the auth fail in staging?" → routes to Detective → T7/T9
/orient "before I rename EmbedBackend"       → routes to Refactorer → T10
```

If the answer to "which orientation?" is ambiguous, check
`ripvec:intent-routing` — it has verbatim phrasal matches from
`SKILL_TASK_INTENT_INDEX.md §§1-8`.
