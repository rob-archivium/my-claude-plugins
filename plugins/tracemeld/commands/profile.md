---
description: Import a performance profile and run a full bottleneck analysis
argument-hint: <file-path> [dimension]
---

The user wants to analyze a performance profile. Parse $ARGUMENTS:
- First argument: file path to the profile (required)
- Second argument: cost dimension to analyze (optional, defaults to "wall_ms")

## Steps

1. **Import the profile** using the tracemeld MCP `import_profile` tool:
   - source: the file path from arguments
   - format: "auto" (let tracemeld detect the format)
   - Supported formats: pprof, gecko, chrome trace, collapsed stacks, speedscope, Claude Code transcripts (.jsonl)
   - For Claude transcripts: idle time (human between turns) is excluded by default. Use `include_idle: true` if you want to see how slow the human is

2. **Get the overview** using `profile_summary` with group_by="kind"

3. **Find bottlenecks** using `bottleneck` with dimension from arguments (or "wall_ms")
   - Show the top 5 results

4. **For each bottleneck that has a `source` field**:
   - Read the source file at the reported line number
   - Use LSP `hover` on the function to understand its type signature
   - Use LSP `findReferences` to see how many places call it

5. **Find the critical paths** using `hotpaths` with the same dimension

6. **Check for waste** using `find_waste`

7. **Synthesize findings** into:
   - The #1 bottleneck with code-level explanation
   - Top 3 optimization recommendations with file:line references
   - Any detected anti-patterns (retry loops, redundant reads, blind edits)
