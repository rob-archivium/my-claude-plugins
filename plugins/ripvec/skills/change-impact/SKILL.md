---
name: change-impact
description: "Use before making significant code changes to understand the blast radius. Triggers on: 'what depends on this', 'what will break if I change', 'show me the impact', 'refactor this safely', 'what uses this module', 'find all callers', 'assess the blast radius'. Use when planning refactors, API changes, module moves, or any change to code that others depend on."
---

# Change Impact Analysis

Before changing a function signature, moving a module, or refactoring an API — understand what depends on it. The combination of `get_repo_map(focus_file)` + LSP `findReferences` + `find_similar` gives you the full blast radius.

## The three-tool pattern

**1. Structural dependencies** — what files depend on the file you're changing:
```
get_repo_map(focus_file: "src/backend/mod.rs", max_tokens: 1500)
```
Shows callers and callees — every file that imports from this module.

**2. Symbol-level references** — exact call sites for the specific symbol:
```
LSP findReferences on the function/trait/struct you're changing
```
Shows every line of code that uses it — not just imports, but actual usage.

**3. Similar code** — other implementations that follow the same pattern:
```
find_similar(file: "src/backend/metal.rs", line: 42)
```
If you're changing one implementation, find_similar shows others that follow the same pattern and likely need the same change.

## Examples

### Changing a trait method signature (Rust)

You want to add a parameter to `EmbedBackend::embed_batch`:

1. `get_repo_map(focus_file: "src/backend/mod.rs")` → shows 6 files depend on this trait
2. LSP `findReferences` on `embed_batch` → shows every call site
3. `find_similar` on the Metal impl → shows CPU, CUDA impls that all need updating

**Blast radius**: 6 files, ~15 call sites, 3 trait implementations.

### Renaming a REST endpoint (TypeScript)

You want to rename `/api/users` to `/api/v2/users`:

1. `get_repo_map(focus_file: "src/routes/users.ts")` → shows which middleware, controllers, and test files connect
2. `search_code("api/users endpoint")` → finds frontend fetch calls, API client wrappers, integration tests
3. LSP `findReferences` on the route handler → exact server-side references

### Moving a Python module

You want to move `utils/auth.py` to `middleware/auth.py`:

1. `get_repo_map(focus_file: "utils/auth.py")` → shows every file that imports from it
2. `search_code("from utils.auth import")` → finds all import statements
3. `search_code("authentication decorator usage")` → finds indirect usage through decorators

## The safety checklist

Before any structural change:
- [ ] `get_repo_map(focus_file)` — identify all dependent files
- [ ] LSP `findReferences` — count exact usage sites
- [ ] `find_similar` — identify parallel implementations needing the same change
- [ ] Run tests on the dependency neighborhood, not just the changed file

## When this skill helps most

- Changing public APIs (trait methods, exported functions, REST endpoints)
- Moving or renaming modules/files
- Refactoring shared utilities
- Updating database schemas that models depend on
- Modifying interfaces between frontend and backend
