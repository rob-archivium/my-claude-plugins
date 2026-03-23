---
name: profile-cpp
description: >
  Profile C and C++ applications using samply, perf, or Instruments, then import into
  tracemeld for analysis. Use when profiling C/C++ code, finding native performance
  bottlenecks, or analyzing a perf or samply profile.
---

# Profile C/C++ Applications

Guide the user through profiling a C or C++ application, importing the profile into tracemeld, and analyzing the results.

## Step 1: Build Configuration

Debug symbols and frame pointers are essential for accurate profiling. Add these flags:

```bash
# GCC / Clang — required flags
CFLAGS="-g -fno-omit-frame-pointer -O2"
CXXFLAGS="-g -fno-omit-frame-pointer -O2"

# For CMake projects
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_C_FLAGS="-fno-omit-frame-pointer" \
      -DCMAKE_CXX_FLAGS="-fno-omit-frame-pointer" \
      ..

# For Meson projects
meson setup build --buildtype=debugoptimized \
      -Dc_args="-fno-omit-frame-pointer" \
      -Dcpp_args="-fno-omit-frame-pointer"

# For Makefile projects — add to your CFLAGS/CXXFLAGS
make CFLAGS="-g -fno-omit-frame-pointer -O2" CXXFLAGS="-g -fno-omit-frame-pointer -O2"
```

Key flags explained:
- `-g` — emit debug info (DWARF) for symbol resolution
- `-fno-omit-frame-pointer` — preserve frame pointers for accurate stack unwinding
- `-O2` — keep optimizations on so the profile reflects production behavior

## Step 2: Choose a Profiling Tool

### Option A: samply (Recommended — macOS and Linux)

samply is a sampling profiler. It saves raw addresses and resolves symbols via a local server that Firefox Profiler queries in the browser.

**Do NOT use `--save-only` or `-o`** — those produce files with hex addresses only, not resolved function names.

```bash
# Install (requires Rust toolchain)
cargo install samply

# Profile a binary — let it open the browser (DO NOT use --save-only)
samply record ./my-binary [args...]

# Profile with elevated privileges (Linux, for kernel stacks)
sudo samply record ./my-binary [args...]

# In Firefox Profiler (browser tab that opens):
#   1. Verify you see function names (not hex addresses)
#   2. Click the upload/share button → "Save as file..."
#   3. Save to e.g. /tmp/profile.json
# The file saved FROM the browser contains resolved symbol names.
# DO NOT close the terminal while saving — samply's symbol server runs there.
```

### Option B: perf + inferno (Linux)

```bash
# Install perf (Ubuntu/Debian)
sudo apt-get install linux-tools-common linux-tools-$(uname -r)

# Install inferno for collapsing
cargo install inferno

# Record with perf — use dwarf unwinding for best C++ stack accuracy
perf record -g --call-graph dwarf -F 997 ./my-binary [args...]

# Or use frame pointers (faster, less overhead, requires -fno-omit-frame-pointer)
perf record -g --call-graph fp -F 997 ./my-binary [args...]

# Collapse to folded stacks for tracemeld
perf script | inferno-collapse-perf --all > profile.folded

# Alternative: use perf's built-in collapse
perf script | stackcollapse-perf.pl > profile.folded
```

### Option C: Instruments (macOS only)

```bash
# Record a time profile with xctrace
xcrun xctrace record --template "Time Profiler" --launch ./my-binary -- [args...]

# The output is a .trace bundle
# Open in Instruments.app, select the Time Profiler track,
# then File → Export → choose "CSV" or copy stack traces manually.
# For tracemeld, collapsed stacks are preferred — see the conversion step below.
```

For automated macOS profiling without Instruments, use samply (Option A).

### Option D: Valgrind / Callgrind (any platform, high overhead)

