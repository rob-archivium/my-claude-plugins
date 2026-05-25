---
name: jvm-recipes
description: >
  Use when working with JVM-language code (Java, Kotlin, Groovy, Spring
  Boot). Triggers on: "Spring DI", "find all @Autowired", "@Component
  bean wiring", "Kotlin coroutine flow", "@RestController endpoints",
  "JVM dead code", "spring-boot orientation", "Java annotation impact",
  "Liskov substitution audit", "Gradle build script analysis", "find
  bean factories". Specializes the hub skills for JVM idioms —
  annotation-as-first-class-symbol (M-J-1), container-bound reachability
  (M-J-2), phase-disjoint substrate (M-J-3).
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
  escalate_to: ripvec:codebase-teacher
---

# jvm-recipes — JVM (Java / Kotlin / Spring) as ripvec sees it

Be brief. Cite `docs/AGENTIC_PATTERNS_4_0.md` Part XI §XI.4 M-J-1 / M-J-2 / M-J-3
(JVM-specific principles) and Part X §X.6 (spring-boot calibration).
**spring-boot is the M14 DI-saturated sentinel** — Cycle 9 B-0009 closed
JVM entry-point detection (live=0→29,941, dead=1.0→0.768, conf=Low→HIGH).
The JVM ecosystem is the canonical *annotation-driven, container-bound,
phase-disjoint* corpus.

## §0 Graph position

Specializes the five hub orientations for JVM. Triage
(`ripvec:ripvec-orientation` → `ripvec:intent-routing`) routes here
when `.java`, `.kt`, `.groovy`, or `application.{yml,properties}`
dominant. JVM work most often escalates to `ripvec:codebase-teacher`
because Spring's annotation density makes T13/T14 onboarding tours
unusually effective — the framework *teaches itself* through
annotations once you can read them.

## §1 Language character

What ripvec sees on a JVM corpus:

- **Annotations ARE the API.** Spring `@Component`, `@Service`,
  `@RestController`, `@Autowired`, `@Inject`, `@QuarkusMain`,
  `@MicronautApplication` — these are *static type information
  surfaced as code* (Cardelli/Reynolds manifest types). A static
  analyzer that ignores them indexes a strict subset of program
  meaning. **M-J-1 anchor.**
- **Container-bound reachability.** Spring's `ApplicationContext`,
  Guice's `Injector`, Dagger's component graphs — beans are wired
  at *runtime* by the DI container. The static call graph is
  necessary but not sufficient. M1 LBB (Late-Binding Budget) at
  *categorical maximum* on DI-heavy corpora. **M-J-2 anchor.**
- **Phase-disjoint substrate.** Build-phase code (`build.gradle.kts`,
  `pom.xml` plugins, annotation processors) vs runtime-phase code
  (services, controllers) are *different code*. Conflating them
  produces wrong oracles. **M-J-3 anchor (Bracha mixins).**
- **Kotlin uniformity surprise:** Kotlin `suspend fun`, backtick-
  quoted test names, `.kts` Gradle DSL all parse cleanly through
  ripvec's tree-sitter-kotlin. The Java↔Kotlin polyglot mix does
  NOT degrade chunk quality (Wave 6 opus/spring-boot finding,
  Part XI §XI.6 line 3274).
- **JUnit 4/5 mixed-runner reality.** Test detection: `@Test`,
  `@ParameterizedTest`, `@RepeatedTest`, `@TestFactory`, `@Nested`,
  Kotlin `@TestInstance(Lifecycle.PER_CLASS)`. Spring Boot's
  `@SpringBootTest` is a *framework-dispatched* entry, not a
  pure test.
- **M14 status:** spring-boot is the *DI-saturated JVM polyglot*
  M14 sentinel (Part X §X.6 — was 100%-false-positive pre-Cycle-9,
  now operational baseline post-B-0009).

## §2 Working recipes (JVM earned its keep on these)

