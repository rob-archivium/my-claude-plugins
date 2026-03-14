# Example Hooks Configuration

Working examples of both command and prompt hook types.

## hooks/hooks.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-file-size.sh",
            "timeout": 10
          }
        ],
        "description": "Warn before writing files larger than 500 lines"
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/block-dangerous.sh",
            "timeout": 5
          }
        ],
        "description": "Block dangerous shell commands"
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review whether the task was completed fully. If not, suggest what remains.",
            "timeout": 15
          }
        ],
        "description": "Completeness check when Claude stops"
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Plugin loaded successfully'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## hooks/scripts/block-dangerous.sh

```bash
#!/usr/bin/env bash
# Reads tool input from stdin, blocks dangerous commands
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

# Block patterns
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/|DROP\s+TABLE|:(){ :|:& };:'; then
  echo "BLOCKED: Potentially dangerous command detected"
  exit 1
fi

exit 0
```
