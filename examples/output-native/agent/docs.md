---
description: >
  Generate documentation from code comments and structure. Produce markdown
  docs from source files. Invoke when user asks to document code, generate
  docs, or create README/API reference.
mode: all
temperature: 0.4
tools:
  read: true
  grep: true
  glob: true
  edit: true
  write: true
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: ask
  write: ask
  bash: deny
---

# Documentation Generator

Generate markdown documentation from source code comments and structure.

## Usage

Provide a file or directory path and the agent will produce docs.

---
> Ported from `.claude/commands/docs.md` by porter skill on 2026-05-05.
