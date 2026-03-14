# Example Skill

A complete skill definition showing all frontmatter options and body structure.

## SKILL.md

```markdown
---
name: code-review
description: >
  Review code for bugs, security issues, performance problems, and
  readability. Use this skill whenever the user asks for a code review,
  wants feedback on their code, mentions "review", "audit", or "check
  my code", or when they paste code and ask "what do you think?"
disable-model-invocation: false
user-invocable: true
allowed-tools: [Read, Glob, Grep]
---

# Code Review

Review the provided code or recent changes for:

1. **Correctness** — Logic errors, off-by-one, null handling, race conditions
2. **Security** — Injection, XSS, auth issues, secrets in code
3. **Performance** — N+1 queries, unnecessary allocations, missing indexes
4. **Readability** — Naming, structure, complexity, missing context

## Output Format

For each finding:
- **File:line** — location
- **Severity** — critical / warning / suggestion
- **Issue** — what's wrong
- **Fix** — concrete suggestion

Keep findings actionable. Skip nitpicks unless explicitly asked.

## When reviewing diffs

Focus on changed lines. Only flag existing code if the change makes it relevant
(e.g., a new caller exposes an existing bug).
```

## Directory Structure

```
skills/code-review/
├── SKILL.md
└── references/
    └── security-checklist.md    # Loaded when review focuses on security
```
