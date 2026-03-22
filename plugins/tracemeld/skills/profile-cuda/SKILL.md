---
name: profile-cuda
description: >
  Profile CUDA GPU workloads from Rust, C++, or Python programs using
  NVIDIA Nsight Systems. Capture kernel execution timelines, memory
  transfers, and NVTX annotations, then import and analyze with tracemeld.
  Use when profiling CUDA code, GPU performance, kernel timing, or nsight.
---

# Profile CUDA GPU Applications

## Prerequisites

- **NVIDIA GPU** with CUDA support
- **CUDA Toolkit** installed (`nvcc --version`)
- **Nsight Systems** installed (`nsys --version`). Bundled with CUDA Toolkit or standalone from NVIDIA's apt repo. **Minimum version: 2024.x.** Older versions (2022.x from Ubuntu repos) have different SQLite schemas and may not export correctly. Install the latest from NVIDIA's repo:
  ```bash
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  sudo apt update
  sudo apt install nsight-systems-2025.6.3  # or latest version from: apt search nsight-systems-
  ```
  The new binary lands at `/opt/nvidia/nsight-systems-<version>/bin/nsys` — add it to PATH or use the full path.

## Step 1: Capture a Profile

### Choose trace flags carefully

```bash
nsys profile --trace=cuda,nvtx -o my_profile ./your_program [args...]
```

The `--trace` flag controls what gets recorded. Always include `cuda`. Add others as needed:

| Flag | What it captures | When to use |
|------|-----------------|-------------|
| `cuda` | Runtime API + GPU kernels + memcpy + memset + sync | **Always** |
| `nvtx` | User annotations (ranges + marks) | When you have NVTX instrumentation |
| `cublas` | cuBLAS API calls | When using GEMM / linear algebra |
| `cudnn` | cuDNN API calls | When using convolutions / neural network layers |
| `osrt` | OS runtime (pthreads, I/O) | When investigating CPU-side overhead |

**Do NOT use `--trace=cuda,nvtx,cublas,cudnn,osrt` blindly.** Each flag increases trace size and overhead. Start with `cuda` only, then add flags when you need to answer specific questions.

### Control capture duration

For long-running programs, limit what you capture:

```bash
# Capture only 5 seconds, starting 2 seconds after launch
nsys profile --trace=cuda,nvtx --duration=5 --delay=2 -o my_profile ./your_program

# Or use NVTX markers to start/stop from code
nsys profile --trace=cuda,nvtx --capture-range=nvtx --nvtx-capture="profile_region" -o my_profile ./your_program
```

### Add NVTX annotations to your code

NVTX **ranges** (push/pop) create spans with duration. NVTX **marks** create instant events. Both are imported by tracemeld.

**Rust:**
```toml
[dependencies]
nvtx = "0.3"
```
```rust
fn train_step() {
    let _range = nvtx::range("train_step");  // span: ends when dropped
    {
        let _fwd = nvtx::range("forward_pass");
        // ... kernels ...
    }
    nvtx::mark("optimizer_step_start");  // instant marker
}
```

**Python (PyTorch):**
```python
with torch.cuda.nvtx.range("forward"):
    output = model(input_tensor)
```

**C++:**
```cpp
#include <nvtx3/nvToolsExt.h>
nvtxRangePushA("forward_pass");
// ... CUDA kernels ...
nvtxRangePop();
```

## Step 2: Export to SQLite

```bash
nsys export --type sqlite my_profile.nsys-rep
```

This creates `my_profile.sqlite`. This is the format tracemeld imports.

**Do NOT use `--type json` or `--type text`.** Only SQLite contains the full CUPTI activity records with correlation IDs that let tracemeld link CPU API calls to their GPU work.

## Step 3: Import into tracemeld

```
import_profile with source="my_profile.sqlite" format="nsight_sqlite"
```

For very large traces (>100k kernel launches), cap the import:
```
import_profile with source="my_profile.sqlite" format="nsight_sqlite" nsight_options={"max_kernels": 50000}
```

### What gets imported

tracemeld creates these lanes and span types from the SQLite export:

