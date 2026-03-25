---
name: profile-claude
description: >
  Profile Claude Code sessions by importing JSONL transcripts into tracemeld for analysis.
  Use when reviewing Claude Code session efficiency, analyzing token/cost spend, finding
  wasteful tool patterns, or optimizing how Claude Code is used on a project.
---

# Profile Claude Code Sessions

Guide the user through importing a Claude Code session transcript into tracemeld and analyzing LLM turn costs, tool execution time, and workflow anti-patterns.

## Step 1: Find the Transcript

Claude Code writes JSONL transcripts to `~/.claude/projects/`. Each file represents one session.

```bash
# List recent transcripts, newest first
ls -lt ~/.claude/projects/*/*/claude_transcript.jsonl 2>/dev/null | head -10

# Or for the current project specifically
ls -lt ~/.claude/projects/-$(pwd | tr '/' '-')/*.jsonl 2>/dev/null | head -5
```

The path encoding replaces `/` with `-` and prepends `-`, so `/Users/rwaugh/src/myapp` becomes `-Users-rwaugh-src-myapp`.

If the user already has a `.jsonl` path, skip straight to Step 2.

## Step 2: Import into tracemeld

```
import_profile with source=<path>, format="auto"
```

Each import automatically resets previous profile data, so you always get a clean analysis.

tracemeld auto-detects Claude Code JSONL transcripts by looking for `sessionId` and `type` fields.

**Key parameter — `include_idle`:**
- `false` (default) — excludes human think time between turns. This is usually what you want, because you're analyzing what *Claude* did, not how long the human took to type.
- `true` — includes `user_input:*` idle spans. Useful if you want a complete timeline or want to see interaction pacing.

**Pricing defaults** (Claude Opus):
- Input: $15/M tokens, Output: $75/M tokens, Cache reads: $1.50/M tokens
- Override with `input_cost_per_m`, `output_cost_per_m`, `cache_read_cost_per_m` if using a different model

## Step 3: Analyze

Once the profile is imported, follow this Claude-specific analysis pipeline. The **analyze-profile** skill covers the general workflow; this section adds interpretation guidance specific to Claude transcripts.

### Claude-Specific Dimensions

Claude transcript profiles have five dimensions. Token and cost data lives only on `llm_turn` spans; tool spans (Bash, Read, Write, etc.) carry only `wall_ms`.

| Dimension | What it measures | When to use |
|-----------|-----------------|-------------|
| `wall_ms` | Elapsed time per turn/tool | "What took the longest?" |
| `output_tokens` | Generation tokens per turn | "Where did Claude spend the most effort generating?" |
| `input_tokens` | Prompt tokens per turn | "What's driving context size?" |
| `cache_read_tokens` | Cached prompt tokens | "How much prior context is being replayed?" |
| `cost_usd` | Estimated dollar cost per turn | "What's the most expensive part?" |

**Tip:** Always check both `cost_usd` and `output_tokens`. Cost is dominated by cache reads (cheap per-token but high volume), while output tokens show where Claude actually generated the most content. A turn with $0.34 cost but only 735 output tokens means context replay, not generation, is driving the bill.

### Claude-Specific Frame Kinds

The importer creates these frame types from transcript data:

| Frame kind | Example | What it represents |
|------------|---------|-------------------|
| `session:*` | `session:imported` | Root span wrapping the entire session |
| `llm_turn:*` | `llm_turn:req_011CZKMHvvbn` | One LLM request-response cycle (grouped by requestId) |
| `Bash:*` | `Bash:run tests` | Shell command execution |
| `Read:*` | `Read:src/main.ts` | File read |
| `Write:*` | `Write:src/new.ts` | File creation |
| `Edit:*` | `Edit:src/main.ts` | File edit |
| `Grep:*` | `Grep:TODO` | Content search |
| `Glob:*` | `Glob:**/*.ts` | File pattern search |
| `Agent:*` | `Agent:explore codebase` | Subagent launch |
| `TaskCreate:*` | `TaskCreate:implement auth` | Task management |
| `ToolSearch:*` | `ToolSearch:select:mcp_tool` | Deferred tool schema fetch |
| `Skill:*` | `Skill:profile` | Skill invocation |
| `WebSearch:*` | `WebSearch:query` | Web search |
| `LSP:*` | `LSP:hover` | Language server call |
| `mcp__*` | `mcp__tracemeld-local__bottleneck` | MCP tool call |
| `user_input:*` | `user_input:waiting` | Idle time between turns (only with `include_idle: true`) |

### Interpreting Tool Results for Claude Transcripts

Claude transcripts have a flat call structure (session → turn → tools), not the deep call stacks you see in CPU profiles. This changes how each tracemeld tool should be read:

**`profile_summary` with group_by="kind"**
- The `session` group will show 95%+ of `wall_ms` — this is the total session duration and is expected. Focus on the other groups.
- `llm_turn` will show 100% of all token and cost dimensions, since only LLM turns have token data.
- Look at `Agent`, `Bash`, `Write`, `Edit`, `Read` groups for tool execution time breakdown.
- `span_count` per group shows how many operations of each type occurred (e.g., 426 Bash calls, 216 Reads).

**`bottleneck` on wall_ms**
- The `session:imported` root will always be #1 — **skip it** and look at entries #2+.
- Agent spans often dominate because they run full subprocesses. A 6,650s Agent span means a subagent ran for ~2 hours.
- Large `Write` operations may appear (e.g., writing a big file to a slow path).
- Bash spans reflect actual command execution time (test suites, builds).

