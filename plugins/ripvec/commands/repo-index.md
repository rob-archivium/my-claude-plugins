---
name: repo-index
description: Create a repo-level search index that can be committed to git
---

Call the `reindex` MCP tool with repo-level storage enabled:

reindex(repo_level: true)

This creates a `.ripvec/` directory at the project root containing:
- `config.toml` — model and version pin
- `cache/` — the search index (manifest + object store)

After indexing completes, commit `.ripvec/` to git so teammates get instant
semantic search without re-embedding.

If the index already exists as repo-local, this re-indexes incrementally
(only changed files are re-embedded).

Report the result: how many chunks indexed, from how many files, and remind
the user to `git add .ripvec/ && git commit` to share the index.
