---
description: Run a performance review of the current tracemeld session (after self-instrumenting)
---

The user wants to review the performance of their current session.

## Steps

1. Call `profile_summary` with group_by="kind" to get headline numbers
2. Look at which group has the highest pct_of_total on any dimension
3. Call `bottleneck` on that dimension with top_n=5
4. For each bottleneck with a source field, read the source to understand why it's expensive
5. Call `hotpaths` on the same dimension to see complete call chains
6. Call `find_waste` to identify anti-patterns
7. Call `spinpaths` to check for operations that spent time without producing output
8. Synthesize into:
   - What went well (efficient operations)
   - What was wasteful (with specific anti-patterns and savings estimates)
   - What to do differently next time (concrete recommendations with file:line references where available)
