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
```

### Option A: Automated (recommended for Claude Code / headless)

Use `--save-only` with `--unstable-presymbolicate` to save a profile with a symbol sidecar file. tracemeld reads both files and resolves symbols automatically — no browser needed.

```bash
# THE EXACT COMMAND — do not omit any flags:
samply record --save-only --unstable-presymbolicate -o /tmp/profile.json.gz ./target/release/my-binary [args...]
```

This produces TWO files:
- `/tmp/profile.json.gz` — the profile (gzip compressed, hex addresses)
- `/tmp/profile.json.gz.syms.json` — the symbol sidecar (function names, file paths, line numbers)

**BOTH files must exist at the same path.** tracemeld auto-detects the sidecar and resolves addresses during import.

**CRITICAL: You MUST include `--unstable-presymbolicate`.** Without it, only the .json.gz is produced with no symbol info, and you get hex addresses like `0x44f8` instead of function names.

```bash
# For benchmarks:
samply record --save-only --unstable-presymbolicate -o /tmp/bench.json.gz -- cargo bench --bench my_bench

# For tests:
samply record --save-only --unstable-presymbolicate -o /tmp/test.json.gz -- cargo test --release -- --nocapture specific_test
```

**If the sidecar has `"data":[]` (empty symbols):** The issue is missing debug info. Verify `debug = true` in Cargo.toml, rebuild, and re-record. On macOS, you may also need to run `dsymutil target/release/my-binary` before profiling to generate the .dSYM bundle.

## Step 3: Import into tracemeld

```
import_profile with source="/tmp/profile.json.gz" format="gecko"
```

tracemeld automatically:
- Decompresses gzip
- Detects and loads the `.syms.json` sidecar if present (same path + `.syms.json`)
- Resolves hex addresses to function names using the sidecar

You should see lanes (one per thread), frames with resolved function names, and samples.

**If you see hex addresses instead of function names**, check in order:
1. Does the `.syms.json` sidecar file exist? (`ls /tmp/profile.json.gz.syms.json`) — if not, re-record with `--unstable-presymbolicate`
2. Is the sidecar non-empty? (`cat /tmp/profile.json.gz.syms.json`) — if `"data":[]`, samply couldn't find debug info
3. Is `debug = true` in Cargo.toml? Without it, there's no debug info for samply to read
4. Was the binary stripped? Check for `strip = true` in Cargo.toml

## Step 4: Analyze

Once the profile is imported, use the **analyze-profile** skill for the full analysis workflow. It covers:
- `profile_summary` → `bottleneck` → `hotpaths` → `find_waste` → `spinpaths` → `starvations`
- LSP integration (hover, findReferences, incomingCalls) for source-level investigation
- Synthesis of findings into actionable recommendations

For Rust profiles, use rust-analyzer as the LSP server. Multi-threaded Rust profiles benefit especially from `starvations` (detecting idle threads while others are busy) and grouping by lane (`profile_summary` with group_by="lane").

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
