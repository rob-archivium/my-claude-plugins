---
name: python-recipes
description: >
  Use when working with Python code, especially Flask-like frameworks
  or Textual-like mixin-heavy applications. Triggers on: "MRO dispatch",
  "mixin handler", "find all overrides of this method", "Python class
  hierarchy", "docstring-grade prose probe", "@classmethod kind",
  "find_similar handle_error returns 5 candidates", "Liskov violation
  detector", "prepare_call_hierarchy returns silent empty on Python",
  "appcontext", "blueprint". Specializes the hub skills for Python
  idioms — MRO-flattened polymorphism, decorated-definition kind
  resolution, docstring-as-first-class-chunk.
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
    - ripvec:javascript-recipes
    - ripvec:polyglot-recipes
  escalate_to: ripvec:detective
---

# python-recipes — Python as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` Parts VII-X and
`docs/BUG_DATABASE.md` §§1, 2, 11 by line. **Python is the language
where NC2 MRO Proximity Collapse was discovered** (Part IX §IX.4,
lines 1980-2005); the canonical exemplar is mnemosyne's
`_handle_error` chorus (six overrides + one canonical surfaced in
one `find_similar` call).

## §0 Graph position

Specializes the five hub orientations for Python. Triage
(`ripvec:ripvec-orientation` → `ripvec:intent-routing`) routes here
when `.py`-dominant. Python work most often escalates to
`ripvec:refactorer` (MRO-detected near-duplicates as parameterization
candidates per NC12) or `ripvec:detective` (the M8 Liskov-violation
detector).

## §1 Language character

What ripvec sees on a Python corpus:

- **Mixin polymorphism flattens into semantic proximity.** Per NC2
  (Part IX §IX.4, lines 1980-2005), `find_similar(symbol_name=X)`
  on a mixin method returns the canonical + every per-subclass
  override in one call. Sim gradient IS bug-severity gradient:
  0.97-0.99 = deletion candidates, 0.85-0.88 = parameterization
  candidates, ~0.85 mixin canonical.
