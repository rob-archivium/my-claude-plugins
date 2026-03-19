---
name: profile-typescript
description: >
  Profile TypeScript and Node.js applications using --cpu-prof, Chrome DevTools, or 0x,
  then import into tracemeld for analysis. Use when profiling Node.js, finding JavaScript
  or TypeScript performance bottlenecks, or analyzing a V8 CPU profile.
---

# Profile TypeScript / Node.js Applications

Guide the user through profiling a Node.js or TypeScript application, importing the profile into tracemeld, and analyzing the results.

## Step 1: Choose a Profiling Tool

### Option A: Node.js --cpu-prof (Recommended — zero dependencies)

Node.js has built-in V8 CPU profiling. This produces a `.cpuprofile` file in Chrome trace format.

```bash
# Profile a script
node --cpu-prof --cpu-prof-interval=100 script.js

# Profile a TypeScript file with tsx
npx tsx --cpu-prof --cpu-prof-interval=100 script.ts

# Profile with ts-node
node --cpu-prof --cpu-prof-interval=100 -r ts-node/register script.ts

# The output file is CPU.${pid}.cpuprofile in the current directory
# Control output directory:
node --cpu-prof --cpu-prof-dir=./profiles script.js

# Profile a specific duration (e.g., a server handling requests):
# Start the process, send requests, then send SIGINT (Ctrl+C) to stop
node --cpu-prof server.js
```

### Option B: Chrome DevTools (for running servers)

```bash
# Start Node.js with the inspector
node --inspect server.js

# Or with tsx for TypeScript
npx tsx --inspect server.ts

# Then:
# 1. Open chrome://inspect in Chrome
# 2. Click "inspect" on the Node.js target
# 3. Go to the "Performance" tab
# 4. Click "Record", run your workload, click "Stop"
# 5. Click the down arrow → "Save profile..." → saves as .json (Chrome trace format)
```

### Option C: 0x (flamegraph-oriented)

```bash
# Install
npm install -g 0x

# Profile a script (generates a flamegraph and .0x directory with raw data)
0x script.js

# For TypeScript
0x -- npx tsx script.ts

# 0x writes collapsed stacks in the output directory
# Look for: .0x/*/stacks.*.out
```

### Option D: clinicjs (for server workloads)

```bash
# Install
npm install -g clinic

# Profile with autocannon load generation
clinic flame -- node server.js
# This opens a flamegraph in the browser and saves data

# For just the profile data
clinic flame --collect-only -- node server.js
```

## Step 2: Import into tracemeld

After obtaining the profile file, import it:

- **.cpuprofile (from --cpu-prof)**: `import_profile` with source=path, format="auto"
- **.json (from Chrome DevTools)**: `import_profile` with source=path, format="auto"
- **Collapsed stacks (from 0x)**: `import_profile` with source=path, format="auto"

tracemeld auto-detects all V8/Chrome formats.

## Step 3: Analyze

Once imported, run the full analysis workflow:

1. `profile_summary` with group_by="kind" — see headline numbers
2. `bottleneck` with dimension="wall_ms" and top_n=5 — find the most expensive functions
3. `hotpaths` with dimension="wall_ms" — see complete call chains
4. `find_waste` — detect anti-patterns
5. For each bottleneck with a `source` field:
   - Read the source file at the reported line
   - Use LSP `hover` on the function for type info
   - Use LSP `findReferences` to see all call sites

## Common TypeScript / Node.js Performance Patterns

### JSON parsing overhead
`JSON.parse()` and `JSON.stringify()` are frequent hotspots:
- Avoid parsing the same payload multiple times — cache the result
- Use streaming parsers (`JSONStream`, `stream-json`) for large payloads
- Consider `Buffer`-based operations instead of string-based for binary protocols
- Use `structuredClone()` instead of `JSON.parse(JSON.stringify(obj))` for deep cloning

### Async overhead and microtask storms
Excessive `await` in loops creates microtask overhead:
- Use `Promise.all()` for concurrent independent operations
- Batch database queries instead of querying in a loop
- Use `for...of` with a single await instead of `.map()` + `Promise.all()` when ordering matters and you want backpressure

### Regular expression backtracking
Regex with nested quantifiers can cause catastrophic backtracking:
- Look for patterns like `(a+)+`, `(a|b)*c`, or `.*.*`
- Use `re2` package for untrusted input (linear-time matching)
- Prefer specific character classes over `.`

### Memory leaks and GC pressure
Look for `(garbage collector)` or `Scavenge` in the profile:
- Avoid creating objects in hot loops — reuse objects
- Use `WeakMap` / `WeakRef` for caches that should not prevent GC
- Watch for closure captures that retain large objects
- Use `Buffer.allocUnsafe()` instead of `Buffer.alloc()` when you will fill it immediately

### require() / import at startup
Module loading can dominate startup profiles:
- Lazy-load large modules with dynamic `import()`
- Check for unused dependencies being imported
- Use `--conditions` or tree-shaking to reduce module graph size

### Event loop blocking
Synchronous operations (e.g., `fs.readFileSync`, `crypto.pbkdf2Sync`) block the event loop:
- Use async variants (`fs.promises.readFile`, `crypto.pbkdf2`)
- Offload CPU-bound work to worker threads (`worker_threads`)
- Use `setImmediate()` to break up long synchronous computations

### TypeScript-specific patterns
- Excessive type narrowing at runtime (type guards in hot paths) adds overhead
- Decorator metadata emission (`emitDecoratorMetadata`) slows startup
- Source map lookups in error stacks can be expensive in production — disable `--enable-source-maps` in production if not needed