```bash
# Record with callgrind (very slow — 10-50x overhead)
valgrind --tool=callgrind --callgrind-out-file=callgrind.out ./my-binary [args...]

# Convert to collapsed stacks
# Use gprof2dot + a conversion script, or:
# pip install gprof2dot
gprof2dot -f callgrind callgrind.out | dot -Tsvg -o profile.svg
```

Note: Callgrind captures instruction counts, not wall-clock time. Useful for algorithmic analysis but does not reflect I/O or system-level behavior.

## Step 3: Import into tracemeld

After obtaining the profile file, import it:

- **Gecko JSON from samply**: `import_profile` with source=path, format="auto"
- **Collapsed stacks (.folded from perf + inferno)**: `import_profile` with source=path, format="auto"

tracemeld auto-detects both formats.

## Step 4: Analyze

Once the profile is imported, use the **analyze-profile** skill for the full analysis workflow. It covers:
- `profile_summary` → `bottleneck` → `hotpaths` → `find_waste` → `spinpaths` → `starvations`
- LSP integration (hover, findReferences, incomingCalls) for source-level investigation
- Synthesis of findings into actionable recommendations

For C/C++ profiles, use clangd as the LSP server. The analysis skill's LSP steps work well with clangd for understanding template instantiations, virtual dispatch, and macro expansions.

## Common C/C++ Performance Patterns

### Cache misses and memory layout
Poor cache locality is the most common C/C++ performance issue:
- Use `struct` arrays (SoA) instead of array of structs (AoS) for data-parallel loops
- Align hot data to cache lines (`alignas(64)`)
- Use contiguous containers (`std::vector`) over node-based ones (`std::list`, `std::map`)
- Minimize pointer chasing — flatten tree structures where possible

### Virtual function overhead
Virtual dispatch prevents inlining and branch prediction:
- Use CRTP (Curiously Recurring Template Pattern) for compile-time polymorphism
- Use `std::variant` + `std::visit` instead of class hierarchies for closed type sets
- Mark classes `final` when no further derivation is expected
- Consider devirtualization: if only one implementation exists, the compiler may optimize it

### Memory allocation in hot paths
`malloc`/`new` in tight loops causes allocator contention and fragmentation:
- Pre-allocate buffers and reuse them
- Use arena/bump allocators for batch allocations (`std::pmr` in C++17)
- Use `jemalloc` or `mimalloc` as drop-in replacements for better multi-threaded performance
- Avoid `std::shared_ptr` in hot paths — the atomic reference counting is expensive

### String operations
`std::string` has hidden costs (SSO threshold, heap allocation, copies):
- Use `std::string_view` for non-owning references (C++17)
- Use `absl::StrCat` / `absl::StrAppend` for concatenation (avoids temporaries)
- Reserve capacity: `str.reserve(expected_size)`
- Avoid `std::ostringstream` in hot paths — use `fmt::format` or `std::format` (C++20)

### Lock contention
Look for `pthread_mutex_lock`, `__lll_lock_wait`, or `std::mutex::lock` in profiles:
- Use `std::shared_mutex` (C++17) for read-heavy workloads
- Use lock-free queues (`moodycamel::ConcurrentQueue`) for producer-consumer patterns
- Use thread-local storage (`thread_local`) to reduce sharing
- Partition data to minimize sharing between threads

### Template instantiation bloat
Excessive template instantiation increases code size and instruction cache pressure:
- Use explicit template instantiation to control which specializations are generated
- Factor non-dependent code out of templates
- Use type erasure (`std::function`, `std::any`) when runtime polymorphism is acceptable
- Check binary size with `bloaty` to identify template bloat

### Compiler optimization hints
- Use `__builtin_expect` / `[[likely]]` / `[[unlikely]]` for branch prediction
- Use `__restrict__` to enable alias analysis optimizations
- Use `-march=native` for platform-specific optimizations (SIMD, etc.)
- Profile-guided optimization (PGO): `gcc -fprofile-generate` → run → `gcc -fprofile-use`
