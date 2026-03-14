# archiuvium-plugin-creator

Kitchen-sink template plugin for the my-claude-plugins marketplace. Demonstrates
every Claude Code plugin component type with working examples, and includes a
skill that guides users through creating new plugins from scratch.

## Installation

```shell
/plugin install archiuvium-plugin-creator@my-claude-plugins
```

## What's Included

### Skill: archiuvium-plugin-creator

Auto-invoked when you want to create a new plugin. Provides step-by-step guidance
through component selection, directory scaffolding, and marketplace registration.

Includes bundled resources:
- `references/component-guide.md` — Detailed guide to every component type
- `references/plugin-structure.md` — Directory layout and manifest reference
- `examples/` — Working examples of each component type
- `scripts/scaffold-plugin.sh` — Automated plugin scaffolding

### Command: /create-plugin

```shell
/create-plugin my-new-plugin all
/create-plugin api-tools skill command mcp
```

Scaffolds a new plugin directory with the selected component types.

### Agent: plugin-reviewer

Validates plugin structure, naming conventions, and best practices. Automatically
invoked when reviewing plugins, or delegate to it explicitly.

### Hooks

- **PreToolUse (Write)** — Validates plugin directory conventions when writing files

### MCP Server

- **plugin-registry** — Stub MCP server demonstrating the stdio transport pattern

### LSP Server

- **example-language** — Stub LSP server demonstrating the language server configuration

### Output Style

- **example-style** — Demonstrates custom response formatting with frontmatter

### Settings

- `settings.json` — Sets `plugin-reviewer` as the default agent

## Using as a Template

Copy any component from this plugin as a starting point:

```bash
# Copy the whole plugin as a base
cp -r plugins/archiuvium-plugin-creator plugins/my-new-plugin

# Or just grab individual components
cp plugins/archiuvium-plugin-creator/hooks/hooks.json plugins/my-plugin/hooks/
```

## Component Reference

| Component | File | Purpose |
|-----------|------|---------|
| Skill | `skills/archiuvium-plugin-creator/SKILL.md` | Plugin creation guidance |
| Command | `commands/create-plugin.md` | `/create-plugin` scaffolding |
| Agent | `agents/plugin-reviewer.md` | Structure validation |
| Hooks | `hooks/hooks.json` | Convention enforcement |
| MCP | `.mcp.json` | Registry server stub |
| Script | `scripts/registry-server.js` | MCP server example |
| Script | `skills/.../scripts/scaffold-plugin.sh` | Directory scaffolding |
