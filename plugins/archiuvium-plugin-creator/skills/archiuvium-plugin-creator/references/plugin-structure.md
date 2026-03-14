# Plugin Structure Reference

Complete reference for Claude Code plugin directory layout, manifest format,
and marketplace registration.

## Table of Contents

- [Directory Layout](#directory-layout)
- [Plugin Manifest](#plugin-manifest)
- [Marketplace Registration](#marketplace-registration)
- [Path Variables](#path-variables)
- [Naming Conventions](#naming-conventions)

---

## Directory Layout

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # REQUIRED: Plugin manifest
├── skills/                   # Auto-discovered
│   └── skill-name/
│       ├── SKILL.md         # Required per skill
│       ├── references/
│       ├── examples/
│       ├── scripts/
│       └── assets/
├── commands/                 # Auto-discovered (.md files)
├── agents/                   # Auto-discovered (.md files)
├── hooks/
│   ├── hooks.json           # Hook event configuration
│   └── scripts/             # Hook executable scripts
├── .mcp.json                # MCP server definitions
├── .lsp.json                # LSP server definitions
├── output-styles/            # Response formatting styles (.md files)
├── settings.json             # Plugin-level default settings
├── scripts/                 # Shared utilities
├── LICENSE
├── CHANGELOG.md
└── README.md
```

### Placement Rules

1. `plugin.json` MUST be in `.claude-plugin/`
2. Component directories MUST be at plugin root level
3. Components MUST NOT be nested inside `.claude-plugin/`
4. Only create directories for components the plugin uses
5. Auto-discovery finds components in default directories automatically

### Custom Component Paths

plugin.json can specify additional component locations (supplements defaults,
doesn't replace them):

```json
{
  "name": "my-plugin",
  "commands": ["./commands", "./extra-commands"],
  "agents": "./specialized-agents",
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json",
  "lspServers": "./.lsp.json",
  "outputStyles": "./output-styles",
  "settings": "./settings.json"
}
```

---

## Plugin Manifest

### Minimal

```json
{
  "name": "plugin-name"
}
```

### Full

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief explanation of what the plugin does",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://example.com"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/org/plugin",
  "license": "MIT",
  "keywords": ["relevant", "keywords"]
}
```

### Version Warning

For plugins in a monorepo marketplace using relative paths, set the version
in `marketplace.json` only — not in `plugin.json`. If both are set, `plugin.json`
wins silently, which causes the marketplace version to be ignored.

---

## Marketplace Registration

Each plugin needs an entry in the marketplace's `.claude-plugin/marketplace.json`:

```json
{
  "name": "plugin-name",
  "source": "plugin-name",
  "description": "Marketplace listing description",
  "version": "1.0.0",
  "author": { "name": "Author Name" },
  "license": "MIT",
  "keywords": ["discovery", "tags"],
  "category": "development",
  "tags": ["searchable"]
}
```

When `metadata.pluginRoot` is set (e.g., `"./plugins"`), the `source` field is
relative to that root. So `"source": "plugin-name"` resolves to `./plugins/plugin-name`.

### Strict Mode

| Value | Meaning |
|-------|---------|
| `true` (default) | `plugin.json` is authority. Marketplace supplements. |
| `false` | Marketplace entry is the full definition. Plugin must not have component declarations in plugin.json. |

---

## Path Variables

| Variable | Resolves To |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin's installation directory (in cache) |
| `${CLAUDE_PROJECT_DIR}` | User's current project directory |
| `${VAR_NAME}` | Environment variable |

Use `${CLAUDE_PLUGIN_ROOT}` everywhere — plugins are copied to
`~/.claude/plugins/cache/` on install. Hardcoded paths and `../` references
will break.

---

## Naming Conventions

- **Plugin names:** kebab-case, no spaces (`my-plugin`, not `My Plugin`)
- **Directories:** kebab-case (`my-skill/`, `hook-scripts/`)
- **Files:** kebab-case (`create-widget.md`, `validate-input.sh`)
- **Skill names:** kebab-case, 1-64 chars
- **Agent names:** kebab-case, 3-50 chars
- **Command filenames:** become the `/slash-command` name
