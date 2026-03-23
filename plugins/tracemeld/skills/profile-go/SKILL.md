---
name: profile-go
description: >
  Profile Go applications using go test -cpuprofile, runtime/pprof, or net/http/pprof,
  then import into tracemeld for analysis. Use when profiling Go code, finding Go performance
  bottlenecks, or analyzing a Go pprof profile.
---

# Profile Go Applications

Guide the user through profiling a Go application, importing the pprof profile into tracemeld, and analyzing the results.

## Step 1: Choose a Profiling Method

### Option A: go test -cpuprofile (Recommended for benchmarks)

The simplest way to get a CPU profile for a specific benchmark or test.

```bash
# Profile a specific benchmark
go test -cpuprofile cpu.prof -bench=BenchmarkMyFunc ./pkg/...

# Profile with memory allocations too
go test -cpuprofile cpu.prof -memprofile mem.prof -bench=BenchmarkMyFunc ./pkg/...

# Profile all tests (not just benchmarks)
go test -cpuprofile cpu.prof -run=TestMyFunc ./pkg/...

# Increase benchmark duration for better sampling
go test -cpuprofile cpu.prof -bench=BenchmarkMyFunc -benchtime=10s ./pkg/...

# Quick look with go tool pprof (optional, before importing to tracemeld)
go tool pprof -top cpu.prof
```

### Option B: runtime/pprof (for programs/commands)

Add profiling directly to your main function:

```go
import (
    "os"
    "runtime/pprof"
)

func main() {
    f, _ := os.Create("cpu.prof")
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()

    // ... your program logic ...
}
```

Then build and run normally:

```bash
go build -o myapp .
./myapp
# cpu.prof is written when the program exits
```

### Option C: net/http/pprof (for servers)

Import the pprof HTTP handler in your server:

```go
import _ "net/http/pprof"

// If you already have an HTTP server on :8080, pprof endpoints are auto-registered.
// Otherwise, start a debug server:
go func() {
    http.ListenAndServe("localhost:6060", nil)
}()
```

Then collect a profile while the server handles traffic:

```bash
# Collect a 30-second CPU profile
curl -o cpu.prof "http://localhost:6060/debug/pprof/profile?seconds=30"

# Collect a heap profile (memory)
curl -o heap.prof "http://localhost:6060/debug/pprof/heap"

# Collect a goroutine profile
curl -o goroutine.prof "http://localhost:6060/debug/pprof/goroutine"

# Or use go tool pprof directly
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30
```

### Option D: fgprof (wall-clock profiling)

Standard pprof only captures on-CPU time. `fgprof` captures wall-clock time including I/O waits:

```go
import "github.com/felixge/fgprof"

func main() {
    http.DefaultServeMux.Handle("/debug/fgprof", fgprof.Handler())
    go http.ListenAndServe(":6060", nil)
    // ...
}
```

```bash
# Collect wall-clock profile
curl -o wall.prof "http://localhost:6060/debug/fgprof?seconds=30"
```

## Step 2: Import into tracemeld

All Go profiling tools produce pprof format (.prof / .pb.gz), which tracemeld imports natively:

- **pprof (.prof)**: `import_profile` with source=path, format="auto"

tracemeld auto-detects pprof protobuf format.

## Step 3: Analyze

Once the profile is imported, use the **analyze-profile** skill for the full analysis workflow. It covers:
- `profile_summary` → `bottleneck` → `hotpaths` → `find_waste` → `spinpaths` → `starvations`
- LSP integration (hover, findReferences, incomingCalls) for source-level investigation
- Synthesis of findings into actionable recommendations

For Go profiles, use gopls as the LSP server. The analysis skill's LSP steps (hover for type info, findReferences for call sites, incomingCalls for call hierarchy) all work with gopls.

## Common Go Performance Patterns

### Excessive allocations (GC pressure)
Look for `runtime.mallocgc`, `runtime.gcBgMarkWorker`, or `runtime.scanobject` in the profile:
- Pre-allocate slices: `make([]T, 0, expectedCap)`
- Use `sync.Pool` for frequently allocated/freed objects
- Avoid `fmt.Sprintf` in hot paths — use `strconv.AppendInt` or `[]byte` builders
- Avoid interface boxing in hot loops (causes heap allocation)
- Use `go build -gcflags="-m"` to see escape analysis decisions

### String and byte slice conversions
`string([]byte)` and `[]byte(string)` allocate and copy:
- Use `strings.Builder` for building strings incrementally
- Use `bytes.Buffer` for byte-oriented building
- Pass `[]byte` through your pipeline instead of converting to string
- In Go 1.22+, `unsafe.String` and `unsafe.SliceData` for zero-copy (use with care)

### Map performance
Maps have overhead from hashing and bucket management:
- Pre-size maps: `make(map[K]V, expectedSize)`
- For small maps with integer keys, consider a slice instead
- Avoid maps with pointer keys/values (causes GC scanning overhead)
- Use `sync.Map` only for specific patterns (few writes, many reads from many goroutines)

### Channel and mutex contention
Look for `runtime.chanrecv`, `runtime.chansend`, or `sync.(*Mutex).Lock` in hotpaths:
- Use buffered channels to reduce synchronization points
- Batch items through channels instead of sending one at a time
- Use `sync.RWMutex` if reads vastly outnumber writes
- Consider lock-free alternatives: `atomic.Value`, `atomic.Int64`, etc.

### Goroutine overhead
Creating too many goroutines or goroutine leaks:
- Use worker pools (`errgroup`, channel-based) instead of unbounded goroutine creation
- Use `runtime.NumGoroutine()` to detect leaks
- Use `context.WithCancel` to properly shut down goroutine trees
- Avoid goroutine-per-request patterns for high-throughput servers — use bounded workers

### Reflection overhead
`reflect` package and `interface{}` assertions are slow:
- Use code generation (`go generate`) instead of reflection where possible
- Cache reflected types: `reflect.TypeOf((*T)(nil)).Elem()`
- Use generics (Go 1.18+) to avoid interface{} and type assertions in hot paths

### I/O patterns
- Use `bufio.Reader` / `bufio.Writer` to reduce syscall frequency
- Use `io.Copy` instead of reading into a buffer and writing — it uses `sendfile` when possible
- Batch database queries — avoid N+1 patterns
- Use connection pooling (database/sql does this automatically, but check `MaxOpenConns`)
