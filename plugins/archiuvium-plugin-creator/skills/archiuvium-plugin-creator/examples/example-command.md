# Example Command

A complete slash command showing frontmatter and body.

## commands/summarize.md

```markdown
---
description: Summarize a file's purpose and structure
argument-hint: <file-path>
allowed-tools: [Read, Glob]
---

Read the file at $ARGUMENTS and provide:

1. A one-sentence summary of what it does
2. Its main exports, functions, or classes
3. Key dependencies it relies on
4. How it fits into the broader project

Keep the response concise — no more than 15 lines.
```

## commands/check-deps.md (no arguments)

```markdown
---
description: Check for outdated or vulnerable dependencies
allowed-tools: [Read, Bash, Glob]
---

1. Find the project's dependency files (package.json, requirements.txt, go.mod, etc.)
2. Check for outdated packages using the appropriate package manager
3. Check for known vulnerabilities if a tool is available (npm audit, pip-audit, etc.)
4. Report findings grouped by severity
```
