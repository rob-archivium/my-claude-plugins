---
name: profile-rust
description: >
  Profile Rust applications using samply, cargo-flamegraph, or perf, then import
  into tracemeld for analysis. Use when profiling Rust code, finding Rust performance
  bottlenecks, or analyzing a Rust CPU profile.
---

# Profile Rust Applications

Guide the user through profiling a Rust application, importing the profile into tracemeld, and analyzing the results.

## Step 1: Choose a Profiling Tool

### Option A: samply (Recommended — macOS and Linux)

samply is a sampling profiler that outputs Gecko Profiler JSON, which tracemeld imports natively.

```bash
# Install samply
cargo install samply

# Build with debug info (release mode + debug symbols)
cargo build --release

# Profile a binary
samply record ./target/release/my-binary [args...]

# Profile a cargo test
samply record -- cargo test --release -- --nocapture specific_test

# samply opens Firefox Profiler in the browser automatically.
# Save the profile as JSON: click the upload arrow → "Save as file..."
# The saved file will be a .json in Gecko Profiler format.
```

### Option B: cargo-flamegraph (Linux, macOS with dtrace)

```bash
# Install
cargo install flamegraph

# Profile (generates flamegraph.svg and writes perf data)
cargo flamegraph --bin my-binary -- [args...]

# To get collapsed stacks for tracemeld import:
cargo flamegraph --bin my-binary -o /dev/null --cmd "inferno-collapse-perf" -- [args...]

# Or use perf directly and collapse:
perf record -g --call-graph dwarf ./target/release/my-binary [args...]
perf script | inferno-collapse-perf > profile.folded
```

### Option C: perf + inferno (Linux only)

```bash
# Install inferno
cargo install inferno

# Record with perf (dwarf unwinding for accurate Rust stacks)
perf record -g --call-graph dwarf -F 997 ./target/release/my-binary [args...]

# Collapse to folded stacks
perf script | inferno-collapse-perf --all > profile.folded
```

## Step 2: Build Configuration

Ensure your Cargo.toml has debug info enabled for release builds:

```toml
[profile.release]
debug = true                # Full debug info for symbol resolution
# OR
debug = 1                   # Line tables only (smaller binary, still useful)
```

For frame pointers (improves stack accuracy, especially on Linux):

```toml
[profile.release]
debug = true
strip = false
```

And set the environment variable:

```bash
export RUSTFLAGS="-C force-frame-pointers=yes"
cargo build --release
```

## Step 3: Import into tracemeld

After obtaining the profile file, import it:

- **Gecko JSON from samply**: `import_profile` with source=path, format="auto"
- **Collapsed stacks (.folded)**: `import_profile` with source=path, format="auto"
- **pprof (.prof/.pb.gz)**: `import_profile` with source=path, format="auto"

tracemeld auto-detects all of these formats.

## Step 4: Analyze

Once imported, run the full analysis workflow:

1. `profile_summary` with group_by="kind" — see headline numbers and where time is spent
2. `bottleneck` with dimension="wall_ms" and top_n=5 — find the most expensive functions
3. `hotpaths` with dimension="wall_ms" — see complete call chains to the hotspots
4. `find_waste` — detect anti-patterns like retry loops or redundant operations
5. For each bottleneck with a `source` field:
   - Read the source file at the reported line
   - Use LSP `hover` to understand the function signature
   - Use LSP `findReferences` to see all call sites

## Common Rust Performance Patterns

### Allocator pressure
Look for frequent calls to `alloc::alloc`, `__rdl_alloc`, or `malloc`. Common fixes:
- Pre-allocate with `Vec::with_capacity()`
- Use `SmallVec` for small, bounded collections
- Use arena allocators (`bumpalo`) for batch allocations
- Avoid `clone()` in hot loops — use references or `Cow<'_, T>`

### String formatting overhead
`format!()` and `to_string()` allocate. In hot paths:
- Use `write!()` to a reusable buffer
- Use `itoa` / `ryu` for fast number-to-string conversion
- Consider `Cow<'static, str>` for strings that are usually static

### Lock contention
Look for `parking_lot::Mutex::lock` or `std::sync::Mutex::lock` in hotpaths.
- Switch to `RwLock` if reads dominate
- Use `dashmap` or sharded locks for concurrent maps
- Consider lock-free structures (`crossbeam`) for extreme contention

### Iterator overhead
`collect()` allocates. Check if you can:
- Chain iterators instead of collecting intermediate results
- Use `for_each()` instead of `collect()` when you only need side effects
- Use `itertools::process_results` for fallible iterator chains

### Serialization / deserialization
`serde_json::from_str` and `serde_json::to_string` are common hotspots:
- Use `serde_json::from_reader` / `to_writer` to avoid intermediate strings
- Consider `simd-json` for parsing-heavy workloads
- Use `rmp-serde` (MessagePack) or `bincode` if JSON format is not required

### Hash map performance
`HashMap` with the default hasher (SipHash) is DoS-resistant but not fastest:
- Use `rustc_hash::FxHashMap` for non-adversarial data
- Use `ahash::AHashMap` for a good balance of speed and quality
- Check if `BTreeMap` is better for small maps with ordered iteration
