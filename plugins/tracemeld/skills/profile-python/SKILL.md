---
name: profile-python
description: >
  Profile Python applications using py-spy, cProfile, or scalene, then import into
  tracemeld for analysis. Use when profiling Python code, finding Python performance
  bottlenecks, or analyzing a Python CPU profile.
---

# Profile Python Applications

Guide the user through profiling a Python application, importing the profile into tracemeld, and analyzing the results.

## Step 1: Choose a Profiling Tool

### Option A: py-spy (Recommended — low overhead, no code changes)

py-spy is a sampling profiler that can attach to running processes and outputs multiple formats.

```bash
# Install
pip install py-spy

# Record collapsed stacks (best for tracemeld)
py-spy record --format raw -o profile.folded -- python script.py

# Record speedscope JSON format
py-spy record --format speedscope -o profile.json -- python script.py

# Attach to a running process
py-spy record --format raw -o profile.folded --pid 12345

# Record for a specific duration (seconds)
py-spy record --format raw -o profile.folded --duration 30 -- python script.py

# Include native C extension frames
py-spy record --format raw --native -o profile.folded -- python script.py

# Increase sampling rate (default 100 Hz, max ~1000 Hz)
py-spy record --format raw --rate 997 -o profile.folded -- python script.py

# py-spy may need root on Linux:
sudo py-spy record --format raw -o profile.folded --pid 12345
```

### Option B: cProfile + flameprof (built-in, no install needed)

```bash
# Record with cProfile (built into Python)
python -m cProfile -o profile.prof script.py

# Convert to collapsed stacks with flameprof
pip install flameprof
flameprof --format=collapsed profile.prof > profile.folded

# Or convert with flamegraph.pl
python -m cProfile -o profile.prof script.py
pip install flameprof
flameprof profile.prof > profile.svg  # visual flamegraph
```

### Option C: scalene (CPU + memory + GPU)

```bash
# Install
pip install scalene

# Profile (generates a JSON report)
scalene --json --outfile profile.json script.py

# Profile with reduced overhead
scalene --cpu-only --json --outfile profile.json script.py
```

### Option D: yappi (multi-threaded / async aware)

```bash
# Install
pip install yappi

# Use in code:
# import yappi
# yappi.set_clock_type("wall")  # or "cpu"
# yappi.start()
# ... your code ...
# yappi.stop()
# yappi.get_func_stats().save("profile.prof", type="pstat")
```

## Step 2: Import into tracemeld

After obtaining the profile file, import it:

- **Collapsed stacks (.folded from py-spy --format raw)**: `import_profile` with source=path, format="auto"
- **Speedscope JSON (.json from py-spy --format speedscope)**: `import_profile` with source=path, format="auto"
- **pstat (.prof from cProfile)**: Convert to collapsed stacks first with flameprof, then import

tracemeld auto-detects collapsed stacks and speedscope JSON.

## Step 3: Analyze

Once imported, run the full analysis workflow:

1. `profile_summary` with group_by="kind" — see headline numbers
2. `bottleneck` with dimension="wall_ms" and top_n=5 — find the most expensive functions
3. `hotpaths` with dimension="wall_ms" — see complete call chains
4. `find_waste` — detect anti-patterns
5. For each bottleneck with a `source` field:
   - Read the source file at the reported line
   - Use LSP `hover` on the function for type info (works with pyright/pylsp)
   - Use LSP `findReferences` to see all call sites

## Common Python Performance Patterns

### GIL contention in multi-threaded code
Python's Global Interpreter Lock means only one thread runs Python bytecode at a time:
- Use `multiprocessing` instead of `threading` for CPU-bound work
- Use `concurrent.futures.ProcessPoolExecutor` for parallel computation
- Use `asyncio` for I/O-bound concurrency (no GIL contention for I/O waits)
- Consider `nogil` builds (Python 3.13+ free-threaded mode) for true parallelism

### Unnecessary list creation
List comprehensions and `list()` calls allocate memory:
- Use generator expressions `(x for x in ...)` instead of `[x for x in ...]` when iterating once
- Use `itertools` for chaining, filtering, and slicing without materializing lists
- Avoid `list(range(n))` — use `range(n)` directly in loops

### String concatenation in loops
Repeated `+=` on strings creates O(n^2) behavior:
- Use `"".join(parts)` to concatenate a list of strings
- Use `io.StringIO` for building large strings incrementally
- Use f-strings for formatting (faster than `.format()` or `%`)

### Attribute lookup overhead
Python resolves attributes at runtime via dictionary lookup:
- Cache attribute lookups in local variables in tight loops: `append = my_list.append`
- Use `__slots__` on classes to avoid per-instance `__dict__`
- Use `@functools.lru_cache` for expensive pure-function results

### Import time
Module imports can be slow, especially with large dependency trees:
- Use lazy imports: `import module` inside the function that needs it
- Profile startup with `python -X importtime script.py`
- Check for circular imports that cause double initialization

### NumPy / Pandas vectorization
Element-wise Python loops over arrays are extremely slow:
- Use vectorized NumPy operations instead of Python loops
- Use `.apply()` on Pandas only as a last resort — prefer built-in vectorized methods
- Use `numba.jit` for numerical loops that cannot be easily vectorized
- Consider `polars` as a faster alternative to pandas for data processing

### I/O and serialization
`json.loads` / `json.dumps` and `pickle` are common hotspots:
- Use `orjson` or `ujson` for faster JSON parsing (3-10x speedup)
- Use `msgpack` or `protobuf` for binary serialization
- Batch database queries — avoid N+1 query patterns
- Use connection pooling (`sqlalchemy.pool`, `asyncpg.Pool`)

### Regular expressions
Regex compilation is expensive — compile once and reuse:
- Use `re.compile(pattern)` at module level, not inside functions
- Use string methods (`.startswith()`, `.endswith()`, `in`) when possible
- Consider `regex` package for complex patterns (faster than `re` for many cases)