| Lane | Span kind prefix | What it represents |
|------|------------------|--------------------|
| `cuda-runtime` | `cuda_api:` | CPU-side CUDA API calls (cuLaunchKernel, cuMemcpy*, cuMemAlloc*, etc.) |
| `cuda-runtime` | `cuda_sync:` | Synchronization events (Context sync, Stream sync, Event sync, Stream wait sync) |
| `gpu-N-kernels` | `kernel:` | GPU kernel executions on device N |
| `gpu-N-memory` | `memcpy:HtoD`, `memcpy:DtoH`, `memset` | GPU memory operations on device N |
| `nvtx` | `nvtx:` | NVTX ranges (spans) and marks (markers) |
| `cublas` | `cublas:` | cuBLAS API calls |
| `cudnn` | `cudnn:` | cuDNN API calls |

**Correlation linkage:** Each `cuda_api:cuLaunchKernel` span becomes the parent of its corresponding `kernel:` span. Same for `cuMemcpy*` → `memcpy:`. This is how tracemeld connects CPU-side launch calls to their GPU-side execution.

### Value dimensions

Each span carries up to 5 value dimensions:

| Dimension | Unit | Available on |
|-----------|------|-------------|
| `wall_ms` | milliseconds | All spans |
| `bytes` | bytes | memcpy, memset |
| `threads` | count | kernels (gridX*Y*Z * blockX*Y*Z) |
| `shared_mem_bytes` | bytes | kernels (static + dynamic) |
| `registers` | count | kernels (registersPerThread) |

## Step 4: Analyze — The CUDA Analysis Pipeline

CUDA profiling is fundamentally different from CPU profiling. Instead of sampling a single call stack, you have parallel timelines: the CPU issuing commands, the GPU executing them asynchronously, and memory transfers bridging both. The analysis pipeline reflects this.

### 4a. Start with the summary — find the dominant category

```
profile_summary with group_by="kind"
```

Look at the `pct_of_total` for `wall_ms`. The profile falls into one of these patterns:

| Dominant category | What it means | Next step |
|-------------------|---------------|-----------|
| `kernel` > 70% | GPU-compute bound | Hotspots by `wall_ms` to find expensive kernels |
| `cuda_api` > 50% | CPU overhead or sync stalls dominate | Hotspots by `wall_ms` — look for `cuMemcpy*` or `cudaDeviceSynchronize` |
| `memcpy` > 30% | Memory-transfer bound | Hotspots by `bytes` to find large transfers |
| `cuda_sync` > 20% | Over-synchronization | Focus on `cuda_sync:` spans |
| `kernel` ~= `cuda_api` | Mixed — common in real profiles | Analyze both; the API time often hides sync waits |

**The `cuda_api` vs `kernel` split is the most important signal.** In a well-pipelined GPU program, `cuda_api` time should be negligible — the CPU fires kernels asynchronously and moves on. When `cuda_api` approaches or exceeds `kernel` time, the CPU is blocking.

### 4b. Find the top bottlenecks

```
bottleneck with dimension="wall_ms"
```

For CUDA profiles, the results need careful interpretation:

**If the top bottlenecks are `cuda_api:cuMemcpyDtoHAsync*`:** The CPU is blocking on Device→Host copies. Despite the "Async" name, these calls block when:
- The copy is to pageable (non-pinned) host memory
- The stream has pending work that must complete first
- The program immediately reads the destination buffer after the call

**If the top bottlenecks are `cuda_api:cuLaunchKernel`:** Launch overhead is high relative to kernel runtime — too many small kernels. Check with `focus_function` to see average kernel duration.

**If the top bottlenecks are `kernel:*` spans:** The GPU is the real bottleneck. Use `explain_span` on the kernel to see grid/block dimensions, shared memory, and register count.

### 4c. Understand the kernel mix

```
focus_function with function_name="cuda_api:cuLaunchKernel"
```

This shows all kernel types launched as callees, ranked by total cost. It gives you:
- **call_count per kernel** — how many times each kernel launched
- **total_cost per kernel** — aggregate wall time on GPU
- **The full kernel roster** — what the program actually does on the GPU

From the callee list, you can identify:
- Model architecture (attention kernels, GEMM, normalization, activation functions)
- cuBLAS GEMM variants (`ampere_sgemm_*`) — these are the matrix multiplies
- Custom vs library kernels

### 4d. Drill into expensive kernels

For each kernel that appears in bottlenecks or has high aggregate time:

```
explain_span with span_id="<span_id from hotspots>"
```

This reveals the kernel's launch configuration:
- **gridDim** `[X, Y, Z]` — number of thread blocks
- **blockDim** `[X, Y, Z]` — threads per block
- **threads** (product of grid * block) — total thread count
- **registersPerThread** — register pressure indicator
- **shared memory** — dynamic + static shared memory per block
- **parent_id** — links to the `cuda_api:cuLaunchKernel` span that launched it
- **streamId** — which CUDA stream it ran on

