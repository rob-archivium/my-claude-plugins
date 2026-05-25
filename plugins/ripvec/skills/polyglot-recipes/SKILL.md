---
name: polyglot-recipes
description: >
  Use when a codebase spans multiple languages with cross-language
  semantic references (HCL→Python→SQL, Python→Jinja→JS,
  protobuf→generated-stub callers, OpenAPI→client+server, GraphQL
  schema↔resolvers, Terraform→cloud-resource attribute lookup).
  Triggers on: "HCL terraform_remote_state", "SQL FROM/JOIN edges",
  "polyglot dark matter", "string-API across languages", "find_similar
  returns not in index", "where does this Python variable hit SQL",
  "trace this template variable", "schema-impl drift". Specializes the
  hub skills for *cross-language seams* — M5 dark-matter coefficient,
  M6 oracles-are-typed (Codd/Pearl/Hickey trichotomy), M22 polyglot
  incompleteness cost, NC7/NC13/NC16 spec-oracle drift gradient.
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
    - ripvec:javascript-recipes
  escalate_to: ripvec:drift-auditor
---

# polyglot-recipes — cross-language seams as ripvec sees them

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` Part IX (NC1c, NC8, M5),
Part X (NC16, M22), Part XI §XI.4 (M6 trichotomy) and `BUG_DATABASE.md`
§§4-5 (I#54a/b polyglot edge bugs). **aurora is the M14 polyglot
canonical** (HCL+Python+SQL, validated through 3 cycles); the
constitutional polyglot sentinel.

## §0 Graph position

Specializes the five hub orientations for *cross-language seams*. This
skill fires when no single per-language skill (`c-recipes`,
`python-recipes`, `javascript-recipes`, `jvm-recipes`, `go-recipes`,
`rust-recipes`) captures the task because the *interesting* edges
cross language boundaries. Most often escalates to
`ripvec:drift-auditor` because polyglot dark-matter manifests as
*systemic dead-zone drift* — ripvec can't see the seam, so the seam
silently rots.

## §1 Polyglot character

What ripvec sees on a polyglot corpus:

- **Cross-language string-as-API is everywhere.** HCL outputs become
  Python config values become SQL @{variable_name} interpolations
  become Jinja `{{var}}` becomes the URL the JS fetch() hits. **None
  of these are typed in ripvec's eyes** — every hop is a string.
  M5 anchor.
- **M5 Dark-Matter Coefficient** (NC16): `rg-files(name) /
  index-files(name)`. On aurora, `bucket_name`: 11 files contain the
  string, 1 is in the symbol index. Ratio 11:1 = ripvec is blind to
  10 of the 11 files for this name. **Quantifiable polyglot blindness.**
- **M6 Oracles-Are-Typed (Codd/Pearl/Hickey trichotomy):** every
  cross-language API point fits one of three shapes:
  - **Codd-form:** relational projection (HCL `terraform_remote_state.X.outputs.Y`)
  - **Pearl-form:** intervention/do-operator (Python sets SQL @{var})
  - **Hickey-form:** value/identity (tfvars strings; protobuf bytes)
  - Lensing decision: each oracle form needs a different recipe.
- **NC8 Runtime-Variable-Injection Tracing:** a 4-hop chain
  (env → tfvar → Python config dataclass → SQL template var)
  reproducible by grep-composition even when ripvec can't trace it
  symbolically. Anchor recipe for polyglot detective work.
- **NC1c "not in index" IS the M5 diagnostic.** When
  `find_similar(symbol_name=X)` returns "not in index" but `rg`
  finds X across the corpus, that's a polyglot dark-matter signal.
- **I#54a/b polyglot edge bugs are open.** HCL→HCL via
  `terraform_remote_state` and SQL FROM/JOIN edges are partial-
  resolved via semantic search; full LSP edge resolution is a
  4.2.0+ target. **M22 Polyglot Incompleteness Cost** says: when
  bug deferral lets the dark-matter coefficient grow, productivity
  decays at compound rates.

## §2 Working recipes (polyglot earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **NC16 Polyglot Dark-Matter Probe** | "Quantify how blind ripvec is on this name" | `mcp__ripvec__find_similar(symbol_name=X)` → if "not in index" → cross-language `mcp__ripvec__search(corpus="all", query=X)` → compare hit-counts; ratio = dark-matter coefficient | High ratio (≥5) = serious polyglot blindness; pair with workaround | Part X §X.4 NC16 |
| **NC8 Runtime-Variable-Injection Trace** | "How does this Python config value reach the SQL query?" | Pick variable name (e.g., `athena_silver_schema`); `mcp__ripvec__search(corpus="all", query="athena_silver_schema")` → enumerate hits across HCL/Python/SQL files → narrate the 4-hop chain by file order | Reproducible by name-grep even where ripvec can't trace symbolically; M5 use-case canonical | Part IX §IX.4 NC8 |
| **M6 Codd-form Oracle Probe (HCL remote_state)** | "Where does Terraform module A read from module B's outputs?" | `mcp__ripvec__search(query="terraform_remote_state", root=infrastructure/)` → for each hit, the `.outputs.X` path IS the Codd projection | I#54a partial: search works, `lsp_references` returns silent empty on HCL refs (deferred 4.2.0) | M6, BUG_DATABASE §4 I#54a |
| **M6 Pearl-form Oracle Probe (Python→SQL @{var})** | "Where does this template var get bound?" | Pick `@{var_name}` from SQL → `mcp__ripvec__search(corpus="all", query="var_name")` → look for `variables={var_name: ...}` Python assignment | This IS Pearl's `do(var_name=value)` intervention on the SQL DAG | M6, Part XI §XI.4 |
| **M6 Hickey-form Oracle Probe (typed value/identity)** | "Decomplect this tfvars string from its consumer types" | `mcp__ripvec__search(query="bucket_name")` then `mcp__ripvec__lsp_references` on each site to classify consumer-type (ARN vs S3-URI vs path) | M6 Hickey-form: the value travels typed-free; consumer-types diverge over time = M22 cost manifesting | M6, M22 |
| **NC7 Spec-as-Implementation-Oracle** | "Does the spec doc match the impl?" | `mcp__ripvec__find_similar(symbol_name=fn_in_spec)` against `find_similar(symbol_name=fn_in_impl)` → sim score IS the drift index | Sim 1.0 = spec is impl mirror (rare); sim 0.7-0.9 = healthy drift; sim < 0.5 = stale | Part IX §IX.4 NC7 |
| **NC13 Spec-Oracle Drift Gradient** | "Is the implementation drifting from the spec?" | Run NC7 across N spec/impl pairs; sort by descending sim gap; pairs with gap > 0.3 are the drift hotspots | Quantitative — actionable in PR descriptions ("4 spec/impl drifts above threshold; close before merge") | Part X §X.4 NC13 |
| **M5 Aurora-Style 4-Layer Bridge Audit** | "Audit cross-language data flow end-to-end" | Pick a single variable name; chain HCL→Python→SQL→[Jinja|JS] via `mcp__ripvec__search(corpus="all")` per hop; document which hops ripvec sees (LSP edges) vs which it doesn't (M5 dark matter) | Per-variable; this is the aurora canonical recipe | M5, NC8, Part X §X.4 |

## §3 Known engine gaps for this language family

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0017 / I#54a** HCL `terraform_remote_state` edges | Open (P2) | `lsp_references` on HCL `.outputs.X` returns silent empty; semantic search works | Use `mcp__ripvec__search` instead of `lsp_references` for HCL edges | BUG_DATABASE §4 |
| **B-0018 / I#54b** SQL FROM/JOIN edges | Open (P2) | SQL table references not resolved to schema definitions | Cross-language string search; the M5 dark-matter pattern | BUG_DATABASE §4 |
| **B-0019** HCL `module "X" { source = "../X" }` blocks | Open (P3, subsumed by I#54a) | Module composition edges missing | Workaround via search; treat as I#54a | BUG_DATABASE §4 |
| **B-0020** SQL chunker zero-symbols (per-CREATE granularity) | Partial fix | CREATE TABLE → struct now indexed per-file; per-CREATE granularity still missing | One file = one schema oracle; live with file-level granularity | BUG_DATABASE §4 |
| **B-0021** HCL `locals { }` blocks chunked as single | Open (P3) | Individual local-vars not addressable | Use `mcp__ripvec__search(query="local.X")` | BUG_DATABASE §4 |
| **B-0023** HCL `locals { ... }` collapsed to single chunk | Open (P3) | Same family as B-0021 | Same workaround | BUG_DATABASE §4 |
| **N3 anti-pattern: string-API across languages** | Open architectural | Treating untyped string passing as if typed | Apply M5 + M6 trichotomy; document each oracle's form explicitly | M5, M22 |

## §4 Polyglot-specific BPMN — the M6 Codd-form HCL→Python→SQL trace flow

```mermaid
flowchart TD
  U[User: "How does the silver schema name<br/>get from Terraform to the SQL query?"] --> PV[Pick a variable name<br/>e.g. athena_silver_schema]
  PV --> SA[mcp__ripvec__search<br/>corpus=all, query=athena_silver_schema]
  SA --> CLA{Hits include .tf .py .sql .j2 ?}
  CLA -->|Yes — polyglot trace| EH[Enumerate per file kind]
  CLA -->|HCL only| HCL_only[Single-language;<br/>route to c-recipes / language-specific]
  EH --> HF[For each HCL hit:<br/>read locals{} or output{} or var{} surrounding]
  HF --> PF[For each Python hit:<br/>read read_tfvar / config dataclass / @click.option]
  PF --> SF[For each SQL hit:<br/>read CREATE TABLE / @{var} interpolation / FROM]
  SF --> JF[For each Jinja/.j2 hit:<br/>read {{var}} expansion]
  JF --> CH[Chain narration: HCL output → Python read → SQL @{var} → Jinja {{var}}]
  CH --> DM[Compute M5 dark-matter coefficient<br/>rg-files / index-files ratio]
  DM --> DMR{Ratio ≥ 5?}
  DMR -->|Yes| ALERT[**Polyglot dark matter detected**<br/>route to ripvec:drift-auditor<br/>cite M22 polyglot incompleteness cost]
  DMR -->|No| CLEAN[Trace is clean;<br/>document M6 oracle form per hop]
  HCL_only --> H6[H6 Fill-Graph Dual<br/>combine find_similar+lsp_references<br/>per c-recipes / jvm-recipes appropriate]
