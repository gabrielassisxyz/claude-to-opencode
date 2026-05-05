---
name: feature-dev
description: >
  Implement new features from spec end-to-end. Reads specs, explores codebase,
  writes code, runs tests, and coordinates with sub-agents. Invoke when user
  asks to build a feature, implement from requirements, or develop new
  functionality.
license: MIT (ported from .claude/skills/feature-dev)
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
