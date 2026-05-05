---
description: >
  Quick command to port Claude Code skills/agents/commands to OpenCode format.
  Run this when you want to migrate a plugin, convert a skill, or translate
  artifacts between Claude Code and OpenCode.
---

# Porter — Claude Code → OpenCode

Port Claude Code artifacts to OpenCode format automatically.

## Usage

```
/porter [source_path] [--target-format=powerpack|native|both]
```

- `source_path`: Path to `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, or a specific file. Defaults to current directory.
- `--target-format`: Output format. Default is `powerpack`.

## Examples

```
/porter                              # Scan CWD for Claude Code artifacts
/porter ./my-claude-skills           # Port from custom path
/porter --target-format=native       # Output native agent format
/porter --target-format=both         # Generate both formats
```

## What It Does

1. Discovers skills, agents, and commands in the source directory
2. Translates YAML frontmatter to OpenCode schema
3. Maps tools (Read → read, Bash → bash, etc.)
4. Infers zero-trust permissions based on tool set
5. Assigns temperature and mode heuristically
6. Generates companion command files
7. Produces a validation report (`porter-report.md`)

## Decision Points

The porter will pause and ask when:
- An unknown tool is encountered
- Model cannot be inferred
- Target file already exists
- MCP enhancement is suggested
- Complex sub-agent topology is detected

For all other cases, it proceeds autonomously.