| Recipe | Trigger | Tool sequence | Caveat | Cite |
|---|---|---|---|---|
| **Annotation Constellation Map** | "Find all @Component beans" | `mcp__ripvec__lsp_workspace_symbols(query="@Component", root=src/main)` then `lsp_references` per hit | Annotation-uses indexed since Cycle 9 B-0009; pre-fix returned empty | M-J-1, Part XI §XI.4 |
| **Spring Bean Wiring Trace** | "What gets injected here?" | `mcp__ripvec__lsp_hover(location of @Autowired field)` → type → `lsp_workspace_symbols(query=Type, kind=5)` → all @Component implementing | Spring's contextual rules (`@Primary`, `@Qualifier`) require reading nearby annotations to disambiguate | M-J-2 |
| **JVM Entry-Point Audit** | "What can actually start this app?" | `mcp__ripvec__find_dead_code(root=., summary_only=true)` → check `entry_points_detected` for "X main", "Y framework-dispatched (Spring)", "Z tests" | Post-B-0009 detector: Spring main, @SpringBootApplication, @Test, public static void main, @SpringBootTest framework-dispatched | B-0009 closed Cycle 9 |
| **T14 Concept-by-Example via @Component** | "Teach me the service layer" | `mcp__ripvec__find_similar(symbol_name=ExistingService)` returns N similar @Components → `lsp_document_symbols` for outline → narrate | High-value because annotations are the index Spring devs already use mentally | T14 + Bruner enactive-iconic-symbolic |
| **Phase-Disjoint Audit (build.gradle.kts vs src/)** | "Is this Gradle DSL or runtime code?" | Read tree-sitter language tag per chunk; build-files are `groovy`/`kotlin-gradle`; runtime are `kotlin`/`java` | M-J-3: never let build-time fix a runtime bug; never let runtime fix a build bug | M-J-3, Bracha mixins |
| **Liskov Substitution Audit (overridden methods)** | "Does this @Override preserve the contract?" | `mcp__ripvec__lsp_goto_implementation(interface_method)` → per impl `lsp_hover` (contract claim) + `lsp_outgoing_calls` (enactment) | C4 Normalization Contract Audit, JVM variant | C4 Part I §2 |
| **DI Cycle Detection** | "Are these beans in a circular dep?" | `mcp__ripvec__lsp_prepare_call_hierarchy` per @Autowired field-injection site → `lsp_incoming_calls` fixed-point | Spring 6 / Boot 3 throws BeanCurrentlyInCreationException at runtime; static detection beats runtime | T7 Recursive Caller Climb adapted |
| **Kotlin Coroutine Flow Trace** | "Where does this Flow emit?" | `mcp__ripvec__lsp_workspace_symbols(query="emit", kind=12, root=.)` then narrow by enclosing `flow {}` builder | Coroutines are continuation-passing under the hood; outgoing_calls works | M-J-1 + Reynolds CPS |

## §3 Known engine gaps for this language

Per `docs/BUG_DATABASE.md` (verified Cycle 11 W3 / 4.1.9).

