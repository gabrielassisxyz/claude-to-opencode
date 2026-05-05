# Task Plan — OpenCode-Hooks Fork: UserPromptSubmit Support

## Context

The `opencode-yaml-hooks` plugin (OpenCode-Hooks) supports session and tool lifecycle events but **deliberately excludes message/prompt events**. The goal of this fork is to add `message.updated` (or equivalent) event support to enable automatic capture of user prompts — critical for the homunculus plugin's observation system.

**Decision:** We will fork `OpenCode-Hooks` and add native support for message events. This keeps everything in yaml-hooks (consistent, single technology, no workarounds).

---

## Phase 1: Verify OpenCode Emits Message Events

**Status:** ✅ COMPLETED

**Findings:**
- OpenCode emits `message.updated`, `message.part.updated`, `message.part.delta`, `session.updated`, `session.diff`, `session.status` through the plugin API
- `message.updated` contains `role` ("user" | "assistant") and `messageID`, but **no text**
- `message.part.updated` contains `messageID` and `part.text`, but **no role**
- **Both events are needed together** to reliably capture user prompts

---

## Phase 2: Fork Implementation

**Goal:** Add `message.updated` and `message.part.updated` event support to the yaml-hooks plugin, with the runtime correlating the two to provide a clean `prompt.submitted` experience.

### Design

The runtime will maintain a lightweight in-memory state (a `Set<string>` of user message IDs):

```
message.updated (role="user", id="msg_123")  →  Add "msg_123" to userMessageIds Set
                                                      ↓
message.part.updated (id="msg_123", text="hi")  →  Check Set → match! → Dispatch hook
                                                      ↓
Hook bash script receives enriched payload with role="user" and the text
```

This approach:
- Requires no temp files or external state
- Is fast (Set lookup is O(1))
- Is reliable (correlates by messageID, not heuristics)
- Keeps the bash script simple (receives a single, complete payload)

### Files to Modify

#### 2.1 Add events to type system
**File:** `src/core/types.ts`
- Add `"message.updated"` and `"message.part.updated"` to `SESSION_HOOK_EVENTS` array
- Update `isHookEvent()` validation guard to recognize both

#### 2.2 Add state tracking for user messages
**File:** `src/core/session-state.ts` (or new file `src/core/message-state.ts`)
- Add `userMessageIds: Set<string>` to track which messageIDs belong to the user
- Add functions: `markUserMessage(id: string)`, `isUserMessage(id: string): boolean`

#### 2.3 Listen for events in runtime
**File:** `src/core/runtime.ts`
- In the `event()` method, add branches for:
  - `message.updated`: if `role === "user"`, add messageID to `userMessageIds`
  - `message.part.updated`: if `type === "text"` and messageID is in `userMessageIds`, build enriched context and call `dispatchHooks()`
- Enriched context for `message.part.updated` includes:
  - `session_id`
  - `event: "message.part.updated"`
  - `message_id`
  - `role: "user"` (inferred from state)
  - `text` (the prompt text)

#### 2.4 Define bash context
**File:** `src/core/bash-types.ts`
- Extend `BashHookContext` for message events:
  ```typescript
  {
    session_id: string
    event: "message.updated" | "message.part.updated"
    message_id: string
    role?: "user" | "assistant"
    text?: string
  }
  ```

#### 2.5 Update validation logic
**File:** `src/core/load-hooks.ts`
- `supportsPathConditions()`: message events do NOT support path conditions
- `parseAsync()`: allow `async: true` for message events (non-blocking)
- `parseHookAction()`: `action: stop` is NOT supported for message events
- Add validation: message events cannot use `matchesCodeFiles` or path conditions

#### 2.6 Add tests
**File:** `test/runtime.test.ts`
- Test: `message.updated` with `role="user"` adds messageID to state
- Test: `message.updated` with `role="assistant"` does NOT add to state
- Test: `message.part.updated` with user messageID dispatches hook with enriched payload
- Test: `message.part.updated` with assistant messageID does NOT dispatch user hook
- Test: bash action receives correct `text` and `role` fields

