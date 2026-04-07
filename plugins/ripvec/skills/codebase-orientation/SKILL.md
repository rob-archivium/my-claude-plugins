---
name: codebase-orientation
description: "Use when starting work on unfamiliar code, asked about project structure or architecture, exploring how modules connect, or needing to understand a codebase before making changes. Triggers on: 'how does this project work', 'explain the architecture', 'show me the structure', 'where should I start', 'what are the main modules', 'how are things organized'."
---

# Codebase Orientation

When you need to understand how a project is structured — which files are central, what depends on what, where the key abstractions live — use `get_repo_map` before reading individual files.

## Why this matters

Reading files one by one to understand architecture is slow and expensive. A single `get_repo_map` call returns a function-level PageRank overview showing:
- Which files and functions are structurally central (called by many others)
- Key definitions (traits, structs, functions) with signatures
- Call graph flow (who calls whom at the function level)

This replaces 10+ sequential Read operations with one tool call.

## How to orient

**Step 1: Get the structural overview**
```
get_repo_map(max_tokens: 2000)
```
The output ranks files by structural importance. The top files are the architectural spine — read these first.

**Step 2: Zoom into the area you're working on**
```
get_repo_map(focus_file: "src/auth/middleware.ts", max_tokens: 1500)
```
Topic-sensitive PageRank concentrates on the focus file's neighborhood — what it depends on and what depends on it.

**Step 3: Use ripvec's LSP for detailed navigation**

ripvec provides LSP code intelligence for all 21 supported languages. After identifying key files from the repo map:

- `LSP documentSymbol` — get the full symbol outline of a file (functions, classes, methods). Works for ALL languages ripvec supports including bash, HCL, TOML, Ruby, Kotlin, Swift, Scala.
- `LSP goToDefinition` — jump to where a symbol is defined
- `LSP hover` — see scope chain and context for a symbol
- `LSP incomingCalls` / `outgoingCalls` — trace call chains through the function-level graph

## Examples across languages

**Rust monorepo**: "How does the backend trait system work?"
→ `get_repo_map` shows `backend/mod.rs` as high-rank with trait definition, then each backend impl file as callees

**Django project**: "Where do I start understanding this app?"
→ `get_repo_map` shows `urls.py` and `models.py` as most-imported, `views.py` as primary caller — read in that order

**Terraform infrastructure**: "What resources depend on what?"
→ `get_repo_map` shows which `.tf` files are central. `LSP documentSymbol` lists all resource/data/variable blocks per file. ripvec provides this — no other LSP covers HCL.

**React + Express full-stack**: "How does the frontend talk to the backend?"
→ `get_repo_map` reveals the API boundary: `api/routes/index.ts` as the hub, `src/hooks/useApi.ts` as the frontend entry point

## When NOT to use this

- You already know the file you need → just `Read` it
- You need an exact string → use `Grep`
- You need a specific symbol definition → use `LSP goToDefinition`

Orientation is for the "I don't know where to start" moment. Once oriented, switch to precise tools.
