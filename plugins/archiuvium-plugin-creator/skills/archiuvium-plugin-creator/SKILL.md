---
name: archiuvium-plugin-creator
description: >
  Guide for creating complete Claude Code plugins with all component types
  (skills, commands, agents, hooks, MCP servers) and registering them in the
  my-claude-plugins marketplace. Use this skill whenever the user wants to
  create a new plugin, scaffold a plugin, add a plugin to the marketplace,
  build a Claude Code extension, or asks "how do I make a plugin?" Even if
  they only mention one component type (like "I want to add a hook" or
  "create a skill"), invoke this skill because it provides the full structural
  context needed to do it correctly.
---

# Archiuvium Plugin Creator

Create complete, well-structured Claude Code plugins and register them in the
my-claude-plugins marketplace. This skill walks you through the entire process
from idea to installable plugin.

## When to Use This

- User wants to create a new plugin from scratch
- User wants to add any component (skill, command, agent, hook, MCP server) to a plugin
- User asks about plugin structure or conventions
- User wants to register a plugin in the marketplace

## Process

### 1. Understand What the User Wants

Ask these questions (skip any you can already answer from context):

1. **What should the plugin do?** Get a one-sentence description.
2. **Which components does it need?** Walk through each type:
   - **Skills** — Contextual guidance Claude auto-invokes based on task
   - **Commands** — Slash commands the user explicitly invokes (`/my-command`)
   - **Agents** — Specialized subagents for delegation
   - **Hooks** — Event handlers that fire on tool use, session events, etc.
   - **MCP Servers** — External tool integrations (APIs, databases, services)
   - **LSP Servers** — Language server protocol integrations for code intelligence
   - **Output Styles** — Custom response formatting
   - **Settings** — Plugin-level default configuration (e.g., default agent)
3. **Plugin name?** Must be kebab-case, descriptive, unique in the marketplace.

### 2. Scaffold the Directory Structure

Use the scaffold script to create the plugin skeleton:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/archiuvium-plugin-creator/scripts/scaffold-plugin.sh <plugin-name> [components...]
```

Components: `skill`, `command`, `agent`, `hook`, `mcp`, `lsp`, `output-style`, `settings`, `all`

If the script isn't available, create the structure manually. The required layout is:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (REQUIRED)
├── skills/                   # Skills (subdirectories with SKILL.md)
│   └── <skill-name>/
│       └── SKILL.md
├── commands/                 # Slash commands (.md files)
├── agents/                   # Subagent definitions (.md files)
├── hooks/
│   ├── hooks.json            # Hook event configuration
│   └── scripts/              # Hook scripts
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server definitions
├── output-styles/            # Response formatting styles (.md files)
├── settings.json             # Plugin-level default settings
├── scripts/                  # Shared utilities
├── LICENSE
├── CHANGELOG.md
└── README.md
```

**Critical rules:**
- `plugin.json` goes in `.claude-plugin/` — nowhere else
- All component directories go at the plugin root — never inside `.claude-plugin/`
- Only create directories for components the plugin actually uses
- Use kebab-case for all file and directory names
- Use `${CLAUDE_PLUGIN_ROOT}` for all internal path references in hooks and MCP configs

### 3. Create Each Component

Read the appropriate reference file for detailed guidance on each component type:

- **Skills:** Read `references/component-guide.md` § Skills
- **Commands:** Read `references/component-guide.md` § Commands
- **Agents:** Read `references/component-guide.md` § Agents
- **Hooks:** Read `references/component-guide.md` § Hooks
- **MCP Servers:** Read `references/component-guide.md` § MCP Servers
- **LSP Servers:** Read `references/component-guide.md` § LSP Servers
- **Output Styles:** Read `references/component-guide.md` § Output Styles
- **Settings:** Read `references/component-guide.md` § Plugin Settings

For working examples of each component type, see the `examples/` directory.

### 4. Write the Plugin Manifest

Create `.claude-plugin/plugin.json` with at minimum a `name`:

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "0.1.0",
  "author": {
    "name": "Author Name"
  },
  "license": "MIT",
  "keywords": ["relevant", "keywords"]
}
```

For relative-path plugins in this marketplace, set the version in `marketplace.json`
rather than in `plugin.json` to avoid silent conflicts where plugin.json wins.

### 5. Register in the Marketplace

Add an entry to the root `marketplace.json` at `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": "my-plugin",
  "description": "Brief description for the marketplace listing",
  "version": "0.1.0",
  "author": { "name": "Author Name" },
  "license": "MIT",
  "keywords": ["discovery", "tags"],
  "category": "development",
  "tags": ["searchability"]
}
```

The `source` path is relative to `metadata.pluginRoot` (which is `./plugins` in this
marketplace), so just use the plugin directory name.

### 6. Validate and Test

```bash
claude plugin validate ./plugins/<plugin-name>
```

Then install locally:

```shell
/plugin marketplace add ./path/to/Claude-Plugins
/plugin install <plugin-name>@my-claude-plugins
```

## Quick Reference

| Component | Location | Format | Trigger |
|-----------|----------|--------|---------|
| Skill | `skills/<name>/SKILL.md` | Markdown + YAML frontmatter | Auto by Claude or `/skill-name` |
| Command | `commands/<name>.md` | Markdown + YAML frontmatter | `/command-name` by user |
| Agent | `agents/<name>.md` | Markdown + YAML frontmatter | By Claude or user delegation |
| Hook | `hooks/hooks.json` | JSON event config | Automatic on matching events |
| MCP Server | `.mcp.json` | JSON server config | Automatic on plugin load |
| LSP Server | `.lsp.json` | JSON server config | Automatic on plugin load |
| Output Style | `output-styles/<name>.md` | Markdown + YAML frontmatter | Per-session or per-project |
| Settings | `settings.json` | JSON config | Automatic on plugin enable |

## Common Pitfalls

- **Paths break after install** — Plugins are copied to a cache. Use `${CLAUDE_PLUGIN_ROOT}`, never hardcoded or relative `../` paths.
- **Version conflicts** — For monorepo plugins, set version only in marketplace.json.
- **Hook scripts not executable** — Run `chmod +x` on all scripts in `hooks/scripts/`.
- **Skill not triggering** — Make the description pushy and specific. Include trigger phrases.
- **Components in wrong directory** — Commands, agents, skills, hooks go at plugin root, not in `.claude-plugin/`.
