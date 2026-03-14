# my-laude-plugins Marketplace Design

**Date:** 2026-03-14
**Audience:** Team/Org
**Architecture:** Monorepo (all plugins in `plugins/` directory)

## Repository Structure

```
Claude Plugins/
├── .claude-plugin/
│   └── marketplace.json              # Marketplace registry
├── plugins/
│   └── archiuvium-plugin-creator/    # First plugin: meta plugin-creator
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── archiuvium-plugin-creator/
│       │       ├── SKILL.md
│       │       ├── references/
│       │       ├── examples/
│       │       └── scripts/
│       ├── commands/
│       ├── agents/
│       ├── hooks/
│       │   ├── hooks.json
│       │   └── scripts/
│       ├── .mcp.json
│       ├── scripts/
│       ├── LICENSE
│       ├── CHANGELOG.md
│       └── README.md
├── LICENSE
└── README.md
```

## Marketplace Manifest

- **Name:** `my-laude-plugins`
- **Schema:** `https://anthropic.com/claude-code/marketplace.schema.json`
- **`metadata.pluginRoot`:** `./plugins` (allows short source paths)
- **Plugin source type:** Relative paths (monorepo)

## First Plugin: archiuvium-plugin-creator

A kitchen-sink template plugin that demonstrates every Claude Code plugin component type with working examples. The primary skill helps users create new plugins for this marketplace from scratch.

### Components Demonstrated

1. **Skills** — `archiuvium-plugin-creator` skill with references/, examples/, scripts/
2. **Commands** — Slash commands with frontmatter
3. **Agents** — Subagent definitions
4. **Hooks** — Both command and prompt hook types using `${CLAUDE_PLUGIN_ROOT}`
5. **MCP Servers** — Stdio server example
6. **Scripts** — Shared utility scripts

### Key Conventions

- All paths use `${CLAUDE_PLUGIN_ROOT}` for portability
- kebab-case for all file and directory names
- Semantic versioning
- Version set in marketplace.json only (not plugin.json) for relative-path plugins
- `strict: true` (default) — plugin.json is authority