```

## §5 Cross-corpus calibration

Polyglot is exercised primarily by **aurora** (canonical IaC polyglot,
per Part X §X.4):

- **aurora** (~few hundred HCL+Python+SQL files) — M14 polyglot
  canonical. M5 dark-matter coefficient measured (`bucket_name`: 11:1).
  NC8 4-hop chain reproducible. NC7 spec-vs-impl drift quantifiable.
- **Cycle 6 Wave 6 / opus/aurora finding:** M22 Polyglot
  Incompleteness Cost — bug deferral on I#54a/b lets the dark-matter
  coefficient grow; aurora's `bucket_name` was 11:1 in Wave 5 → 11:0
  in Wave 6 (the *darkness deepened*, not improved).
- **(Cycle 12+ candidate)** add a second polyglot dipole partner:
  candidate is a Django+PostgreSQL+templates app, or a NestJS app
  with protobuf/graphql.
- **Diagnostic rule:** if a polyglot finding reproduces on aurora
  AND a second polyglot corpus, it's M5/M6 architectural; if on
  aurora only, suspect IaC-specific (HCL chunker, SQL grammar).

## §6 Heritage citations

Polyglot's earned heritage:

- **Codd, E.F.** *A Relational Model of Data* (1970) — HCL
  `terraform_remote_state.X.outputs.Y` is *literally* a relational
  projection (`SELECT outputs.Y FROM remote_state WHERE name=X`).
  **M6 Codd-form anchor.**
- **Pearl, J.** *Causality* (2009) — Python setting SQL @{var} is
  Pearl's `do(var=value)` operator on the SQL DAG: an *intervention*
  not an observation. **M6 Pearl-form anchor.**
- **Hickey, R.** *Simple Made Easy* (2011); *The Value of Values*
  (2012) — typed-free string-as-value flowing across language
  boundaries is *complecting value with identity*. **M6 Hickey-form
  anchor; M22 incompleteness-cost roots here.**
- **Wittgenstein, L.** *Philosophical Investigations* §43 (1953) —
  "the meaning of a word is its use in the language" — polyglot
  strings have meanings determined by their consumer types, not
  their producer. M5 dark-matter is literally Wittgensteinian.
- **Brooks, F.** *No Silver Bullet* (1986) — polyglot architecture
  is *essential* complexity (the cost of right-tool-for-the-job)
  AND *accidental* (the cost of cross-language semantic erosion);
  M22 quantifies the accidental cost.
- **Box, G.E.P.** *All Models Are Wrong* (1976) — the polyglot
  oracle trichotomy (Codd/Pearl/Hickey) is a model not a theorem;
  use it where it earns its keep.
- **Naur, P.** *Programming as Theory Building* (1985) — polyglot
  codebases require *cross-language theory*; the M22 cost is the
  theory-rot tax when ripvec can't see one of the languages
  involved.
