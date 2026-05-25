---
name: c-recipes
description: >
  Use when working with C code (kernel or production-grade server) and
  especially when the corpus is fn-ptr-dispatched, macro-saturated, or
  arch-conditionally compiled. Triggers on: "find dead code in this C
  project", "what does this vtable dispatch to", "where is REDIS_OK
  defined", "what calls this driver entry", "kernel mega-cluster",
  "struct file_operations", "robj *createObject", "container_of",
  "where do `.open = fn` assignments go in the call graph", "main()
  not detected as entry". Specializes the hub skills
  (cartographer / detective / refactorer / onboarder / sentinel) for
  C idioms — fn-ptr struct-init tables, preproc macros, and the
  M19 redis ↔ linux diagnostic dipole.
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
    - ripvec:polyglot-recipes
    - ripvec:jvm-recipes
  escalate_to: ripvec:detective
---

# c-recipes — C as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` and `docs/BUG_DATABASE.md`
by Part/§ + line rather than restating. **C is the language where the
M19 diagnostic dipole was discovered** (Part XI §XI.1, lines 2965-2983):
redis (no kernel idioms) isolates language-general bugs; linux (massive
fn-ptr + macro density) amplifies them.

## §0 Graph position

Specializes the five hub orientations for the C family. Triage
(`ripvec:ripvec-orientation` → `ripvec:intent-routing`) routes here
when the codebase is `.c`/`.h`-dominant. C work most often escalates
to `ripvec:detective` because the unique C failure modes (fn-ptr
mega-clusters, macro NC1c silence, `pointer_declarator` symbol
corruption) are diagnostic-shaped, not map-shaped.

## §1 Language character

What ripvec sees on a C corpus:

- **Call graph is a lower bound.** Direct `fn(args)` calls are
  extracted; fn-ptr dispatch via struct-of-fnptr initializers
  (`{ .open = my_open, ... }`) is **invisible** until B-0013 lands
  (§3). On redis, this is the difference between `getCommand`
  reachable vs orphaned; on linux it is the difference between
  every driver `.probe` being live vs the 560K-def mega-cluster.
- **Macro vocabulary is a separate language game.** Per M10
  (Part IX §IX.3, lines 1856-1870) — Wittgenstein/Quine: ripvec
  now ingests `preproc_def` and `preproc_function_def` (B-0015
  closed 4.1.5). `REDIS_OK`, `OBJ_ENCODING_*`, `container_of`,
  `list_for_each_entry` resolve via `find_similar(symbol_name=…)`.
