# my-laude-plugins

Team plugin marketplace for Claude Code.

## Installation

```shell
/plugin marketplace add path/to/Claude-Plugins
```

Or from a Git host:

```shell
/plugin marketplace add your-org/my-laude-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **archiuvium-plugin-creator** | Kitchen-sink template and plugin scaffolding tool. Demonstrates every component type (skills, commands, agents, hooks, MCP servers). |

## Installing a Plugin

```shell
/plugin install archiuvium-plugin-creator@my-laude-plugins
```

## Adding Plugins

See the [archiuvium-plugin-creator](plugins/archiuvium-plugin-creator/) plugin for a full reference of every component type, or use its `/create-plugin` command to scaffold a new plugin.

## For Teams

Add to your project's `.claude/settings.json` to auto-prompt team members:

```json
{
  "extraKnownMarketplaces": {
    "my-laude-plugins": {
      "source": {
        "source": "github",
        "repo": "your-org/my-laude-plugins"
      }
    }
  }
}
```
