---
name: javascript-recipes
description: >
  Use when working with JavaScript, TypeScript, JSX/TSX, React, Express,
  or Node.js code. Triggers on: "find dead code in this React app",
  "what calls this hook", "what does this component render", "trace this
  useEffect", "dead_fraction=1.0 on JS", "JSX find_similar empty",
  "handler not detected as caller", "useCallback closure attribution",
  "express middleware as entry", "module.exports as entry-point". Covers
  the M19 react ↔ express dipole and the M20 Structure-At-Render-Time
  principle. Specializes the hub skills for JS framework idioms —
  closure-as-protocol, callback registration with runtime schedulers,
  JSX chunk-boundary noise.
graph:
  generalizes_to:
    - ripvec:cartographer
    - ripvec:detective
    - ripvec:refactorer
    - ripvec:onboarder
    - ripvec:sentinel
  specializes_into: []
  cross_references:
    - ripvec:ripvec-orientation
    - ripvec:intent-routing
    - ripvec:recipes
    - ripvec:python-recipes
    - ripvec:jvm-recipes
  escalate_to: ripvec:detective
---

# javascript-recipes — JS / TS / React / Express as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` Part XI (Wave 5, post-4.1.3)
and `docs/BUG_DATABASE.md` §§2, 5 by line rather than restating. **The
JS lane is where M20 (Structure-At-Render-Time) was earned** (Part XI
§XI.4, lines 3182-3211); the language's character is "control flow is
computed at runtime from state/props/hook closures, not at file time."

## §0 Graph position

Specializes the five hub orientations for the JS family (JavaScript,
TypeScript, JSX, TSX). Triage (`ripvec:ripvec-orientation` →
`ripvec:intent-routing`) routes here when the corpus is
`.js`/`.jsx`/`.ts`/`.tsx`-dominant. JS work most often escalates to
`ripvec:detective` (closure attribution gaps) or `ripvec:sentinel`
(framework-shaped dead-code reports where `dead_fraction` is a lower
bound by construction).

## §1 Language character

What ripvec sees on a JS corpus:

- **`find_dead_code` entry-point seeds exist but are *insufficient.***
  B-0008 (I#70) closed 4.1.4: `export default function`,
  `module.exports = ...`, `*.test.*` / `*.spec.*` now seed. On react
  this yields `1694 library exports + 32 tests` but `dead_fraction`
  remains 0.967 because B-0005 (closure attribution) dominates.
- **Closure-bounded calls are silently dropped.** B-0005 (I#71) Open
  (verified 4.1.9): hook bodies (`useCallback`/`useEffect`/`useMemo`)
  emit ZERO outgoing edges. On `react-devtools-shared` the probe
  showed `lsp_outgoing_calls` returned `results: []` even for direct
  `useState`/`useEffect` calls when ANY arrow-callback argument was
  present — bug is broader than originally specced (per BUG_DATABASE
  §1 lines 183-208).
- **`lsp_prepare_call_hierarchy` returns silent empty on JS positions.**
  Worse than the Rust closure analog (which at least flags
  `nearest_preceding=true`).
- **JSX `find_similar` recovered.** B-0016 (I#72) closed Cycle 11 W3:
  function components now return semantically-near candidates at
  sim 0.87-0.89 on react-devtools-shared (BUG_DATABASE §5 lines
  433-466). If you see sim 0.04-class scores, you're on a pre-4.1.9
  substrate.
- **Express server-side seeds are incomplete.** B-0010 (I#74) Open:
  `app.listen`, `app.get/post/put`, `module.exports = router` not
  seeded as carefully as React's `createRoot().render()`. Server
  `dead_fraction=0.988` on Cycle 11 W3 express probe.
- **M14 status:** react (982 files, hook-heavy) is the JS-framework
  sentinel; express is the JS-server dipole partner.

## §2 Working recipes (JS earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **Identifier-Convention Fallback (NC11 JS variant)** | "Who calls this hook?" — and `lsp_incoming_calls` is silent | `mcp__ripvec__lsp_workspace_symbols(query="use<Hook>", kind=12)` then `mcp__ripvec__search(query="invokes <hook> in render body")` | The convention IS the dispatch index when call-hierarchy is broken (B-0005) — `useXxx`, `handleXxx`, `onXxx` carry semantic load; M20 + Part XI §XI.3 amendment | Part XI §XI.3 lines 3095-3103 |
| **Spec-Oracle Drift (NC13) on TS migration** | "Is this component still matching its TypeScript interface?" | `mcp__ripvec__find_similar(symbol_name=ComponentName, corpus="all", top_k=5)` → look for spec/`.d.ts` at sim 1.0 and live at sim < 0.85 | The 1.0-to-live gap is a *quantitative drift index*; a 0.33 gap predicts ~4 specific divergences | Part X §X.4 NC13 lines 2661-2675 |
| **JSX Component Cluster (post-4.1.9)** | "Find components similar to this Dialog" | `mcp__ripvec__find_similar(symbol_name="DialogContent", top_k=5)` → sim 0.87-0.89 cluster of JSX components | If sim < 0.10, you're on pre-4.1.9 substrate — B-0016 didn't reproduce on react-devtools-shared after 4.1.9 chunker improvements | BUG_DATABASE §5 lines 446-466 |
| **Framework-Aware Dead-Code Sweep** | "What's actually dead in this React/Express app?" | `mcp__ripvec__find_dead_code(root=corpus, summary_only=true, min_cluster_size=50, max_clusters=5)` THEN inspect cluster roots against the seed list | Treat `dead_fraction` as a LOWER BOUND when B-0005/B-0010 are open — closure-dispatched and middleware-dispatched code is reachable but invisible | B-0005, B-0008, B-0010 |
| **Express Route-Handler Recovery** | "What handles POST /users?" | `mcp__ripvec__search(query="POST users route handler", corpus="code")` then `mcp__ripvec__lsp_references` on each handler fn | Server-side B-0010 means `app.post(path, handler)` doesn't register `handler` as live; route discovery is search-grade | B-0010 |
| **Hook-Cluster Convention Audit** | "Are all our `useXxx` hooks following the same pattern?" | `mcp__ripvec__find_duplicates(threshold=0.85, intra_file=false, root=corpus/src/hooks)` | High-sim cluster across `useXxx`-named functions = consistent convention; outliers at sim 0.85-0.92 are refactor candidates per F8 | Part VII F8 lines 1660-1664 |
| **M20 Render-Time Escape Hatch** | "Why does this component appear dead?" | Identifier-convention search + `mcp__ripvec__search(query="render this in JSX", corpus="all")` | Declare a "scheduler-blind zone" in your report; runtime-scheduled invocations are recoverable only by tracing the scheduler | Part XI §XI.4 M20 lines 3182-3211 |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0005** (I#71) JS closure attribution | Open (P1, target 4.2.0) | `lsp_outgoing_calls` on hook-shaped functions returns empty `results: []`; broader than spec — top-level calls also drop when arrow-callback siblings present | Identifier-convention fallback (recipe above); `mcp__ripvec__search` over hook names | BUG_DATABASE §1 lines 168-208 |
| **B-0008** (I#70) JS entry-point detector | Closed 4.1.4 (partial) | 1694 exports + 32 tests seed on react, but `dead_fraction=0.967` because B-0005 dominates | Treat `dead_fraction` as lower bound; verify with identifier-convention probes | BUG_DATABASE §2 lines 247-263 |
| **B-0010** (I#74) Express server entry | Open (P2, target 4.2.0) | `app.listen()`, `app.METHOD(handler)`, `module.exports = router` not seeded; express `dead_fraction=0.988` | Augment seeds via `lsp_workspace_symbols(query="app.get|app.post|app.use")` and treat their handler args as live | BUG_DATABASE §2 lines 294-322 |
| **B-0016** (I#72) JSX `find_similar` silence | Closed Cycle 11 W3 | Pre-4.1.9: 0.044 sim on visually-near components | If reproducing on a current substrate, you're on the wrong corpus — re-try on react-devtools-shared (application code) not react-dom (renderer) | BUG_DATABASE §5 lines 433-466 |
| **B-0030** (I#75) `pre_dedup_count` 500 cap | Open (P3) | `useCallback` / `useState` saturate `pre_dedup_count=500` on react; `drift_meaningful=false` correctly reports unreliable | Accept `drift_meaningful=false` as the answer; ask narrower queries | BUG_DATABASE §7 lines 657-675 |

## §4 Language-specific BPMN — the JS framework-corpus flow

```mermaid
flowchart TD
  U[User: "find dead code", "trace this hook",<br/>"who calls this component"] --> S{Corpus shape?}
  S -->|React-style framework<br/>hooks + JSX| RF[mcp__ripvec__find_dead_code<br/>summary_only=true<br/>min_cluster_size=50]
  S -->|Express-style server<br/>routes + middleware| ES[mcp__ripvec__find_dead_code<br/>+ supplement with route search]
  RF --> RC{dead_fraction > 0.5<br/>AND cluster rooted at<br/>hook-shaped fn?}
  RC -->|Yes| BC[B-0005 closure attribution<br/>**Apply NC11 JS variant**]
  RC -->|No| RR[Likely real dead code;<br/>route to refactorer]
  BC --> IC[**Identifier-Convention Fallback**<br/>mcp__ripvec__lsp_workspace_symbols<br/>query=use* or handle* or on*]
  IC --> SR[mcp__ripvec__search<br/>query='invokes Hook in render body'<br/>corpus=code]
  SR --> CV[Cross-verify reachability<br/>via M20 scheduler-blind-zone<br/>declaration]
  ES --> EC{Top cluster is a<br/>route handler?}
  EC -->|Yes| EH[mcp__ripvec__lsp_workspace_symbols<br/>query='app.get|app.post|app.use'<br/>treat handler args as live seeds]
  EC -->|No| EM[Possibly middleware;<br/>search 'app.use' usage]
  CV --> ESC[If still unresolved →<br/>escalate to ripvec:detective]
  EH --> RR
```

## §5 Cross-corpus calibration

JS is exercised by the **M19 dipole** (Part XI §XI.4, lines 3164-3181):

- **react** (982 files) — JS-framework substrate sentinel. Surfaced
  I#70/I#71/I#72 + M20 (Structure-At-Render-Time). The hook-heavy
  application code (react-devtools-shared) is the reproduction
  target; react-dom (renderer code) is the wrong target — bugs
  there don't characterize framework-shape codebases.
- **express** — JS-server dipole partner. Surfaces B-0010
  (route-registration entries) cleanly; the server idiom (callback
  registration with a runtime scheduler) is M20's other empirical
  form alongside React's render-time structure.
- **Cycle 8+ rotation:** TypeScript is the Phase 2 onboarding target
  (Part X §X.8, lines 2885-2904). The React lane already includes
  `compiler/packages/babel-plugin-react-compiler/` as a TS pilot.
- **Diagnostic rule:** a JS bug reproducing on BOTH react and express
  is **JS-general** (e.g., closure attribution); one only on react
  is **framework-specific** (M20 territory); one only on express is
  **server-shape-specific** (route-seed gap).

## §6 Heritage citations

The JS bibliography earned in cross-corpus campaigns (verbatim from
Part XI §XI.9):

- **Crockford, D.** *JavaScript: The Good Parts* (2008) —
  functions-as-values is the substrate; every callback is a closure
  registration. **M20 anchor.**
- **Abramov, D.** *A Complete Guide to useEffect* (overreacted.io,
  2019) — every render is a fresh closure-over-state; static
  analysis cannot see the capture. **M20 anchor for the React
  variant.**
- **Reynolds, J.** *Definitional Interpreters for Higher-Order
  Programming Languages* (1972); *Types, Abstraction and Parametric
  Polymorphism* (1983) — every late-bound dispatch is morally a
  closure (callbacks ARE closures; render-tree dispatch IS
  defunctionalized). **M20 + MK-4 shared anchor; CPS Callback-as-
  Protocol heritage.**
- **Steele, G. & Sussman, G.** *The Art of the Interpreter* — the
  lambda-as-protocol that makes JS callback registration semantically
  load-bearing. Heritage for the identifier-convention fallback (the
  `useXxx`/`handleXxx` convention IS the protocol's documentation).
- **Hickey, R.** *Are We There Yet?* (2009); *Simple Made Easy*
  (2011) — place-oriented programming and runtime dispatch as the
  engineering choice React/Express both make. **M20 anchor.**
- **Pike, R.** *Errors are values* (2015) — the empty
  `lsp_outgoing_calls` IS the result (B-0005 diagnostic); shared
  with NC1a/M2.