Key things to look for:
- **Registers per thread > 128**: Very high register pressure, may limit occupancy
- **Registers per thread < 20 with large grids**: Simple element-wise kernel — candidate for fusion
- **Shared memory > 0**: Kernel uses tiled/collaborative algorithms
- **Only 1 stream used**: No concurrent kernel execution possible

### 4e. Aggregate a specific kernel across all invocations

```
focus_function with function_name="kernel:<kernel_name>"
```

This shows aggregate stats across all invocations. Compare:
- **span_count** vs total kernel count — what fraction of launches is this kernel?
- **total wall_ms** / span_count = average kernel duration
- If avg duration < 10us, the kernel is tiny — candidate for fusion

### 4f. Check for GPU starvation

```
starvations
```

This checks for lanes that are idle while other lanes are active. In CUDA profiles:
- **`gpu-N-memory` idle 99%+**: Normal if the program is compute-bound (most time in kernels)
- **`gpu-N-kernels` idle while `cuda-runtime` active**: GPU starvation — the CPU can't feed kernels fast enough, or sync calls are draining the pipeline
- **Large idle gaps in `gpu-N-kernels`**: Look at the gap timestamps — they usually correspond to `cuMemcpyDtoH` calls where the CPU is blocking and the GPU pipeline drains

### 4g. Examine the DtoH copy pattern

If `cuMemcpyDtoHAsync` dominates (common!):

```
focus_function with function_name="cuda_api:cuMemcpyDtoHAsync_v2"
```

Check:
- **span_count** — how many DtoH copies?
- **self_cost vs total_cost** — self cost is the CPU blocking time; total includes the GPU memcpy child. If self >> child, the CPU is waiting for the GPU pipeline to drain before the copy can even start.
- **callees** → `memcpy:DtoH` total bytes — is the data volume large, or is it small copies that are slow due to sync?

Then use `explain_span` on the most expensive instance to see the bytes transferred and the timing gap between the CPU call start and the GPU copy start.

### 4h. Detect anti-patterns

```
find_waste
```

```
spinpaths
```

