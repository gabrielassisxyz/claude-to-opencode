---
description: >
  Implement new features from spec end-to-end. Reads specs, explores codebase,
  writes code, runs tests, and coordinates with sub-agents.
mode: primary
model: anthropic/claude-sonnet-4-6
temperature: 0.3
tools:
  read: true
  edit: true
  write: true
  bash: true
  grep: true
  glob: true
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: ask
  write: ask
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
    "npm test*": allow
    "npm run lint*": allow
    "go test*": allow
    "cargo test*": allow
    "rm -rf*": deny
    "rm -r /": deny
    "git push --force*": deny
    "git reset --hard*": deny
    "chmod 777*": deny
    "*": ask
---

# Feature Development Skill

Given a specification, implement the feature end-to-end.

## Workflow

1. Read the spec and understand requirements
2. Explore existing codebase for relevant files
3. Implement changes
4. Run tests to verify
5. Ask the user for review

## Sub-agents

- `@test-writer` — writes unit tests for the feature

---
> Ported from `.claude/skills/feature-dev/SKILL.md` by porter skill on 2026-05-05.
