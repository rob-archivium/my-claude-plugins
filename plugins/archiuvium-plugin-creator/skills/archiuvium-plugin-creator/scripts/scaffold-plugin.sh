#!/usr/bin/env bash
# Scaffold a new Claude Code plugin directory structure.
# Usage: scaffold-plugin.sh <plugin-name> [components...]
# Components: skill, command, agent, hook, mcp, all
set -euo pipefail

PLUGIN_NAME="${1:?Usage: scaffold-plugin.sh <plugin-name> [components...]}"
shift
COMPONENTS=("${@:-all}")

# Resolve marketplace root (two levels up from this script's plugin)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
PLUGIN_DIR="$MARKETPLACE_ROOT/plugins/$PLUGIN_NAME"

if [[ -d "$PLUGIN_DIR" ]]; then
  echo "Error: Plugin directory already exists: $PLUGIN_DIR"
  exit 1
fi

# Validate plugin name (kebab-case)
if [[ ! "$PLUGIN_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: Plugin name must be kebab-case (lowercase letters, numbers, hyphens)"
  exit 1
fi

echo "Creating plugin: $PLUGIN_NAME"

# Always create the manifest
mkdir -p "$PLUGIN_DIR/.claude-plugin"
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << EOF
{
  "name": "$PLUGIN_NAME",
  "description": "",
  "author": {
    "name": ""
  },
  "license": "MIT"
}
EOF

has_component() {
  local target="$1"
  for c in "${COMPONENTS[@]}"; do
    [[ "$c" == "$target" || "$c" == "all" ]] && return 0
  done
  return 1
}

# Skill
if has_component "skill"; then
  mkdir -p "$PLUGIN_DIR/skills/$PLUGIN_NAME"
  cat > "$PLUGIN_DIR/skills/$PLUGIN_NAME/SKILL.md" << 'EOF'
---
name: PLUGIN_NAME
description: >
  TODO: Describe when this skill should trigger and what it does.
  Be specific and include trigger phrases.
---

# PLUGIN_NAME

TODO: Write skill instructions here.
EOF
  sed -i '' "s/PLUGIN_NAME/$PLUGIN_NAME/g" "$PLUGIN_DIR/skills/$PLUGIN_NAME/SKILL.md"
  echo "  Created skills/$PLUGIN_NAME/SKILL.md"
fi

# Command
if has_component "command"; then
  mkdir -p "$PLUGIN_DIR/commands"
  cat > "$PLUGIN_DIR/commands/$PLUGIN_NAME.md" << 'EOF'
---
description: TODO - brief description for /help
argument-hint: [args]
allowed-tools: [Read, Glob, Grep, Bash]
---

TODO: Write command instructions here. Use $ARGUMENTS for user input.
EOF
  echo "  Created commands/$PLUGIN_NAME.md"
fi

# Agent
if has_component "agent"; then
  mkdir -p "$PLUGIN_DIR/agents"
  cat > "$PLUGIN_DIR/agents/$PLUGIN_NAME.md" << EOF
---
name: $PLUGIN_NAME
description: |
  TODO: Describe when to use this agent and what it specializes in.
model: sonnet
color: green
tools: [Read, Write, Edit, Glob, Grep, Bash]
---

TODO: Write agent system prompt here.
EOF
  echo "  Created agents/$PLUGIN_NAME.md"
fi

# Hook
if has_component "hook"; then
  mkdir -p "$PLUGIN_DIR/hooks/scripts"
  cat > "$PLUGIN_DIR/hooks/hooks.json" << 'EOF'
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
        ],
        "description": "TODO: describe what this hook validates"
      }
    ]
  }
}
EOF
  cat > "$PLUGIN_DIR/hooks/scripts/validate.sh" << 'EOF'
#!/usr/bin/env bash
# TODO: Implement validation logic
# Reads tool input from stdin
# Exit 0 to allow, non-zero to block
set -euo pipefail
exit 0
EOF
  chmod +x "$PLUGIN_DIR/hooks/scripts/validate.sh"
  echo "  Created hooks/hooks.json and hooks/scripts/validate.sh"
fi

# MCP
if has_component "mcp"; then
  cat > "$PLUGIN_DIR/.mcp.json" << 'EOF'
{
  "example-server": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/example-server.js",
    "args": [],
    "env": {}
  }
}
EOF
  echo "  Created .mcp.json"
fi

# Standard files
cat > "$PLUGIN_DIR/README.md" << EOF
# $PLUGIN_NAME

TODO: Describe this plugin.

## Installation

\`\`\`shell
/plugin install $PLUGIN_NAME@my-laude-plugins
\`\`\`
EOF

cat > "$PLUGIN_DIR/CHANGELOG.md" << EOF
# Changelog

## 0.1.0

- Initial release
EOF

cp "$MARKETPLACE_ROOT/LICENSE" "$PLUGIN_DIR/LICENSE" 2>/dev/null || true

echo ""
echo "Plugin scaffolded at: $PLUGIN_DIR"
echo "Next steps:"
echo "  1. Edit .claude-plugin/plugin.json with description and author"
echo "  2. Implement your components"
echo "  3. Add entry to marketplace.json"
echo "  4. Validate: claude plugin validate ./plugins/$PLUGIN_NAME"