- **MRO inverse edges are emitted symmetrically.** B-0006 (I#25/I#58)
  closed 4.1.3: the original "MRO not in BFS" hypothesis was
  *falsified* — the gap was downstream truncation (B-0029 still
  open: 36 callers exceed the 25-cap, 11 silently lost on incoming
  side).
- **`lsp_prepare_call_hierarchy` works.** B-0003 (I#38/I#69) closed
  4.1.4 via the `nearest_preceding` flag generalisation. Was a
  major P0 blocker through Wave 3 (blocked ~8 patterns: T7, T10,
  T15, P2, P7, P9, Hide-Is-Dual-Gini, Prerequisite-Cleanup-Sizing).
- **Docstrings are first-class chunk content.** Per M14 (Part X §X.5,
  lines 2770-2781), the chunk-with-docstring contract IS what makes
  M7 (author-annotated outranks inferred) work. `corpus="docs"` +
  `rerank="always"` is the canonical first move on docstring-heavy
  Python (per M7, F3).
- **`decorated_definition` is over-tagged as Property.** B-0040
  (I#39) Cannot-verify in current audit; pre-Wave-3 every
  `@classmethod`/`@staticmethod`/`@cached_property`/`@property`
  returned kind=7 uniformly. Inspect decorator name in your reading.
- **`document_symbols` may omit multi-inherited classes.** B-0056
  (I#37) Cannot-verify post-permission-denial; pre-fix
  `MnemosyneApp(App)`, `BaseScreen(Screen, ErrorHandlerMixin)`
  invisible to `document_symbols` despite presence in
  `workspace_symbols`.
- **M14 status:** flask is the *minimum-sufficiency Python
  sentinel* (M13 entry); mnemosyne is the *polymorphism / MRO
  oracle* (Part X §X.7, lines 2868-2884).

## §2 Working recipes (Python earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **MRO Proximity Collapse (NC2)** | "Find all overrides of `_handle_error`" | `mcp__ripvec__find_similar(symbol_name="_handle_error")` — returns mixin + every subclass override in one call | Sim gradient = bug-severity gradient: 0.97-0.99 deletion, 0.85-0.88 parameterization, <0.85 keep | Part IX §IX.4 lines 1980-2005 |
| **Mixin-Override Telescope (NC12)** | "Refactor the `_handle_error` chorus" | NC2 result intersected with `mcp__ripvec__find_duplicates(threshold=0.85)` → sim-descending telescope ordering | Delete nearest first; parameterize farthest; keep canonical mixin | Part X §X.4 NC12 lines 2640-2660 |
| **Theory-First Prose Probe (F3)** | "How does appcontext work?" | `mcp__ripvec__search(query="how does the application context propagate through a request", corpus="docs", rerank="always")` then pivot to `corpus="code"` with vocabulary learned | Promoted to canonical across substrate versions on flask (`appcontext.rst` returned at sim 0.985-1.0) | Part VI F3 lines 1129-1156 |
| **Author-Annotated Duplicates (F2)** | "Why does Flask define `send_static_file` twice?" | `mcp__ripvec__find_duplicates(threshold=0.85)` then `mcp__ripvec__lsp_hover` on each side; look for "Note this is a duplicate of" annotation | Flask's `Scaffold`/`Flask` triple at sim 1.0000 / 0.9990 / 0.9790 is the canonical example | Part VI F2 lines 1098-1126; Part VII (promoted) |
| **Convention-Duplicated Override (F2.5)** | "Why do 5 screens share `_handle_error`?" | F2 produces a ≥5-member high-sim cluster; supplement with `search(query="error handling protocol", corpus="docs")` to find ARCHITECTURE.md prose | mnemosyne's `ARCHITECTURE.md §5 "Error Handling Protocol"` is the canonical exemplar | Part VII lines 1283-1301 |
| **Liskov-Violation Detector (M8)** | "Audit whether subclass overrides diverge on policy" | NC2 result → read each override's body; sim-band variance encodes behavioral divergence (re-raise vs notify vs switch-mode) | M8 generalises: Python mixins → Go interface satisfaction → Rust default trait methods overridden — same shape | Part IX §IX.5 M8 lines 2285-2299 |
| **P9 Inheritance-Aware Recall Bridge** | "Validate caller-count on a mixin method" | `ratio = lsp_references_count / lsp_incoming_calls_count` → ratio ~1 = direct, >5 = MRO dispatch signal | Now informational rather than diagnostic since B-0006 closed; useful as a regression check per F7 | Part VII P9 lines 1314-1334; F7 lines 1656-1659 |
| **Document-Workspace Symbol Divergence as Signal** | "Why is `Flask` class missing from document_symbols?" | Compare `lsp_document_symbols(file)` count vs `lsp_workspace_symbols(query=ClassName)` filtered to that file | Missing classes are usually load-bearing (multi-inheritance, project-base inheritance) — B-0056 territory | Part VII lines 1668-1673 |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0003** (I#38/I#69) Python `lsp_prepare_call_hierarchy` | Closed 4.1.4 | Pre-fix: silent empty on every Python position attempted | Confirm 4.1.4+ substrate (`nearest_preceding` flag visible in response data) | BUG_DATABASE §1 lines 139-154 |
| **B-0006** (I#25/I#58) MRO caller resolution | Closed 4.1.3 (root); **B-0029 residue** | 36 callers > 25 cap → 11 silently truncated | Treat caller counts > 25 as approximate; cross-check with `lsp_references` per P9 | BUG_DATABASE §1 lines 210-221 |
| **B-0029** (I#67) incoming-side `truncated_callers` parity | Open (P3) | No `truncated_callers` field paralleling `truncated_calls` | Compute manually: `lsp_references_count - lsp_incoming_calls.results.length` | BUG_DATABASE §7 lines 646-655 |
| **B-0028** (I#64) reranker doesn't weight prose-density | Open (P3) | `search("ErrorHandlerMixin handle_error in textual mixin")` returns sim 0.05 on mnemosyne; rerank Auto didn't fire | Force `rerank="always"` on docstring-heavy Python codebases (per H5′-2) | BUG_DATABASE §7 lines 635-644 |
| **B-0040** (I#39) `decorated_definition` kind | Cannot-verify in current audit | `@classmethod`/`@staticmethod`/`@cached_property` may report kind=7 (Property) | Inspect decorator name; don't trust kind=7 as exclusively `@property` | BUG_DATABASE §9 lines 796-804 |
| **B-0056** (I#37) `document_symbols` multi-inheritance omission | Cannot-verify (permission denial) | `MnemosyneApp(App)`, `BaseScreen(Screen, ErrorHandlerMixin)` may be absent from `document_symbols` | Fall back to `workspace_symbols(query=ClassName)` filtered to file | BUG_DATABASE §11 lines 938-946 |
| **B-0057** (I#40) `lsp_references` start_character sensitivity | Closed per ledger | Pre-fix: char=0 returned empty, char=4 returned 48 hits | Derive `start_character` from chunk header offset, not assume 0 | BUG_DATABASE §11 lines 948-952 |
| **B-0031** (I#20/I#44) `focus_file` small-graph rebias zero-delta | Open (P3) | Bit-identical ranks on small Python corpora (n < 100) | Use multi-anchor focus per NC9, or sub-root scoping to grow the graph | BUG_DATABASE §7 lines 677-686 |

## §4 Language-specific BPMN — the Python polymorphism / MRO flow

```mermaid
flowchart TD
  U[User: "find all _handle_error overrides" or<br/>"audit this mixin chorus"] --> S{Substrate ≥ 4.1.3?}
  S -->|Yes| FS[mcp__ripvec__find_similar<br/>symbol_name=_handle_error]
  S -->|No, pre-4.1.3| FB[Fall back to<br/>lsp_workspace_symbols<br/>then lsp_references per match]
  FS --> NC{NC1 response shape?}
  NC -->|NC1a: candidates list ≥ 4| MX[**NC2 MRO Proximity Collapse**<br/>candidates = mixin + overrides]
  NC -->|NC1b: results list normal| TC[Topic cluster<br/>semantic neighbors at 0.7-0.9]
  NC -->|NC1c: not in index| M5[String-API signal<br/>route to polyglot-recipes]
  MX --> SG{Refactor or audit?}
  SG -->|Refactor| TS[**NC12 Mixin-Override Telescope**<br/>+ find_duplicates threshold=0.85]
  SG -->|Audit Liskov violations| M8[**M8 detector**<br/>read each override; sim-band variance<br/>= behavioral divergence]
  TS --> RR[Delete nearest, parameterize farthest,<br/>keep canonical]
  M8 --> RR2[Report violations; route to ripvec:refactorer]
  TC --> DOC{Is it a how-does-X question?}
  DOC -->|Yes| F3[**F3 Theory-First Prose Probe**<br/>search corpus=docs rerank=always]
  DOC -->|No| RT[Continue with structural analysis]
```

## §3.1 NB: Naming-convention note

Python's *prose-grade docstring discipline* (Naur theory-building made
textual) is what allows F3 + M7 + M14 to compose so well. On
docstring-thin Python (industrial scripts, generated code), the
prose-probe step becomes a search miss — degrade gracefully to
structural recipes.

## §5 Cross-corpus calibration

Python is exercised by the **flask ↔ mnemosyne dipole** (per M19,
Part XI §XI.4 lines 3164-3181):

- **flask** — pristine framework, ~50 files. Minimum-sufficiency
  Python sentinel (M13 entry). Diagnoses regression-class bugs
  (does the clean case still work?); cannot surface I#57 truncation
  or fn-ptr dispatch. F2 deliberate duplication is its canonical
  signal (Scaffold/Flask triple).
- **mnemosyne** — Python large app with Textual mixin idioms.
  Polymorphism / MRO oracle (M13 entry). Surfaces M8 Liskov-
  violation detector, NC2 MRO Proximity Collapse, NC12 Mixin-
  Override Telescope, NC3 Focused-Map Polarity Reversal.
- **Note:** mnemosyne was rotated out of the Wave 5 lane set (per
  the corpus-rotation discipline in
  `docs/CONSTITUTIONAL_CYCLE_OF_ETERNAL_IMPROVEMENT.md`) but
  remains the canonical Python large-app diagnostic per M13's
  "class coverage" criterion.
- **Diagnostic rule:** a Python bug reproducing on BOTH flask and
  mnemosyne is **Python-general**; bugs only on mnemosyne are
  framework-idiom-specific (Textual mixin-shape).

## §6 Heritage citations

Python's earned heritage from cross-corpus campaigns (verbatim from
Part VII-XI bibliographies):

- **Naur, P.** *Programming as Theory Building* (1985) — the
  program's theory lives partially in prose, fully in maintainers.
  Python's docstring discipline elevates prose into the indexing
  primitive (per M14, M7). **Load-bearing Python anchor.**
- **Liskov, B.** *Data Abstraction and Hierarchy* (1987) — the
  substitution principle as a behavioral contract. Python mixins
  are exactly where it is violated *quietly* (M8). **NC2 + M8
  anchor.**
- **Knuth, D.** *Literate Programming* (1984) — prose and code as
  one artifact, encoded at the file-format layer. Heritage for M14
  (chunk-with-docstring contract) and H3b (codebase docs as
  meta-oracle).
- **Feynman, R.** — "you do not understand something until you can
  explain it without the vocabulary." Heritage for F3 Theory-First
  Prose Probe.
- **Brooks, F.** — surgical team / reader-narrator framing for F2.5
  Convention-Duplicated Override (mnemosyne ARCHITECTURE.md as the
  prose oracle).
- **Polya, G.** — *the codebase is its own oracle*; varying the
  problem by changing the corpus IS the test (M13).
- **Box, G.** *all models are wrong, some are useful* — heritage for
  P9 inheritance-depth signal as a useful approximation of an MRO
  walk ripvec can't (yet) do directly.
- **Quine, W.V.O.** — use-mention distinction (M12); applies to
  Python where the rendered `def_callees` and the analytic
  `compute_dead_code` must read different fields.
