# Changelog

## 0.2.0

- CUDA GPU profiling: new `nsight_sqlite` import format for NVIDIA Nsight Systems SQLite exports
- New `/profile-cuda` skill — full guide for capturing, exporting, importing, and analyzing CUDA profiles
- 8 CUPTI table handlers: kernels, memcpy, memset, runtime API, sync, NVTX, cuBLAS, cuDNN
- Correlation ID linkage: CPU API calls automatically linked as parents of GPU kernel/memcpy spans
- 5 value dimensions for GPU spans: wall_ms, bytes, threads, shared_mem_bytes, registers
- max_kernels cap and time_range filtering for large traces
- MCP server now uses `tracemeld@latest` (always pulls newest npm version)

## 0.1.0

- Initial release
- 12 MCP tools: trace, mark, profile_summary, hotspots, hotpaths, bottleneck, explain_span, spinpaths, starvations, find_waste, import_profile, export_profile
- 6 language profiling skills: Rust, TypeScript, Python, Go, C/C++, analysis workflow
- 2 commands: /profile, /perf-review
- 1 agent: performance-analyzer
- Supported formats: collapsed stacks, Chrome trace, Gecko Profiler, pprof