**`bottleneck` on cost_usd**
- This is the most actionable dimension for Claude transcripts. Each entry is an LLM turn.
- Cost is `(input_tokens × $15/M) + (output_tokens × $75/M) + (cache_read_tokens × $1.50/M)`.
- A turn with $0.34 cost and 192K cache_read_tokens means the context window was nearly full — the turn replayed a lot of prior conversation.
- Turns late in a session are more expensive because more context accumulates.

**`bottleneck` on output_tokens**
- Shows where Claude generated the most content — large code writes, long explanations, multi-tool plans.
- A turn with 1,938 output tokens (19% of total) likely wrote several files or a long response.
- Useful for finding turns where Claude over-generated (verbose output, unnecessary detail).

**`hotpaths`**
- Claude transcript hotpaths are typically flat: `session → llm_turn`. There's no deep call hierarchy.
- This tool is less revealing for Claude transcripts than for CPU profiles. Use it mainly to see the dominant session → turn paths by cost.

**`find_waste`**
- Detects blind edits, redundant reads, and retry loops specific to Claude tool usage.
- A clean session (no waste detected) means Claude read before editing, didn't retry failed operations, and didn't re-read unchanged files.
- When waste IS detected, each item includes counterfactual savings (tokens and cost that could have been avoided).

**`spinpaths`**
- **Important caveat for Claude transcripts:** spinpaths flags spans with high wall_ms but no output_tokens. ALL tool spans (Bash, Write, Read, Agent, etc.) will be flagged because tool execution produces no tokens — only LLM turns produce tokens.
- This is expected behavior, not actual waste. For Claude transcripts, spinpaths is most useful for finding LLM turns that consumed tokens without producing tool calls or useful output.
- Filter mentally: ignore tool spans in spinpaths output; focus on any `llm_turn` entries that appear (those are turns where Claude "thought" but didn't act).

## Common Claude Session Anti-Patterns

tracemeld's `find_waste` detects these automatically, but knowing what to look for helps you interpret the results and give CLAUDE.md recommendations:

### Blind edits
Editing a file without reading it first. Claude guesses at the file contents and the edit often fails, wasting a turn.
- **Signal:** `Edit:*` span with no preceding `Read:*` span for the same file
- **Fix:** Add to CLAUDE.md: "Always read a file before editing it"

### Redundant reads
Reading the same file multiple times in one session. Each read consumes a turn and tokens.
- **Signal:** Multiple `Read:*` spans for the same file path
- **Fix:** Read once, refer back to it. Re-reading after editing the file is legitimate

### Retry loops
A tool call fails, then the same (or very similar) call is retried immediately.
- **Signal:** Repeated `Bash:*` or `Edit:*` spans with similar names, back-to-back
- **Fix:** Diagnose the root cause before retrying. Add CLAUDE.md guidance for common failure modes

### Excessive sequential tool calls
Many small tool calls that could be batched or parallelized.
- **Signal:** Long chains of sibling `Read:*` or `Grep:*` spans under one LLM turn
- **Fix:** Use `Agent` for broad exploration, or read multiple files in one turn

### Agent sprawl
Launching too many subagents for tasks that could be done directly.
- **Signal:** Many `Agent:*` spans with high wall_ms and overlapping purposes
- **Fix:** Use agents for genuinely independent parallel work, not for serial tasks. Each agent has its own context window and token spend.

### Context bloat
LLM turns with very high `cache_read_tokens` relative to `output_tokens`.
- **Signal:** `cache_read_tokens` growing across turns (e.g., 97K → 120K → 154K → 192K)
- **Fix:** Be selective about what gets read into context. Use targeted reads with line ranges. Consider starting a new session when context gets large.
- **Real example:** A turn with 192K cache_read_tokens and only 735 output_tokens cost $0.34 — mostly paying to replay context.

### Task/tool overhead
Excessive TaskCreate, TaskUpdate, ToolSearch, or Skill calls that don't contribute to the goal.
- **Signal:** High span counts for overhead tools (e.g., 142 TaskUpdate calls, 61 TaskCreate calls)
- **Fix:** Use tasks for complex multi-step work, not for simple single-action requests

## Example Synthesis

After running the full pipeline, produce findings in this format:

**Session overview: $7.09 total, 2,636 spans, 10,374 output tokens**
- 1,270 LLM turns consumed 4.2M cache_read_tokens and 10.4K output tokens
- 426 Bash calls, 216 Read calls, 193 Edit calls, 66 Agent launches
- Most expensive turn: `llm_turn:req_011CZKMHvvbn` ($0.34) — 192K cache reads, 735 output tokens

**Cost analysis:**
- Cache reads dominate: 4.2M tokens × $1.50/M = ~$6.31 (89% of cost)
- Output generation: 10.4K tokens × $75/M = ~$0.78 (11% of cost)
- Fresh input: negligible ($0.00087)
- **Takeaway:** Cost is driven by context replay, not generation. Shorter sessions or context pruning would reduce spend.

**Wall time analysis (excluding session root):**
- Agents: 15,083s (3.1%) — 66 subagent launches, largest was "Implement Tasks 3-8" at 6,650s
- Writes: 3,280s (0.7%) — 52 file writes, one large write took 822s
- Bash: 1,111s (0.2%) — 426 shell commands
- **Takeaway:** Agent execution dominates non-idle time. Consider whether subagent work could be done in the main session.

**Output token concentration:**
- Top turn generated 1,938 tokens (19% of all output) — likely a large file write or multi-file plan
- Top 5 turns account for 46% of all output tokens
- **Takeaway:** Generation is concentrated in a few key turns; most turns are lightweight tool orchestration

**Waste:** None detected (clean session — all edits preceded by reads, no retry loops)
