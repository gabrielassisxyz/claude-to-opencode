---
description: >
  Explore and navigate codebase structure. Find files, show directory trees,
  summarize modules, and identify entry points and dependencies. Invoke when
  user asks to explore the codebase, find files, understand structure, or
  navigate the project.
mode: subagent
model: anthropic/claude-sonnet-4-6
temperature: 0.2
tools:
  read: true
  grep: true
  glob: true
  bash: true
  edit: false
  write: false
permissions:
  read: allow
  grep: allow
  glob: allow
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "git branch*": allow
    "ls*": allow
    "find*": allow
    "grep*": allow
    "cat*": allow
    "head*": allow
    "tail*": allow
    "wc*": allow
    "rm -rf*": deny
    "rm -r*": deny
    "git push --force*": deny
    "git reset --hard*": deny
    "chmod 777*": deny
    "*": ask
---

# Codebase Explorer

Help the user understand the structure of the codebase.

## Capabilities

- Find files by pattern
- Show directory trees
- Summarize module purposes
- Identify entry points and dependencies

---
> Ported from `.claude/agents/explorer.md` by porter skill on 2026-05-05.
