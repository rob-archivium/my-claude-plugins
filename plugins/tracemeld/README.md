# tracemeld

LLM-native performance profiling plugin for Claude Code.

## Installation

```shell
/plugin install tracemeld@my-claude-plugins
```

## What's Included

### MCP Server (12 tools)
Automatically started via `npx -y tracemeld`:
- `trace` / `mark` — Instrument your work
- `profile_summary` — Session overview
- `hotspots` / `hotpaths` / `bottleneck` — Find what's slow
- `explain_span` — Deep-dive into one operation
- `spinpaths` / `starvations` — Detect busy-wait and thread starvation
- `find_waste` — Anti-pattern detection
- `import_profile` / `export_profile` — Load and export profiles

### Skills (7)
- `/profile-rust` — Profile Rust with samply, cargo-flamegraph, perf
- `/profile-typescript` — Profile Node.js with --cpu-prof, Chrome DevTools
- `/profile-python` — Profile Python with py-spy, cProfile
- `/profile-go` — Profile Go with go test -cpuprofile, runtime/pprof
- `/profile-cpp` — Profile C/C++ with perf, samply
- `/profile-cuda` — Profile CUDA GPU workloads with Nsight Systems
- `/analyze-profile` — Guided analysis workflow with LSP integration

### Commands
- `/profile <file>` — Import a profile and run full analysis
- `/perf-review` — Review current session performance

### Agent
- `performance-analyzer` — Specialized agent for performance analysis tasks

## Supported Formats
| Format | Source | Extension |
|--------|--------|-----------|
| Collapsed stacks | perf, flamegraph, inferno | .folded, .txt |
| Chrome trace | Node.js, Chrome DevTools | .json, .cpuprofile |
| Gecko Profiler | samply, Firefox Profiler | .json |
| pprof | Go, Rust, Python | .prof, .pb.gz |
| Nsight Systems SQLite | NVIDIA Nsight Systems | .sqlite |