- **Pointer-returning functions used to corrupt as symbols.**
  B-0014 (I#66) is closed 4.1.5 — `robj *createObject(...)` now
  carries `symbol_name="createObject"`, not the next sibling.
- **`main()` is now a seeded entry.** B-0007 (I#73) closed 4.1.4:
  `find_dead_code` recognises `int main()` regardless of
  return-type / param shape. `dead_fraction` still high on redis
  because B-0013 (fn-ptr) dominates.
- **M14 status: redis is the production-grade single-language C
  sentinel** (M18, Part XI §XI.4, lines 3139-3162). linux is the
  kernel-idiom-saturated amplifier. Per the M19 dipole rule, fixes
  must pass BOTH.

## §2 Working recipes (C earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **C-Macro Resolution** | "Where is REDIS_OK defined?" or "What is `container_of`?" | `mcp__ripvec__find_similar(symbol_name="REDIS_OK")` → returns `preproc_def` chunk | NC1c (`not found in index`) no longer fires for `#define` constants since 4.1.5; if it does, you've hit a string-API key not a macro — pivot to grep across `.c`/`.h`/`.md` | Part IX §IX.4 NC1c lines 1942-1948; B-0015 |
| **Vtable Fill-Set Recovery** | "What handlers populate `file_operations`?" / "Which drivers register a `.probe`?" | `mcp__ripvec__find_similar(symbol_name="file_operations")` → NC1a candidate cluster (430+ on linux); intersect with `mcp__ripvec__lsp_references` on the struct name | H6′ dual (Part IX §IX.3, lines 1872-1885); call graph terminates at the indirect jump, fill graph recovers it | Part IX §IX.3 H6′; NC10 lines 2118-2126 |
| **Pointer-Function Symbol Lookup** | "Find `createObject` in redis" | `mcp__ripvec__lsp_workspace_symbols(query="createObject", root=corpus)` → exact-name match at the `*` declarator | Pre-4.1.5 corpora: symbol corrupts to the next sibling; check `preview` field against `symbol_name` to confirm 4.1.5+ substrate | B-0014 (I#66) |
| **Kernel Multi-Anchor Tour (NC9)** | "Orient me in linux at kernel scale" | Three `mcp__ripvec__get_repo_map(focus_file=…)` calls — sched/core.c, mm/page_alloc.c, net/core/dev.c — intersect the top-N lists | Files in all three = kernel spine (`rcupdate.h`, `atomic-instrumented.h`); files unique to one = subsystem-local | Part IX §IX.4 NC9 lines 2106-2117 |
| **Build-Matrix Portability Audit (F4)** | "Where do arch-specific implementations diverge?" | `mcp__ripvec__find_duplicates(threshold=0.85, intra_file=false, root=arch_subdir)` — cluster by `defs_*_amd64.go`-shape file stems (or `arch/x86/`, `arch/arm/`) | Sim 0.85 inside a portability cluster = drift worth investigating; gap in a cluster = missing port | Part VI F4 lines 1159-1194 |
| **Main-Seeded Dead-Code Sweep** | "What dead code in redis?" | `mcp__ripvec__find_dead_code(root=corpus, summary_only=true, min_cluster_size=10, max_clusters=5)` | On corpora dominated by fn-ptr dispatch (redis, every C server), `dead_fraction` is a **lower bound** until B-0013 lands; mega-clusters rooted at `addReplyError`-shaped commands are B-0013 territory, not real dead code | B-0007 closed; B-0013 still open |
| **Confidence-Band-as-Diagnostic (M1)** | "Why is this kernel dead-code report so noisy?" | Read `confidence` field on `find_dead_code` response | `Low` is not surrender — it is the tool refusing to lie. Late-Binding Budget formula (Part X §X.6, lines 2830-2867) quantifies how much dispatch is runtime | M1 Part IX §IX.5 lines 2184-2196 |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0013** (I#55) fn-ptr struct-literal edges | Closed 4.1.5 redis side; **linux next-layer (static-inline macros) Open** | `redisCommandTable[]={...}` and `static const struct file_operations xfs_file_operations={.open=xfs_file_open,...}` produce no synthetic call edges → 5041-def cluster (redis pre-fix), 560K-def mega-cluster (linux) | On affected substrates: use Vtable Fill-Set Recovery recipe (above); on post-fix substrates: verify by `find_dead_code` confidence climbing from Low → Medium | BUG_DATABASE §3 |
| **B-0015** (I#53) macros invisible | Closed 4.1.5 | `find_similar(symbol_name="REDIS_OK")` used to return NC1c | Confirm `preproc_def` kind in response; if absent, you're on pre-4.1.5 substrate | BUG_DATABASE §4 |
| **B-0014** (I#66) `pointer_declarator` | Closed 4.1.5 | `robj *createObject` carried wrong symbol_name | Cross-check `preview` against `symbol_name`; if mismatch persists you're pre-4.1.5 | BUG_DATABASE §4 |
| **B-0007** (I#73) C `int main()` entry | Closed 4.1.4 | `dead_fraction=1.0` on redis pre-fix | Confirm `entry_points_detected` contains `"… main"` | BUG_DATABASE §2 |
| **B-0034/B-0035** (I#61/I#76) kernel OOM | Closed main-context; **subagent transport ceiling persists** | Full-Linux `find_dead_code` from subagents `Connection closed` at 80-90s | Use sub-corpus root (`kernel/sched`, `drivers/net`) — works for subagents per Wave 5 testing; reserve full-root for main context | BUG_DATABASE §8 |
| **MK-1 entry-point gap** | Open (target 4.2.0) | ~10K kernel module-init / fs-register / driver-probe entries not seeded | Augment `find_dead_code` interpretation with knowledge that driver `.probe` chains are fn-ptr-dispatched, not dead | Part XI §XI.5 MK-1 lines 3220-3225 |

## §4 Language-specific BPMN — the C diagnostic flow

```mermaid
flowchart TD
  U[User: "find dead code in C corpus" or<br/>"why is this driver/handler unreachable?"] --> S[Determine corpus class<br/>per M19 dipole]
  S --> SR{redis-shape<br/>or kernel-shape?}
  SR -->|redis: production server,<br/>≤10K files| RD[mcp__ripvec__find_dead_code<br/>summary_only=true<br/>min_cluster_size=10]
  SR -->|kernel: linux/freebsd,<br/>≥50K files| KD[Use sub-corpus root<br/>kernel/sched OR drivers/net<br/>NC9 multi-anchor focus]
  RD --> RC{Top cluster rooted<br/>at command-table fn?}
  RC -->|Yes — addReplyError / getCommand| VF[**Vtable Fill-Set Recovery**<br/>mcp__ripvec__find_similar<br/>symbol_name=command_table_struct]
  RC -->|No — semantically coherent| RR[Real dead code;<br/>route to refactorer]
  KD --> KC[Read confidence band<br/>per M1 LBB formula]
  KC --> KG{Confidence Low AND<br/>cluster > 0.05 × total_defs?}
  KG -->|Yes| MK[I#55 mega-cluster collapse<br/>per MK-3 / MK-4<br/>fn-ptr dispatch invisible]
  KG -->|No| OK[Cluster is real;<br/>route to refactorer]
  VF --> SY[Each candidate is a registered<br/>handler — these are LIVE<br/>via runtime dispatch]
  MK --> ES[Escalate to ripvec:detective<br/>or accept M1 LBB-bounded answer]
```

## §5 Cross-corpus calibration

C is exercised by the **M19 dipole** (Part XI §XI.4, lines 3164-3181):

- **redis** — Sanfilippo design discipline, "no hidden machinery."
  The C-language isolator. Reproduces B-0013 (commandTable),
  B-0014 (`robj *createObject`), B-0015 (REDIS_OK) cleanly without
  kernel-macro fog. Per M18, this is the production-grade
  single-language sentinel.
- **linux** — kernel-idiom amplifier. Reproduces every redis bug AT
  SCALE (560K-def mega-cluster, 63K files) plus the kernel-specific
  MK-1 through MK-6 family. Per M11, age × scale demands stratified
  oracles; per M13, kernel diagnoses what no other corpus can.
- **Diagnostic rule:** a C bug that reproduces on BOTH redis and
  linux is **C-general** and warrants a P1 fix. A bug only on
  linux is **kernel-specific** and routes to the MK-series
  remediation (Part XI §XI.5).

## §6 Heritage citations

The C bibliography earned in cross-corpus campaigns (verbatim from
Part IX §IX.9 and Part XI §XI.9):

- **Lions, J.** *Lions' Commentary on UNIX 6th Edition* (1977) —
  annotate what you can prove; the kernel reads as a textbook only
  because its entry points are textual. **MK-1 anchor.**
- **Cantrill, B.** *Hidden in Plain Sight* (ACM Queue, 2006); DTrace
  OSDI '04 — every kernel callsite is observable at runtime, but
  static analysis loses fn-ptr edges. **MK-2 anchor; M1 LBB.**
- **McKusick, M.** *The Design and Implementation of the FreeBSD
  Operating System* (2014) — VFS layering means interesting call
  edges live in struct-literal initializers. **MK-3 anchor; B-0013
  heritage.**
- **Reynolds, J.** *Definitional Interpreters for Higher-Order
  Programming Languages* (1972) — every late-bound dispatch is
  morally a closure; defunctionalize the table. **MK-4 anchor.**
- **Sanfilippo, S.** *Redis design notes / MANIFESTO* — "no hidden
  machinery" is what makes redis the C-language isolator. **M18
  anchor.**
- **Kernighan & Ritchie** *The C Programming Language* — the
  language whose grammar IS the substrate; what the grammar misses
  (`pointer_declarator`, `preproc_def`) the tool can't read.
  Heritage shared with Pirsig 1974 ("anomaly is data").
- **Polanyi, M.** *The Tacit Dimension* (1966) — the tacit knowledge
  of a kernel hacker is "where the entry points are"; ripvec's job
  is to make it explicit. **MK-6 anchor.**
- **Brooks, F.** *No Silver Bullet* — accidental complexity at
  integration points; the macro layer and fn-ptr tables ARE the
  kernel's accidental complexity worth keeping in rotation. **MK-5.**
