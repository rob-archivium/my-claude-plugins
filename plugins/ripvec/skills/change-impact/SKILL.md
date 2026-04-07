---
name: change-impact
description: "Use before making significant code changes to understand the blast radius. Triggers on: 'what depends on this', 'what will break if I change', 'show me the impact', 'refactor this safely', 'what uses this module', 'find all callers', 'assess the blast radius'. Use when planning refactors, API changes, module moves, or any change to code that others depend on."
---

# Change Impact Analysis

Before changing a function signature, moving a module, or refactoring an API — understand what depends on it. ripvec provides the full blast radius through its MCP tools and LSP operations.

## The three-tool pattern

**1. Structural dependencies** — what files and functions depend on what you're changing:
```
get_repo_map(focus_file: "src/backend/mod.rs", max_tokens: 1500)
```
Shows callers and callees at the function level — which specific functions call into this module, not just which files import it.

**2. Call hierarchy** — exact callers and callees for the specific function:

ripvec's LSP provides function-level call hierarchy for all 21 supported languages:
```
LSP incomingCalls on the function you're changing → every function that calls it
LSP outgoingCalls on the function → everything it depends on
```
This uses ripvec's definition-level call graph — backed by per-function PageRank, not just text matching.

**3. Symbol references + similar code**:
```
LSP findReferences on the function/trait/struct → every usage site
find_similar(file: "src/backend/metal.rs", line: 42) → parallel implementations
```

## Examples

### Changing a trait method signature (Rust)

You want to add a parameter to `EmbedBackend::embed_batch`:

1. `get_repo_map(focus_file: "src/backend/mod.rs")` → shows 6 files depend on this trait
2. LSP `incomingCalls` on `embed_batch` → shows every function that calls it
3. LSP `findReferences` on `embed_batch` → every usage site including trait bounds
4. `find_similar` on the Metal impl → shows CPU, CUDA impls that all need updating

**Blast radius**: 6 files, ~15 call sites, 3 trait implementations.

### Changing a Terraform resource

You want to modify an S3 bucket configuration:

1. `get_repo_map(focus_file: "modules/storage/main.tf")` → shows which modules reference this
2. LSP `documentSymbol` → lists all resources, data sources, variables in the file (ripvec is the only LSP that provides this for HCL)
3. `search_code("reference to storage module bucket")` → finds all consumers

### Renaming a REST endpoint (TypeScript)

You want to rename `/api/users` to `/api/v2/users`:

1. `get_repo_map(focus_file: "src/routes/users.ts")` → shows which middleware, controllers, and test files connect
2. `search_code("api/users endpoint")` → finds frontend fetch calls, API client wrappers, integration tests
3. LSP `findReferences` on the route handler → exact server-side references

### Moving a Python module

You want to move `utils/auth.py` to `middleware/auth.py`:

1. `get_repo_map(focus_file: "utils/auth.py")` → shows every file that imports from it
2. LSP `incomingCalls` → which functions actually call the auth functions
3. `search_code("authentication decorator usage")` → finds indirect usage through decorators

## The safety checklist

Before any structural change:
- [ ] `get_repo_map(focus_file)` — identify all dependent files and functions
- [ ] LSP `incomingCalls` — exact callers of the function you're changing
- [ ] LSP `findReferences` — all usage sites (including type annotations, not just calls)
- [ ] `find_similar` — identify parallel implementations needing the same change
- [ ] Run tests on the dependency neighborhood, not just the changed file

## When this skill helps most

- Changing public APIs (trait methods, exported functions, REST endpoints)
- Moving or renaming modules/files
- Refactoring shared utilities
- Updating database schemas that models depend on
- Modifying interfaces between frontend and backend
- Changing Terraform module interfaces