#### 2.7 Update documentation
**File:** `docs/hooks-v2-reference.md`
- Add `message.updated` and `message.part.updated` to supported events
- Document that `message.part.updated` is the practical event for capturing prompts
- Document payload shape for both events
- Provide homunculus example:
  ```yaml
  hooks:
    - id: capture-user-prompt
      event: message.part.updated
      scope: main
      actions:
        - bash: |
            payload=$(cat)
            text=$(echo "$payload" | jq -r '.text // empty')
            echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"prompt\",\"prompt\":\"$text\"}" >> .opencode/homunculus/observations.jsonl
  ```

#### 2.8 Update comparison doc
**File:** `docs/comparison-with-claude-code-hooks.md`
- Add `UserPromptSubmit` → `message.part.updated` mapping
- Note that this requires the fork (not upstream)
- Explain the correlation mechanism (runtime state)

**Estimated Time:** 2-3 hours

---

## Phase 3: Integration with Homunculus

**Goal:** Update the homunculus port to use the forked yaml-hooks plugin for fully automatic observation capture.

### Steps

- [ ] Build forked plugin: `bun run build`
- [ ] Install forked plugin in OpenCode (local path or npm link)
- [ ] Create `hooks.yaml` for homunculus:
  ```yaml
  hooks:
    - id: homunculus-capture-prompt
      event: message.part.updated
      scope: main
      actions:
        - bash: ./scripts/observe.sh prompt

    - id: homunculus-capture-tool
      event: tool.after.*
      actions:
        - bash: ./scripts/observe.sh tool

    - id: homunculus-session-start
      event: session.created
      scope: main
      actions:
        - bash: ./scripts/on_start.sh

    - id: homunculus-session-end
      event: session.deleted
      scope: main
      actions:
        - bash: ./scripts/on_stop.sh
  ```
- [ ] Adapt `observe.sh` to new payload format:
  - `prompt` mode: read JSON from stdin, extract `.text`, log to observations
  - `tool` mode: read JSON from stdin, extract `.tool_name` and `.tool_args`, log to observations
- [ ] Adapt `on_start.sh` and `on_stop.sh` to use `OPENCODE_SESSION_ID` env var
- [ ] Update `skills/homunculus/SKILL.md`:
  - Remove manual observation instructions
  - Add note that observations are captured automatically by yaml-hooks
  - Keep instructions for invoking observer and evolution
- [ ] Update `PORT-TEST.md` with new test flow
- [ ] Validate end-to-end:
  1. Start OpenCode
  2. Type a prompt
  3. Verify `.opencode/homunculus/observations.jsonl` contains the prompt
  4. Run a tool (e.g., `ls`)
  5. Verify tool usage is logged
  6. End session
  7. Verify `identity.json` has updated session count

**Estimated Time:** 1-2 hours

---

## Rejected Alternatives (Documented for Reference)

### Plugin TypeScript Custom
- A separate `.ts` plugin that listens to events and calls scripts
- **Rejected:** Creates a second technology stack; harder to maintain than a single yaml-hooks fork

### Temp File State (yaml-hooks without fork)
- Use `/tmp/opencode-user-msgids.txt` as shared state between `message.updated` and `message.part.updated` hooks
- **Rejected:** Race conditions possible; fragile; feels like a workaround, not a solution

### OpenCode Core Fork
- Fork `anomalyco/opencode` itself to add hooks
- **Rejected:** Massive effort; high maintenance; overkill for this use case

### Wrapper Script (PTY)
- Wrap OpenCode TUI in a pseudo-terminal and parse output
- **Rejected:** Fragile; breaks with UI changes; cannot extract structured data reliably

---

## Repository & Tooling

- **Fork location:** `/home/gabriel/repositories/claude-to-opencode/reference-repos/OpenCode-Hooks/`
- **Upstream:** https://github.com/KristjanPikhof/OpenCode-Hooks
- **Build target:** Bun (`--target bun`)
- **Test runner:** Vitest
- **OpenCode version:** 1.14.39

---

## Success Criteria

- [ ] Fork builds without errors
- [ ] All original tests pass
- [ ] New tests for message events pass
- [ ] `hooks.yaml` with `message.part.updated` works in OpenCode
- [ ] User prompts are captured automatically (no manual skill invocation)
- [ ] Tool usage is captured automatically
- [ ] Session start/end triggers automatically
- [ ] Homunculus observation log is populated without user intervention

---

*Created: 2026-05-05*
*Updated: 2026-05-05*
*Status: Phase 1 complete, Phase 2 ready for implementation*
