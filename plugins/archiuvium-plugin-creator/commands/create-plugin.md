---
description: Scaffold a new plugin for the my-laude-plugins marketplace
argument-hint: <plugin-name> [skill] [command] [agent] [hook] [mcp] [all]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

Create a new Claude Code plugin in the my-laude-plugins marketplace.

## Arguments

The user provided: $ARGUMENTS

Parse the first word as the plugin name (must be kebab-case). Remaining words are
component types to include: `skill`, `command`, `agent`, `hook`, `mcp`, or `all`.
If no components are specified, default to `all`.

## Steps

1. Run the scaffold script:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/archiuvium-plugin-creator/scripts/scaffold-plugin.sh $ARGUMENTS
   ```

2. If the script succeeds, guide the user through filling in the TODOs:
   - Plugin description in `plugin.json`
   - Skill description and instructions in `SKILL.md`
   - Command description and logic
   - Agent specialization and system prompt
   - Hook event configuration
   - MCP server setup

3. Add the plugin entry to the marketplace's `.claude-plugin/marketplace.json`.

4. Suggest running validation: `claude plugin validate ./plugins/<name>`
