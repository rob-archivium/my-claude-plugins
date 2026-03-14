# Example LSP Server Configuration

Working examples of LSP server configurations.

## .lsp.json — Go

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

## .lsp.json — Multiple Languages

```json
{
  "ruby": {
    "command": "solargraph",
    "args": ["stdio"],
    "extensionToLanguage": {
      ".rb": "ruby",
      ".rake": "ruby"
    }
  },
  "elixir": {
    "command": "elixir-ls",
    "args": [],
    "extensionToLanguage": {
      ".ex": "elixir",
      ".exs": "elixir"
    }
  }
}
```

## Key Rules

- The language server binary must be installed on the user's machine
- Use `--stdio` mode for most language servers
- Map all relevant file extensions in `extensionToLanguage`
- For TypeScript, Python, and Rust, prefer the official LSP plugins
