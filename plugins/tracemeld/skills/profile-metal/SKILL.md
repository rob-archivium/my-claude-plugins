---
name: profile-metal
description: >
  Profile Metal, MPS, and MLX GPU workloads on Apple Silicon using
  xctrace and Metal System Trace. Record GPU execution timelines,
  then import and analyze with tracemeld. Use when profiling Metal
  shaders, MPS kernels, MLX operations, Apple GPU performance, or
  xctrace traces.
---

# Profile Metal / MPS / MLX on Apple Silicon

## Prerequisites

- **macOS** with Apple Silicon (M1/M2/M3/M4) or AMD GPU
- **Xcode Command Line Tools** (`xcode-select --install`)
- Verify: `xcrun xctrace list templates | grep Metal`
  - Should show "Metal System Trace"

## Step 1: Build for Profiling

Release builds with debug symbols and frame pointers for symbolicated backtraces.

**Rust:**
```toml
# Cargo.toml
[profile.release]
debug = true
```
```bash
RUSTFLAGS="-C force-frame-pointers=yes" cargo build --release
dsymutil ./target/release/my-binary
```

**C/C++ (CMake):**
```bash
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
```

**Swift:**
```bash
swift build -c release -Xswiftc -g
```

## Step 2: Record a Metal System Trace

```bash
xcrun xctrace record \
  --template 'Metal System Trace' \
  --output ./my_trace.trace \
  --time-limit 30s \
  --no-prompt \
  --env MTL_CAPTURE_ENABLED=1 \
  --target-stdout /dev/null \
  --launch -- ./target/release/my-binary [args...]
```

Key flags:

| Flag | Purpose |
|------|---------|
| `--template 'Metal System Trace'` | Captures GPU hardware, driver, and Metal API events |
| `--time-limit 30s` | Auto-stop after duration (safety net for automation) |
| `--no-prompt` | Skip privacy dialogs — required for headless/CI use |
| `--env MTL_CAPTURE_ENABLED=1` | Enable Metal capture layer |
| `--launch -- cmd` | Profile this binary (must be last flag) |
| `--attach pid` | Attach to running process (alternative to --launch) |

For long-running workloads, use `--attach <pid>` with `--time-limit` instead of `--launch`.

### Profiling with cargo-instruments (Rust shortcut)

```bash
cargo install cargo-instruments
cargo instruments -t "Metal System Trace" --release --open
```

This builds, signs, profiles, and opens the result in Instruments. The `.trace` file is in `target/instruments/`.

## Step 3: Import into tracemeld

```
import_profile with source="my_trace.trace" format="xctrace"
```

tracemeld automatically:
1. Runs `xctrace export --toc` to discover available schemas
2. Exports `metal-gpu-intervals`, `metal-driver-event-intervals`, and `os-signpost-interval`
3. Parses the XML, resolves id/ref deduplication, converts nanosecond timestamps
4. Creates lanes split by GPU stage

### What gets imported

| Lane | Frame prefix | What it represents |
|------|-------------|-------------------|
| `gpu-compute` | `gpu-compute:` | Compute encoder execution (MPS kernels, MLX kernels, custom compute shaders) |
| `gpu-vertex` | `gpu-vertex:` | Vertex processing and tiling (Apple Silicon TBDR architecture) |
| `gpu-fragment` | `gpu-fragment:` | Fragment/pixel shader execution |
| `gpu-other` | `gpu-other:` | Blit encoders, other GPU work |
| `driver` | `driver:` | Metal driver events (command buffer processing, shader compilation, wire memory) |
| `signpost` | `signpost:` | os_signpost intervals (custom markers you inserted) |

## Step 4: Analyze

### 4a. Get the big picture

```
profile_summary with group_by="kind"
```

Look at `pct_of_total` for `wall_ms`:

| Dominant lane | What it means | Next step |
|---------------|---------------|-----------|
| `gpu-compute` > 70% | Compute-bound — shaders or ML kernels are the bottleneck | `bottleneck with dimension="wall_ms"` |
| `driver` > 30% | Driver overhead — shader compilation, command buffer processing | Look for `driver:Shader Compilation` spans |
| `gpu-vertex` + `gpu-fragment` balanced | Render-bound — typical graphics workload | Split analysis by stage |
| `gpu-compute` ~= `driver` | Submission-limited — CPU can't feed the GPU fast enough | Check command buffer submission latency |

### 4b. Find bottlenecks

```
bottleneck with dimension="wall_ms"
```

### 4c. Drill into expensive operations

```
explain_span with span_id="<from hotspots>"
```

### 4d. Trace call chains

```
hotpaths with dimension="wall_ms"
```

### 4e. Check for GPU starvation

```
starvations
```

