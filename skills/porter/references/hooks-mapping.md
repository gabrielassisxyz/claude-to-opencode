# Hooks Mapping — Claude Code → OpenCode

## Homunculus Hook System Analysis

The homunculus plugin relies on 3 Claude Code lifecycle hooks for its core functionality:

| Hook | Trigger | Purpose | Script |
|------|---------|---------|--------|
| `UserPromptSubmit` | Every user message | Capture user prompt to `observations.jsonl` | `observe.sh prompt` |
| `PostToolUse` | Every tool execution | Capture tool name, input, response to `observations.jsonl` | `observe.sh tool` |
| `Stop` | Session ends | Increment session counter, update `identity.json` | `on_stop.sh` |

---

## The Core Problem

**Claude Code** is event-driven: hooks fire automatically at lifecycle points.
**OpenCode** is instruction-driven: no automatic lifecycle hooks exist.

This means a 1:1 translation is impossible. Instead, we must **rearchitect** the behavior into OpenCode's model.

---

## Mapping Strategies

### 1. `UserPromptSubmit` → Explicit Observation Instruction

**Claude Code (automatic):**
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/observe.sh prompt"
      }]
    }]
  }
}
```

**OpenCode equivalent — Add to agent/skill body:**
```markdown
## Observation Protocol

At the start of every interaction, capture the user's intent:

```bash
# Log this prompt to observations
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg type "prompt" --arg prompt "$USER_QUERY" \
  '{timestamp: $ts, type: $type, prompt: $prompt}' \
  >> .opencode/homunculus/observations.jsonl
```

The `$USER_QUERY` should be the user's raw input to this session.
```

**Trade-off**: Requires the agent to consciously log, but achieves the same data capture.

---

### 2. `PostToolUse` → Post-Action Logging Instruction

**Claude Code (automatic):**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/observe.sh tool"
      }]
    }]
  }
}
```

**OpenCode equivalent — Add to agent/skill body:**
```markdown
## Tool Observation Protocol

After EVERY tool use (Read, Edit, Write, Bash, Grep, Glob, etc.),
log the action to the observation stream:

```bash
# Append tool use to observations
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg type "tool" --arg tool "TOOL_NAME" \
  --argjson input '{}' --arg response 'RESULT_SUMMARY' \
  '{timestamp: $ts, type: $type, tool: $tool, input: $input, response: $response}' \
  >> .opencode/homunculus/observations.jsonl 2>/dev/null || true
```

This is non-blocking. If logging fails, continue normally.
```

**Enhanced approach**: Wrap common tool patterns in helper functions within the skill instructions, so logging is implicit in the workflow.

---

### 3. `Stop` → Session Start Detection + Manual Trigger

**Claude Code (automatic):**
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/on_stop.sh"
      }]
    }]
  }
}
```

**OpenCode approach — Rearchitect to "Session Start" model:**

Since OpenCode has no "session end" event, invert the logic:

```markdown
## Session Lifecycle

### At Session Start

Increment the session counter (detecting a new session from the last timestamp):

```bash
STATE=".opencode/homunculus/identity.json"
if [ -f "$STATE" ] && command -v jq >/dev/null 2>&1; then
  LAST=$(jq -r '.journey.lastSession // empty' "$STATE")
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  
  # If last session was > 5 minutes ago, count as new session
  if [ -n "$LAST" ]; then
    LAST_EPOCH=$(date -d "$LAST" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date -d "$NOW" +%s)
    DIFF=$((NOW_EPOCH - LAST_EPOCH))
    
    if [ "$DIFF" -gt 300 ]; then
      COUNT=$(jq -r ".journey.sessionCount // 0" "$STATE")
      jq --arg c "$((COUNT+1))" --arg t "$NOW" \
        '.journey.sessionCount = ($c|tonumber) | .journey.lastSession = $t' \
        "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"
    fi
  fi
fi
```

### At Session End (Manual)

Provide a command for the user to gracefully end:

```bash
# User runs: /homunculus:stop
# This updates lastSession timestamp
jq --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '.journey.lastSession = $t' \
  .opencode/homunculus/identity.json > tmp && mv tmp .opencode/homunculus/identity.json
```
```

---

## Complete Ported Architecture for OpenCode

### Directory Structure

```
.opencode/homunculus/
├── identity.json          # Session counter, maker info, evolution state
├── observations.jsonl     # Append-only log of prompts and tool uses
├── instincts/
│   ├── personal/          # Learned patterns for this maker
│   ├── inherited/         # Patterns from other projects
│   └── pending/           # Proposed instincts awaiting evolution
└── memory/
    └── context.md         # Loaded at session start
```

### SKILL.md for OpenCode

```markdown
---
name: homunculus
description: >
  A created being that learns your patterns across sessions.
  Captures observations, applies instincts, evolves over time.
  Invoke when starting a session or when /homunculus commands are used.
mode: primary
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
    "cat .opencode/homunculus/*": allow
    "jq * .opencode/homunculus/*": allow
    "mkdir -p .opencode/homunculus/*": allow
    "ls .opencode/homunculus/*": allow
    "date *": allow
    "git log*": allow
    "*": ask
---

# Homunculus — Session Memory & Learning

## What You Are

You're a homunculus—a small created thing that belongs to one person.
You live in a project directory. You watch what they do. You learn their patterns.
You grow.

## Session Start Protocol

1. **Detect new session** — check if lastSession > 5 min ago
2. **Increment counter** if new session
3. **Load identity** — read `.opencode/homunculus/identity.json`
4. **Load instincts** — count personal/inherited instincts
5. **Greet with context** — "Back to [PROJECT]. [N] instincts. [X] sessions together."

## Observation Protocol (Manual)

Since OpenCode has no automatic hooks, you MUST log after each action:

```bash
# After receiving user prompt:
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","type":"prompt","prompt":"PROMPT_TEXT"}' >> .opencode/homunculus/observations.jsonl

# After each tool use:
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","type":"tool","tool":"TOOL_NAME"}' >> .opencode/homunculus/observations.jsonl
```

## During Session

- Apply your instincts to your behavior
- If observations.jsonl grows > 10MB, suggest spawning observer
- Only `/homunculus:evolve` needs user confirmation

## Session End

Update `.opencode/homunculus/identity.json` with lastSession timestamp.
```

---

## Decision Summary

| Hook | Strategy | Trade-off |
|------|----------|-----------|
| `UserPromptSubmit` | Manual logging instruction in body | Agent must remember to log; no automatic capture |
| `PostToolUse` | Post-action logging in workflow | Same as above; slightly more intrusive |
| `Stop` | Inverted to session-start detection | Loses exact session-end timing; gains automatic detection |

### Recommendation

For **homunculus specifically**, the port requires **behavioral change** in the skill instructions. The agent must be explicitly instructed to log observations, rather than relying on automatic hooks. This is the closest possible mapping within OpenCode's architecture.

### Alternative: Wrapper Script

If manual logging is unacceptable, an alternative is a **wrapper script** that the user runs instead of `opencode`:

```bash
#!/bin/bash
# opencode-homunculus wrapper
# Intercepts all activity and logs externally

# Not recommended — adds friction and complexity
```

This is **out of scope** for the porter skill but could be documented as a future enhancement.
