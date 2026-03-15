# my-claude-plugins

Team plugin marketplace for Claude Code.

## Installation

```shell
/plugin marketplace add path/to/Claude-Plugins
```

Or from a Git host:

```shell
/plugin marketplace add your-org/my-claude-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **archiuvium-plugin-creator** | Kitchen-sink template and plugin scaffolding tool. Demonstrates every component type (skills, commands, agents, hooks, MCP servers). |
| **shopify-qbo** | Shopify → QuickBooks Online sync and management. 11 commands for sync, lookup, fix, delete, resolve customers, reconcile, report, and undo. |

## Installing a Plugin

```shell
/plugin install archiuvium-plugin-creator@my-claude-plugins
```

## Adding Plugins

See the [archiuvium-plugin-creator](plugins/archiuvium-plugin-creator/) plugin for a full reference of every component type, or use its `/create-plugin` command to scaffold a new plugin.

## For Teams

Add to your project's `.claude/settings.json` to auto-prompt team members:

```json
{
  "extraKnownMarketplaces": {
    "my-claude-plugins": {
      "source": {
        "source": "github",
        "repo": "your-org/my-claude-plugins"
      }
    }
  }
}
```
