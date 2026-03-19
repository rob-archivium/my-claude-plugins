---
name: profile-rust
description: >
  Profile Rust applications and import into tracemeld for analysis. Use when
  profiling Rust code, finding Rust performance bottlenecks, or analyzing a
  Rust CPU profile. Always use samply — it works on macOS and Linux without
  sudo, produces symbolicated Gecko JSON that tracemeld imports directly.
---

# Profile Rust Applications

## USE SAMPLY. Do not use cargo-flamegraph or dtrace.

**samply is the only profiling tool you should use for Rust.** It:
- Works on macOS and Linux without sudo
- Produces Gecko Profiler JSON that tracemeld imports directly
- Resolves symbols automatically (with debug info enabled)
- Does not clean up intermediate files
- Does not require inferno, perf, or any other tool

**Do NOT use cargo-flamegraph on macOS.** It uses dtrace under the hood, cleans up intermediate files (so you can't get collapsed stacks), only outputs SVG (which tracemeld can't import), and the dtrace commands it wraps require sudo. It is a dead end for tracemeld workflows.

**Do NOT use `perf` on macOS.** perf is Linux-only.

**Do NOT use `sample` or `dtrace` directly.** They produce too few samples and require sudo.

## Step 1: Enable Debug Symbols (CRITICAL)

**Without debug symbols, profiles show hex addresses (`0x44f8`) instead of function names.** This is the #1 issue with Rust profiling.

Add to your `Cargo.toml`:

```toml
[profile.release]
debug = true                # Full debug info — required for symbol resolution
strip = false               # Don't strip symbols from the binary
```

On Linux, also set frame pointers for best stack accuracy:

```bash
export RUSTFLAGS="-C force-frame-pointers=yes"
```

On macOS, frame pointers are enabled by default — `debug = true` is sufficient.

Then build:

```bash
cargo build --release
```

**Verify symbols are present:** `nm target/release/my-binary | head` — you should see function names, not just hex addresses.

## Step 2: Profile with samply

```bash
# Install samply (one-time)
cargo install samply

# Profile a binary — MUST use -o to save to a file
samply record -o /tmp/profile.json ./target/release/my-binary [args...]

# Profile a cargo bench
samply record -o /tmp/bench-profile.json -- cargo bench --bench my_bench

# Profile a cargo test
samply record -o /tmp/test-profile.json -- cargo test --release -- --nocapture specific_test
```

**IMPORTANT: Always use `-o /path/to/output.json`.** Without `-o`, samply opens Firefox Profiler in the browser and you have to manually save. With `-o`, it writes the Gecko JSON file directly.

The output file is gzip-compressed Gecko Profiler JSON. tracemeld handles gzip automatically.

## Step 3: Import into tracemeld

```
import_profile with source="/tmp/profile.json" format="gecko"
```

Or let tracemeld auto-detect:

```
import_profile with source="/tmp/profile.json"
```

You should see lanes (one per thread), frames with resolved function names, and samples.

**If you see hex addresses instead of function names:** Go back to Step 1 — `debug = true` is missing from Cargo.toml, or the binary was stripped.

## Step 4: Analyze (tracemeld tells you WHAT, LSP tells you WHY)

Once imported, run the full analysis workflow:

1. `profile_summary` with group_by="lane" — see which threads are active and where time is spent
2. `bottleneck` with dimension="wall_ms" and top_n=5 — find the most expensive functions
3. `hotpaths` with dimension="wall_ms" — see complete call chains to the hotspots
4. `find_waste` — detect anti-patterns like retry loops or redundant operations
5. `starvations` — check for thread starvation (idle threads while others are busy)
6. For each bottleneck with a `source` field:
   - Read the source file at the reported line
   - Use LSP `hover` to understand the function signature
   - Use LSP `findReferences` to see all call sites
   - Use LSP `incomingCalls` to trace the call hierarchy

## Linux Alternative: perf + inferno

On Linux only (not macOS), you can use perf as an alternative:

```bash
cargo install inferno

RUSTFLAGS="-C force-frame-pointers=yes" cargo build --release

perf record -g --call-graph dwarf -F 997 ./target/release/my-binary [args...]
perf script | inferno-collapse-perf --all > /tmp/profile.folded
```

Then import: `import_profile with source="/tmp/profile.folded" format="collapsed"`

**This is Linux-only. On macOS, use samply.**

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
Look for `parking_lot::Mutex::lock` or `std::sync::Mutex::lock` in hotpaths. Use `starvations` tool to detect.
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
