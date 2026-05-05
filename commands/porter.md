---
description: >
  Quick command to port Claude Code skills/agents/commands to OpenCode format.
  Run this when you want to migrate a plugin, convert a skill, or translate
  artifacts between Claude Code and OpenCode.
---

# Porter — Claude Code → OpenCode

Port Claude Code artifacts to OpenCode format automatically.

This command invokes the `porter` skill. For full documentation, see
`skills/porter/SKILL.md`.

## Usage

```
/porter [source_path]
```

- `source_path`: Path to `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, or a specific file. Defaults to current directory.

## Examples

```
/porter                              # Scan CWD for Claude Code artifacts
/porter ./my-claude-skills           # Port from custom path
```

## What It Does

1. Discovers skills, agents, and commands in the source directory
2. Translates YAML frontmatter to OpenCode schema
3. Maps tools (Read → read, Bash → bash, etc.)
4. Infers zero-trust permissions based on tool set
5. Assigns temperature and mode heuristically
6. Generates companion command files
7. Produces a validation report (`porter-report.md`)

## Hooks Support

If the source skill uses Claude Code lifecycle hooks (UserPromptSubmit, PostToolUse,
Stop), the porter can generate a `hooks.yaml` configuration using the forked
`opencode-yaml-hooks` plugin.

**Fork:** https://github.com/gabrielassisxyz/OpenCode-Hooks

Without the fork, the porter falls back to embedding manual logging instructions
in the skill body.

## Decision Points

The porter will pause and ask when:
- An unknown tool is encountered
- Model cannot be inferred
- Target file already exists
- MCP enhancement is suggested
- Complex sub-agent topology is detected
- Hooks are present and user must choose: install forked plugin or use fallback

For all other cases, it proceeds autonomously.
