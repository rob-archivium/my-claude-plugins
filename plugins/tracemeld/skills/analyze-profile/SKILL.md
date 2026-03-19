---
name: analyze-profile
description: >
  Guided performance analysis workflow using tracemeld MCP tools and LSP integration.
  Use when the user has already imported a profile or has a tracemeld session and wants
  to analyze it systematically, find bottlenecks, detect waste patterns, or get
  optimization recommendations with source code references.
---

# Analyze a Performance Profile

Systematic analysis workflow using tracemeld MCP tools combined with LSP for source-level insights.

## The Analysis Pipeline

Follow these steps in order. Each step builds on the previous one.

### Step 1: Get the Big Picture

```
profile_summary with group_by="kind"
```

This shows headline numbers grouped by operation type (e.g., file_read, shell, llm_call). Look at:
- **total wall_ms** — how long the session took overall
- **pct_of_total** — which groups dominate the session time
- **count** — how many times each group of operations ran

Identify the dominant group. This is where you focus the rest of the analysis.

### Step 2: Find the Top Bottlenecks

```
bottleneck with dimension="wall_ms", top_n=5
```

Use the dimension that matters most:
- `wall_ms` — total elapsed time (best default for most profiles)
- `cpu_ms` — CPU time only (use for compute-bound analysis)
- `self_ms` — time in this function only, excluding children

Each bottleneck result includes:
- **name** — the function or operation name
- **cost** — how much time it consumed
- **pct** — what percentage of total time
- **source** — file:line where the code lives (if available)
- **call_count** — how many times it was called

### Step 3: Trace the Call Chains

```
hotpaths with dimension="wall_ms"
```

This shows the most expensive call chains from root to leaf. It reveals:
- Which entry points lead to the bottlenecks
- Whether a bottleneck is called from one place or many
- The full context of why an expensive function is being called

### Step 4: Investigate Each Bottleneck with Source + LSP

For each bottleneck that has a `source` field, use this three-step pattern:

**4a. Read the source code**
Read the file at the reported line number (+/- 20 lines for context). Understand what the function does and look for obvious inefficiencies.

**4b. LSP hover for type information**
Use LSP `hover` on the function name at the reported location. This gives you:
- Full type signature (parameter types, return type)
- Documentation comments
- Generic type parameters and their bounds

**4c. LSP references for call frequency**
Use LSP `findReferences` to see every place this function is called. This tells you:
- Is it called from one place or many?
- Could any call sites be eliminated or batched?
- Are there call sites in test code vs production code?

**4d. LSP incoming calls for the call hierarchy**
Use LSP `incomingCalls` to trace the hierarchy of callers. This reveals:
- The chain of decisions that led to calling this expensive function
- Where a caching layer or early-exit could be inserted

### Step 5: Detect Anti-Patterns

```
find_waste
```

tracemeld detects these common waste patterns:
- **Retry loops** — the same operation repeated after failure
- **Redundant reads** — reading the same file multiple times
- **Blind edits** — editing a file without reading it first
- **Sequential I/O** — operations that could be parallelized

### Step 6: Check for Busy-Wait and Starvation

```
spinpaths
```

Look for operations that spent time without producing output — indicators of:
- Polling loops
- Waiting on locks
- Unnecessary blocking

```
starvations
```

For multi-threaded profiles, check for thread starvation:
- Threads waiting on locks held by other threads
- Imbalanced work distribution

## Tool Selection Guide

| Question | Tool | Key Parameters |
|----------|------|----------------|
| Where does time go overall? | `profile_summary` | group_by="kind" |
| What is the single most expensive function? | `bottleneck` | dimension="wall_ms", top_n=1 |
| What are the top N hotspots? | `bottleneck` | dimension, top_n |
| What call chain leads to a hotspot? | `hotpaths` | dimension |
| Why is one specific function slow? | `explain_span` | span_id (from bottleneck results) |
| Are there wasteful patterns? | `find_waste` | (no params) |
| Is anything spinning without progress? | `spinpaths` | (no params) |
| Are threads being starved? | `starvations` | (no params) |
| Import a new profile file | `import_profile` | source, format="auto" |
| Export for external tools | `export_profile` | format, destination |

## The Key Principle

**tracemeld tells you WHAT is slow** — function names, wall-clock costs, call paths, source file locations.

**LSP tells you WHY it is slow and HOW to fix it** — type signatures reveal the data flow, references show all call sites, incoming calls show the full hierarchy.

Always combine both for actionable recommendations:
1. tracemeld identifies the bottleneck and its cost
2. You read the source code at the reported location
3. LSP hover gives you the function's contract (types, docs)
4. LSP references tell you where it is called from
5. You synthesize a recommendation with a specific file:line, explanation, and expected impact

## Example Synthesis

After running the full pipeline, produce findings in this format:

**Bottleneck #1: `parse_config` at src/config.rs:142 (34% of total time)**
- Called 847 times from `handle_request` (src/server.rs:89)
- Re-parses the config file on every request instead of caching
- Fix: Parse once at startup, store in an `Arc<Config>`, pass by reference
- Expected impact: ~30% reduction in total wall time

**Waste detected: Redundant file reads**
- `src/data/schema.json` read 12 times during the session
- Each read takes ~15ms (I/O bound)
- Fix: Cache the parsed schema in memory after the first read
- Expected savings: ~165ms

**Anti-pattern: Sequential I/O in `load_all_modules`**
- 8 module files loaded sequentially at src/loader.rs:56-72
- Each load is independent and could run in parallel
- Fix: Use `tokio::join!` or `rayon::par_iter` to load concurrently
- Expected impact: ~60% reduction in module loading time (from ~400ms to ~160ms)