In Metal profiles:
- **`gpu-compute` idle while `driver` active**: GPU starvation — the driver is spending too long processing command buffers
- **Gaps in `gpu-compute`**: Look at timestamps — gaps often correspond to shader compilation (cold pipeline state cache) or command buffer boundaries
- **`driver:Shader Compilation` during steady state**: Pipeline state cache miss — pre-compile shader pipelines during loading

### 4f. Aggregate a specific operation

```
focus_function with function_name="gpu-compute:<operation name>"
```

## Framework-Specific Guidance

### Metal Performance Shaders (MPS)

MPS operations dispatch through standard Metal compute encoders. They appear in traces as compute intervals — there is no dedicated MPS schema.

**Label your command buffers** — this is the single most impactful thing for trace readability:

```swift
commandBuffer.label = "MPS: Batch MatMul 512x512"
mpsKernel.encode(commandBuffer: commandBuffer, ...)
commandBuffer.commit()
```

```rust
// objc2-metal
command_buffer.setLabel(ns_string!("MPS: Conv2D 3x3"));
```

These labels propagate through every trace track and appear in the `label` field of imported spans.

**One MPS operation = multiple compute dispatches.** An `MPSMatrixMultiplication` may decompose into several passes visible as separate compute intervals on the GPU timeline. Aggregate with `focus_function` to see total cost.

### MLX

MLX uses hand-optimized Metal compute kernels (gemm, softmax, rms_norm, sdpa), not MPS. They appear as compute encoder intervals.

**Critical: lazy evaluation.** All MLX operations are lazily evaluated. GPU work only happens when `mx.eval()` is called. Your trace must span `mx.eval()` calls:

```python
import mlx.core as mx

# This does NO GPU work:
c = mx.matmul(a, b)

# This dispatches to GPU:
mx.eval(c)
```

**Debug labels:** Build MLX with `MLX_METAL_DEBUG=ON` for descriptive labels on Metal objects.

**Compiled vs uncompiled:** `mx.compile()` fuses operations. A compiled model produces very different trace profiles than an uncompiled one — fewer, larger compute dispatches vs many small ones.

**Built-in GPU capture (alternative to xctrace):**
```python
# Requires MTL_CAPTURE_ENABLED=1
mx.metal.start_capture("mlx_trace.gputrace")
mx.eval(mx.matmul(a, b))
mx.metal.stop_capture()
```

This produces a `.gputrace` bundle openable in Xcode's Metal Debugger (not importable by tracemeld, but useful for shader-level debugging).

### Rust + Metal (objc2-metal)

Add os_signpost markers to correlate CPU and GPU timelines:

```toml
[dependencies]
signpost = "0.1"
```

```rust
use signpost::{OsLog, const_poi_logger};

static GPU_LOGGER: OsLog = const_poi_logger!("com.myapp.gpu");

fn dispatch_compute() {
    let _interval = signpost::begin_interval!(GPU_LOGGER, 1, "Compute Dispatch");
    command_buffer.set_label(ns_string!("MyCompute"));
    // encode work...
    command_buffer.commit();
}
```

These intervals appear in the `signpost` lane and export via `os-signpost-interval`. Use `OS_LOG_CATEGORY_POINTS_OF_INTEREST` (the default for `const_poi_logger!`) for always-on markers.

## Interpreting Results

### Shader compilation stalls

`driver:Shader Compilation` spans during steady-state execution (not during loading) indicate pipeline state cache misses. The GPU idles while the driver compiles.

**Fix:** Pre-compile all pipeline states during app/test initialization. In Metal:
```swift
// Pre-warm pipeline cache
let descriptor = MTLRenderPipelineDescriptor()
// ... configure ...
try device.makeRenderPipelineState(descriptor: descriptor)
```

### Command buffer submission latency

Compare `driver:` span timestamps with `gpu-compute:` span timestamps for the same command buffer. A large gap between driver processing end and GPU execution start means the command buffer queue is deep (good — GPU stays fed) or the driver is slow (bad — look for shader compilation or memory pressure).

### GPU stage balance (graphics workloads)

For rendering workloads, compare time in `gpu-vertex` vs `gpu-fragment`:
- **Vertex-heavy**: Geometry-bound — reduce polygon count, use LOD, simplify vertex shaders
- **Fragment-heavy**: Fill-rate bound — reduce overdraw, simplify fragment shaders, use early-Z
- **Balanced**: Throughput-limited — check the Top Performance Limiter track in Instruments for ALU vs texture vs bandwidth

### Compute kernel optimization (MPS/MLX)

For compute-dominated profiles:
- Many short compute intervals (< 0.1ms each): Kernel launch overhead may dominate. Fuse operations where possible.
- Few long compute intervals: Good batching. Look at individual kernel efficiency via Instruments' GPU counters.
- Gaps between compute intervals: Command buffer boundaries or synchronization. Reduce commit frequency.
