# Example MCP Server Configuration

Working examples of each MCP server type.

## .mcp.json — Stdio (local process)

```json
{
  "file-search": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/file-search.js"],
    "env": {
      "SEARCH_ROOT": "${CLAUDE_PROJECT_DIR}",
      "MAX_RESULTS": "50"
    }
  }
}
```

## .mcp.json — HTTP (REST API)

```json
{
  "company-api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${COMPANY_API_TOKEN}",
      "Content-Type": "application/json"
    }
  }
}
```

## .mcp.json — SSE (Server-Sent Events)

```json
{
  "cloud-service": {
    "type": "sse",
    "url": "https://mcp.cloud-service.com/sse"
  }
}
```

## Combined .mcp.json

A single plugin can define multiple servers:

```json
{
  "local-db": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config/db.json"],
    "env": {
      "DATABASE_URL": "${DATABASE_URL}"
    }
  },
  "external-api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_KEY}"
    }
  }
}
```

## Key Rules

- Always use `${CLAUDE_PLUGIN_ROOT}` for paths to files within the plugin
- Use `${VAR_NAME}` for secrets and environment-specific values
- Servers start automatically when the plugin loads
- Each server's tools appear in Claude's tool list with the server name as prefix
