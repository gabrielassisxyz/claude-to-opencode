# Hooks Mapping — Claude Code → OpenCode

## Overview

Claude Code has lifecycle hooks (`UserPromptSubmit`, `PostToolUse`, `Stop`) that fire
automatically. OpenCode does **not** have these hooks natively, but the **forked**
`opencode-yaml-hooks` plugin adds support for equivalent events.

**Fork:** https://github.com/gabrielassisxyz/OpenCode-Hooks

## Mapping Table

| Claude Code Hook | OpenCode Equivalent (forked plugin) | Fallback (no plugin) |
|------------------|-------------------------------------|---------------------|
| `UserPromptSubmit` | `message.part.updated` event | Manual logging in skill body |
| `PostToolUse` | `tool.after.*` event | Manual logging in skill body |
| `Stop` | `session.deleted` / `session.idle` | Inverted session-start detection |
| `PreToolUse` (security) | `permissions` block | `permissions` block |

## How the Fork Works

The forked `opencode-yaml-hooks` plugin adds `message.updated` and `message.part.updated`
events that are not available in the upstream plugin.

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

## Fallback (No Forked Plugin)

If the user cannot or does not want to install the forked plugin, the porter falls
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
# Install the forked plugin
bun add opencode-yaml-hooks@git+https://github.com/gabrielassisxyz/OpenCode-Hooks.git

# Add to ~/.config/opencode/opencode.json
{
  "plugin": [
    "opencode-yaml-hooks@git+https://github.com/gabrielassisxyz/OpenCode-Hooks.git"
  ]
}
```

## Notes

- The fork is a deliberate scope extension of the upstream plugin
- Upstream deliberately excludes message events (documented as "explicit non-goals")
- The fork could potentially be upstreamed via PR
- Without the fork, manual logging is the only option
