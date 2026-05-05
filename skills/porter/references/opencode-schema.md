# OpenCode Target Format Reference

## SKILL.md Format

Standard OpenCode skill format.

```markdown
---
name: {kebab-case-name}
description: >
  Detailed description optimized for trigger matching.
  Explain WHAT the skill does and WHEN to invoke it.
license: MIT (ported from {source})
---

# {Title}

{Body content — preserved from source}

---
> Ported from `{source_path}` by porter skill on {date}.
```

**Requirements:**
- `name`: required, kebab-case, regex `^[a-z0-9]+(-[a-z0-9]+)*$`
- `description`: required, 1-1024 characters
- `license`: recommended
- File location: `skills/<name>/SKILL.md`

## Agent Format

Standard OpenCode agent format for `~/.config/opencode/agent/`.

```markdown
---
description: >
  Detailed description optimized for trigger matching.
mode: primary | subagent | all
model: {provider}/{model-id}  # optional, inherits if omitted
temperature: 0.1-1.0          # optional
tools:
  read: true
  edit: true
  write: true
  bash: true
  grep: true
  glob: true
  fetch: true
  search: true
  notebook: true
permissions:
  read: allow
  edit: ask
  write: ask
  grep: allow
  glob: allow
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "*": ask
---

{Body content — preserved from source}

---
> Ported from `{source_path}` by porter skill on {date}.
```

**Requirements:**
- `description`: required, 1-1024 characters
- `mode`: required, one of `primary`, `subagent`, `all`
- `model`: optional, provider-prefixed model ID
- `temperature`: optional, float 0.1-1.0
- `tools`: optional, boolean flags for each tool
- `permissions`: optional, but strongly recommended for zero-trust
- File location: `agent/<name>.md`

## Command Format (Slash Commands)

Standard OpenCode command format.

```markdown
---
description: {short_description}
---

# {Title}

{full_body_content}
```

**Requirements:**
- `description`: required
- File location: `command/<name>.md` or `commands/<name>.md`

## Tool Flags Reference

| Flag | Type | Description |
|------|------|-------------|
| `read` | boolean | Read files from disk |
| `edit` | boolean | Edit existing files |
| `write` | boolean | Create new files |
| `bash` | boolean | Execute shell commands |
| `grep` | boolean | Search file contents |
| `glob` | boolean | Find files by pattern |
| `fetch` | boolean | Fetch web pages |
| `search` | boolean | Search the web |
| `notebook` | boolean | Notebook operations |
| `subagent` | boolean | Dispatch sub-agents |

## Permission Values

| Value | Meaning |
|-------|---------|
| `allow` | Permission granted without confirmation |
| `ask` | User confirmation required |
| `deny` | Permission denied |
| `{pattern: value, ...}` | Pattern-based rules (for bash) |

## Mode Definitions

| Mode | Use Case |
|------|----------|
| `primary` | Top-level agent that can dispatch sub-agents |
| `subagent` | Agent designed to be called by another agent |
| `all` | Universal mode, works standalone or as sub-agent |
