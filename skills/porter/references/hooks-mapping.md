# Hooks Mapping — Claude Code → OpenCode

## Overview

Claude Code has lifecycle hooks (`UserPromptSubmit`, `PostToolUse`, `Stop`) that fire
automatically. OpenCode does **not** have these hooks natively, but the
`@gabrielassisxyz/opencode-hooks` plugin adds support for equivalent events.

**Package:** `@gabrielassisxyz/opencode-hooks`
**Repository:** https://github.com/gabrielassisxyz/opencode-hooks

## Mapping Table

| Claude Code Hook | OpenCode Equivalent (via plugin) | Fallback (no plugin) |
|------------------|----------------------------------|---------------------|
| `UserPromptSubmit` | `message.part.updated` event | Manual logging in skill body |
| `PostToolUse` | `tool.after.*` event | Manual logging in skill body |
| `Stop` | `session.deleted` / `session.idle` | Inverted session-start detection |
| `PreToolUse` (security) | `permissions` block | `permissions` block |

## How the Plugin Works

The `@gabrielassisxyz/opencode-hooks` plugin adds `message.updated` and `message.part.updated`
events.

### Correlation Mechanism

The runtime correlates two events to capture user prompts reliably:

1. `message.updated` fires with `role` ("user" | "assistant") and `messageID`
2. `message.part.updated` fires with `messageID` and `text`

The runtime maintains a `Set<string>` of user message IDs:
- When `message.updated` has `role === "user"`, the `messageID` is stored
- When `message.part.updated` has a matching `messageID`, the hook dispatches
  with an enriched payload containing both `role: "user"` and the `text`

### Example hooks.yaml

```yaml
hooks:
  - id: capture-prompt
    event: message.part.updated
    scope: main
    actions:
      - bash: |
          payload=$(cat)
          text=$(echo "$payload" | jq -r '.text // empty')
          if [ -n "$text" ]; then
            echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"prompt\",\"prompt\":\"$text\"}" >> "$OPENCODE_PROJECT_DIR/.opencode/observations.jsonl"
          fi

  - id: capture-tool
    event: tool.after.*
    actions:
      - bash: |
          payload=$(cat)
          tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
          if [ -n "$tool_name" ]; then
            echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"tool\",\"tool\":\"$tool_name\"}" >> "$OPENCODE_PROJECT_DIR/.opencode/observations.jsonl"
          fi

  - id: session-start
    event: session.created
    scope: main
    actions:
      - bash: ./scripts/on_start.sh

  - id: session-end
    event: session.deleted
    scope: main
    actions:
      - bash: ./scripts/on_stop.sh
```

## Fallback (No Plugin)

If the user cannot or does not want to install the `@gabrielassisxyz/opencode-hooks` plugin, the porter falls
back to embedding manual logging instructions in the skill body:

```markdown
## Observation Protocol (Manual)

Since OpenCode has no automatic hooks, you MUST log after each action:

```bash
# After receiving user prompt:
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","type":"prompt","prompt":"PROMPT_TEXT"}' >> .opencode/observations.jsonl

# After each tool use:
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","type":"tool","tool":"TOOL_NAME"}' >> .opencode/observations.jsonl
```
```

## Installation

```bash
# Install the plugin
bun add @gabrielassisxyz/opencode-hooks
```

Add to `~/.config/opencode/opencode.json` (global) or `./.opencode/opencode.json` (local):
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "@gabrielassisxyz/opencode-hooks"
  ]
}
```

## Hook File Locations

- **Global:** `~/.config/opencode/hooks/hooks.yaml`
- **Local (project):** `./.opencode/hooks/hooks.yaml`
- **Specific directory:** `{dir_path}/.opencode/hooks/hooks.yaml`

## Notes

- The `@gabrielassisxyz/opencode-hooks` plugin extends the original `opencode-yaml-hooks` with message events
- The upstream `opencode-yaml-hooks` deliberately excludes message events (documented as "explicit non-goals")
- Without the `@gabrielassisxyz/opencode-hooks` plugin, manual logging is the only option
