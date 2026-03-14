#!/usr/bin/env bash
# Validates that files being written to a plugin directory follow conventions.
# Runs as a PreToolUse hook on Write operations.
# Reads tool input (JSON) from stdin.
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')

# Only validate files within a plugins/ directory
if [[ "$FILE_PATH" != *"/plugins/"* ]]; then
  exit 0
fi

# Extract the plugin directory name
PLUGIN_DIR=$(echo "$FILE_PATH" | sed -n 's|.*/plugins/\([^/]*\)/.*|\1|p')

if [[ -z "$PLUGIN_DIR" ]]; then
  exit 0
fi

# Check naming convention (kebab-case)
if [[ ! "$PLUGIN_DIR" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Warning: Plugin directory '$PLUGIN_DIR' should be kebab-case"
fi

# Check for components inside .claude-plugin/ (they should be at root)
if [[ "$FILE_PATH" == *"/.claude-plugin/"* ]]; then
  BASENAME=$(basename "$FILE_PATH")
  if [[ "$BASENAME" != "plugin.json" && "$BASENAME" != "marketplace.json" ]]; then
    echo "Warning: Only plugin.json belongs in .claude-plugin/. Components go at plugin root."
  fi
fi

exit 0