| Bug | Status | Symptom | Workaround | Cite |
|---|---|---|---|---|
| **B-0009** JVM entry-point detector absent | **Closed 4.1.6** (Cycle 9 Front A) | Pre-fix: `entry_points: []`, `dead_fraction: 1.0` on every JVM corpus | Verify: spring-boot should show "X main", "Y framework-dispatched (Spring)", "Z tests" | BUG_DATABASE §2 |
| **B-0040** (I#39) Python decorator kind mismatch | Cannot-verify | Likely affects JVM annotation kind too; needs probe | Trust `lsp_workspace_symbols` results; spot-check kinds on annotations | BUG_DATABASE §3 |
| **B-0060** workspace_symbols returns docs + JSON sources | Open (P3) | `lsp_workspace_symbols(query="@Component")` may include `.md` / `.yml` chunks containing the literal text | Filter results by `file_path` extension (`.java` / `.kt` / `.groovy`) | BUG_DATABASE §11 |
| **N3 anti-pattern: annotation-vs-implementation confusion** | Open architectural | Reading the annotation as the implementation; M-J-1 says annotations are *spec* not *enact* | Always pair annotation lookup with implementation lookup via `lsp_goto_definition` | M-J-1 |

## §4 Language-specific BPMN — Spring bean wiring trace flow

```mermaid
flowchart TD
  U[User: "What gets injected here?"<br/>cursor on @Autowired field] --> H[mcp__ripvec__lsp_hover<br/>location of @Autowired field]
  H --> T{Hover returned type?}
  T -->|No| FS[mcp__ripvec__find_similar<br/>symbol_name=fieldName<br/>fallback discovery]
  T -->|Yes, type=Foo| WS[mcp__ripvec__lsp_workspace_symbols<br/>query=Foo, kind=5 class or 11 interface]
  WS --> R{Multiple impls?}
  R -->|Single impl| RES[Single bean — wire is unambiguous]
  R -->|Multiple impls| Q[Check for @Primary or @Qualifier<br/>on the @Autowired site]
  Q --> QF{@Primary / @Qualifier found?}
  QF -->|Yes| QS[Disambiguated to specific @Component]
  QF -->|No| AMB[**Ambiguous wire**<br/>Spring will throw NoUniqueBeanDefinitionException<br/>route to ripvec:bug-detective]
  RES --> CH[Chain into lsp_goto_implementation<br/>for actual bean body]
  QS --> CH
  CH --> LP[Loop: lsp_outgoing_calls on the @Bean method<br/>to surface what THIS bean depends on]
  LP --> FP[Fixed-point until quiescent<br/>= the dependency injection tree]
  FS --> WS
```

## §5 Cross-corpus calibration

JVM is exercised primarily by **spring-boot** (per M19 dipole, the
DI-saturated half; a JVM-pristine corpus is a Cycle 12+ rotation
target):

- **spring-boot** (~8700+ files Java+Kotlin+Groovy+props) — M14
  DI-saturated sentinel. Cycle 9 B-0009 closed entry-point
  detection here (live=0→29,941, dead=1.0→0.768, conf=Low→HIGH).
  Validates `summary_only=true` works at JVM scale.
- **(Cycle 12+ rotation candidate)** smaller pristine JVM: maybe
  jackson-core or kotlinx.serialization for a no-DI JVM dipole partner.
- **Diagnostic rule:** if a finding reproduces on spring-boot AND a
  JVM-pristine corpus, it's M-J-1/2/3 language-general; if on
  spring-boot only, it's DI-container-specific.

## §6 Heritage citations

JVM's earned heritage:

- **Cardelli, L.; Wegner, P.** *On Understanding Types, Data
  Abstraction, and Polymorphism* (1985) — manifest types are *facts
  expressed as code*. Annotations are the JVM's manifest type
  surface. **M-J-1 anchor.**
- **Reynolds, J.** *Types, Abstraction, and Parametric Polymorphism*
  (1983) — annotations as parametric metadata; type-driven dispatch.
- **Gosling, J.** *The Java Language Specification* (1996) — Java's
  design centers on *late binding via interfaces*; the JVM is
  M-J-2's home turf by design intent.
- **Liskov, B.** *Substitutability* (1987) — every @Override is a
  Liskov-substitutability claim. C4 audit anchor for JVM.
- **Goetz, B.** *Java Concurrency in Practice* (2006) — runtime
  concurrency invariants invisible to static analysis; M1 LBB
  practitioner anchor.
- **Bracha, G.** *Pluggable Type Systems* (2004); *Mixins as a
  Mechanism of Multiple Inheritance* — build-time vs runtime as
  phase-disjoint substrates. **M-J-3 anchor.**
- **Brooks, F.** *No Silver Bullet* (1986) — DI containers buy
  late-binding leverage at the cost of static analyzability; M-J-2
  is the tax.
