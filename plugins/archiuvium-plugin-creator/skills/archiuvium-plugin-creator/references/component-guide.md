# Component Guide

Detailed reference for every Claude Code plugin component type.

## Table of Contents

- [Skills](#skills)
- [Commands](#commands)
- [Agents](#agents)
- [Hooks](#hooks)
- [MCP Servers](#mcp-servers)
- [LSP Servers](#lsp-servers)
- [Output Styles](#output-styles)
- [Plugin Settings](#plugin-settings)

---

## Skills

Skills are the primary extension mechanism. Claude auto-invokes them based on task
context, or users can invoke them explicitly via `/skill-name`.

### Structure

```
skills/my-skill/
├── SKILL.md              # Required — skill definition
├── references/           # Detailed docs loaded on demand
├── examples/             # Working examples
├── scripts/              # Executable helpers
└── assets/               # Templates, icons, fonts
```

### SKILL.md Frontmatter

```yaml
---
name: my-skill
description: >
  When to trigger this skill and what it does. Be specific and pushy —
  include trigger phrases, keywords, and contexts. Claude undertriggers
  by default, so err on the side of broader matching.
disable-model-invocation: false    # true = only manual /my-skill invocation
user-invocable: true               # false = background knowledge only
allowed-tools: [Read, Glob, Grep, Bash]  # restrict available tools
model: sonnet                      # override model (haiku, sonnet, opus)
context: fork                      # run in isolated subagent context
agent: Explore                     # subagent type for context: fork
argument-hint: <file> [options]    # shown during autocomplete
---
```

### Writing Tips

- **Description is the trigger mechanism.** Include specific phrases users might say.
- **Keep SKILL.md under 500 lines.** Move detailed content to `references/`.
- **Progressive disclosure:** metadata (~100 words) → SKILL.md body → bundled resources.
- **Use imperative form** in instructions ("Read the file", not "You should read the file").
- **Explain why**, not just what. Claude responds better to reasoning than rigid rules.

---

## Commands

Slash commands the user explicitly invokes. Simpler than skills — good for one-shot
actions with clear inputs.

### Location

`commands/my-command.md` — filename becomes the `/my-command` invocation.

### Frontmatter

```yaml
---
description: Short description shown in /help (under 60 chars)
argument-hint: <required-arg> [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
model: sonnet
---
```

### Body

Write the command body as instructions FOR Claude, not messages to the user.
Use `$ARGUMENTS` to access user-provided arguments.

```markdown
---
description: Summarize a file's purpose and structure
argument-hint: <file-path>
allowed-tools: [Read, Glob]
---

Read the file at $ARGUMENTS and provide:
1. A one-sentence summary of what it does
2. Its main exports/functions
3. Key dependencies it relies on

Keep the response concise — no more than 10 lines.
```

---

## Agents

Specialized subagents that Claude delegates to for specific task types. Agents
run in isolated contexts with their own tool sets and system prompts.

### Location

`agents/my-agent.md` — one file per agent.

### Frontmatter

```yaml
---
name: my-agent
description: |
  When to use this agent and what it specializes in.

  <example>
  Context: User wants to do X
  user: "Some user message"
  assistant: "I'll use the my-agent agent to handle this"
  <commentary>Why this agent is the right choice</commentary>
  </example>

model: sonnet
color: green
tools: [Read, Write, Edit, Glob, Grep, Bash]
---
```

### Body

The body is the agent's system prompt — instructions for how it should behave
when delegated to.

### Key Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | 3-50 chars, kebab-case |
| `description` | Yes | Trigger conditions with examples |
| `model` | No | haiku, sonnet, opus |
| `color` | No | Terminal color for output |
| `tools` | No | Available tools list |

---

## Hooks

Event handlers that fire automatically in response to Claude Code events. Hooks
enable validation, automation, and safety guardrails.

### Location

`hooks/hooks.json` — single configuration file.

### Hook Types

1. **Command hooks** — Run shell scripts for deterministic checks
2. **Prompt hooks** — Use LLM evaluation for context-aware decisions

### Events

| Event | Fires When |
|-------|-----------|
| `PreToolUse` | Before a tool executes |
| `PostToolUse` | After a tool completes |
| `PostToolUseFailure` | After a tool fails |
| `UserPromptSubmit` | User sends a message |
| `Stop` | Claude finishes responding |
| `SubagentStart` | Subagent is launched |
| `SubagentStop` | Subagent completes |
| `SessionStart` | Session begins |
| `SessionEnd` | Session ends |
| `PreCompact` | Before context compaction |
| `Notification` | Notification is sent |

### hooks.json Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if the response addresses the user's question completely.",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

### Hook Script Environment

Command hooks receive context via environment variables and stdin:
- `$TOOL_NAME` — the tool being used
- `$TOOL_INPUT` — JSON of tool parameters (via stdin for PreToolUse)
- Exit code 0 = allow, non-zero = block (for PreToolUse)
- Stdout is shown to Claude as feedback

**Always use `${CLAUDE_PLUGIN_ROOT}`** for script paths — plugins are cached elsewhere.

---

## MCP Servers

Model Context Protocol servers connect Claude to external tools and services.
They start automatically when the plugin loads.

### Location

`.mcp.json` at the plugin root.

### Server Types

**Stdio (local process):**

```json
{
  "my-server": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server.js",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_KEY": "${MY_API_KEY}"
    }
  }
}
```

**HTTP (REST API):**

```json
{
  "rest-api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

**SSE (Server-Sent Events):**

```json
{
  "cloud-service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

### Key Points

- Use `${CLAUDE_PLUGIN_ROOT}` for file paths within the plugin
- Use `${VAR_NAME}` for environment variables (API keys, tokens)
- Servers start on plugin load and persist for the session
- Each server provides tools that appear in Claude's tool list

---

## LSP Servers

Language Server Protocol servers give Claude real-time code intelligence for
specific programming languages. They start automatically when the plugin loads.

### Location

`.lsp.json` at the plugin root.

### Configuration

```json
{
  "language-id": {
    "command": "language-server-binary",
    "args": ["--stdio"],
    "extensionToLanguage": {
      ".ext": "language-id"
    }
  }
}
```

### Key Points

- Users must have the language server binary installed on their machine
- Use `extensionToLanguage` to map file extensions to language IDs
- For common languages (TypeScript, Python, Rust), use pre-built official LSP plugins instead
- Create custom LSP plugins only for languages not already covered

---

## Output Styles

Output styles customize how Claude formats its responses. They're Markdown files
with frontmatter defining the style name and instructions.

### Location

`output-styles/` at the plugin root.

### Format

```markdown
---
name: my-style
description: Brief description of the formatting style
---

Instructions for how Claude should format responses when this style is active.
```

### Key Points

- Styles are applied per-session or per-project
- Keep instructions concise — they're injected into every response
- Custom paths can be declared via `outputStyles` in plugin.json

---

## Plugin Settings

A `settings.json` at the plugin root applies default configuration when the
plugin is enabled. Currently supports the `agent` key.

### Location

`settings.json` at the plugin root.

### Format

```json
{
  "agent": "agent-name"
}
```

### Key Points

- Setting `agent` activates a custom agent as the main thread
- The agent must be defined in the plugin's `agents/` directory
- Settings from `settings.json` take priority over `settings` in `plugin.json`
- Unknown keys are silently ignored
