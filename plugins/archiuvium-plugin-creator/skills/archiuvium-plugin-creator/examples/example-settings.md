# Example Plugin Settings

Working examples of plugin-level settings.

## settings.json — Set Default Agent

```json
{
  "agent": "security-reviewer"
}
```

This activates the `security-reviewer` agent (defined in `agents/security-reviewer.md`)
as the main thread when the plugin is enabled. The agent's system prompt, tool
restrictions, and model override become the default behavior.

## When to Use

- Plugin is designed around a single specialized agent workflow
- You want to change Claude's default behavior when the plugin is active
- The plugin's primary value comes from the agent's perspective/expertise