In CUDA profiles these may not trigger (they're designed for LLM agent traces), but check anyway — `spinpaths` can detect CPU polling loops that should be event-driven.

## Reasoning About CUDA Performance

### The CPU-GPU pipeline model

Think of a CUDA program as a producer-consumer pipeline:
- **CPU (producer)**: Enqueues kernel launches, memcpys, and events onto CUDA streams
- **GPU (consumer)**: Dequeues and executes work from the stream queue

When the CPU enqueues faster than the GPU executes, the GPU is fully utilized. When the CPU blocks (sync, DtoH copy, host computation), the GPU pipeline drains and the GPU idles.

**The ideal profile looks like this:**
- `cuda_api:cuLaunchKernel` spans are tiny (< 0.01ms each) — just the enqueue cost
- `kernel:*` spans fill the GPU timeline with no gaps
- `memcpy:HtoD` is overlapped with kernel execution on different streams
- `memcpy:DtoH` happens only at the end, or on a separate stream

**A problematic profile looks like this:**
- `cuda_api:cuMemcpyDtoHAsync` spans are 100-300ms each — the CPU blocks
- Large gaps between kernel bursts on the GPU timeline
- `cuda_sync:Context sync` or `cudaDeviceSynchronize` appearing frequently

### Interpreting kernel duration

Kernel wall time alone doesn't tell you if a kernel is efficient. You need to consider:

1. **Throughput**: bytes processed / wall_ms, or FLOPs / wall_ms
2. **Occupancy proxy**: threads_launched vs max_threads_per_SM * num_SMs
3. **Register pressure**: registersPerThread > 64 starts limiting blocks per SM
4. **Shared memory usage**: high shared mem reduces blocks per SM but may improve data reuse

A kernel taking 3ms that processes 400M elements is very different from one taking 3ms to process 1K elements.

### The DtoH blocking pattern

The most common CUDA bottleneck seen in practice is blocking DtoH copies. In tracemeld output, this looks like:

- `cuda_api:cuMemcpyDtoHAsync_v2` with self_cost = 200-300ms
- Its child `memcpy:DtoH` with cost = 0.01ms and bytes = 192KB

The 200ms self_cost is NOT the copy time — it's the CPU waiting for all previously enqueued GPU work to complete before the copy can start. The GPU was doing useful work during this time, but the CPU was blocked.

**How to confirm:** Compare the DtoH API call start time with the actual memcpy start time (from `explain_span`). A large gap means the CPU was waiting for the GPU pipeline to drain.

**Fixes:**
- Use pinned (page-locked) host memory: `cudaMallocHost` / `cuMemAllocHost`
- Copy on a separate stream that doesn't serialize with compute
- Reduce copy frequency — batch results and copy once
- Move the convergence/check logic to the GPU (reduce kernel) to avoid copying intermediate results
- Use CUDA events to signal completion without blocking the CPU

### Iterative convergence pattern

If DtoH copy durations decrease over time (e.g., 300ms, 300ms, 300ms, 265ms, 167ms, 100ms, 62ms, 47ms, 30ms, 20ms...), the program is:

1. Running a fixed batch of GPU work per iteration
2. Copying a result back to CPU to check convergence
3. Converging — each iteration does less GPU work before the copy

The decreasing times reflect the shrinking GPU pipeline backlog. The first few iterations are dominated by the initial pipeline fill time.

**Fix:** Move the convergence check to the GPU. Launch a small reduction kernel that writes a flag to device memory, then use `cudaMemcpyAsync` + `cudaStreamWaitEvent` to check without blocking the CPU.

### Launch overhead pattern

If `cuLaunchKernel` self_cost is significant and there are thousands of tiny kernels:

```
focus_function with function_name="cuda_api:cuLaunchKernel"
```

Look at the callee list. If many kernels have:
- avg duration < 10us
- registersPerThread < 20 (simple element-wise ops)
- No shared memory

These are candidates for **kernel fusion** — combine multiple element-wise operations into a single kernel. Frameworks like Triton, CUB, or manual fusion can help.

For very high kernel counts (>10k), consider **CUDA Graphs** — record a sequence of launches once, then replay the whole graph with a single API call, eliminating per-launch overhead entirely.

### Multi-stream analysis

Check how many distinct streamIds appear in kernel spans:
- **1 stream**: All kernels execute serially on the GPU. If kernels are small and independent, use multiple streams for concurrency.
- **Multiple streams**: Look for stream wait events (`cuda_sync:Stream wait sync`) to understand the dependency structure.

### cuBLAS GEMM kernel names

If you see `ampere_sgemm_*`, `volta_sgemm_*`, or similar in the kernel list:
- These are auto-tuned cuBLAS GEMM kernels
- The numbers (e.g., `128x64_tn`) encode the tile size and transpose configuration
- `s` = single precision (FP32), `h` = half precision (FP16), `d` = double (FP64)
- If you see `sgemm` everywhere, switching to FP16 (`hgemm`) or using Tensor Cores (via `cublasSetMathMode(CUBLAS_TENSOR_OP_MATH)`) can give 2-8x speedup
- `gemmSN_*` variants are for small-N cases (thin matrices)

## Common Optimization Strategies

### Compute-bound (kernels dominate)
- Reduce precision: FP32 → FP16/BF16 (2x throughput), use Tensor Cores (8x for GEMM)
- Improve memory coalescing: ensure threads in a warp access contiguous memory
- Use shared memory tiling for data reuse patterns
- Increase occupancy: reduce register usage with `__launch_bounds__`

### Memory-transfer bound (memcpy dominates)
- Use pinned host memory (`cudaMallocHost`) for all host↔device transfers
- Overlap transfers with compute using multiple CUDA streams
- Minimize transfer volume — keep data on GPU between operations
- Use Unified Memory with prefetching (`cudaMemPrefetchAsync`) for complex access patterns

### Launch-overhead bound (many tiny kernels)
- Fuse element-wise kernels (scale + mask + softmax → single kernel)
- Use CUDA Graphs to record and replay kernel sequences
- Use persistent kernels that loop internally instead of many short launches
- Batch small independent operations

### Sync-stall bound (DtoH copies or explicit syncs)
- Replace `cudaDeviceSynchronize` with stream-specific `cudaStreamSynchronize`
- Replace DtoH copies for convergence checks with on-device reduction kernels
- Use CUDA events (`cudaEventRecord` + `cudaEventQuery`) for non-blocking completion checks
- Pipeline work across multiple streams so one stream can execute while another syncs
