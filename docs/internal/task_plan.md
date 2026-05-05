# Task Plan — Claude Code to OpenCode Porter

## Core Skill Implementation

- [x] Create skill directory structure (`skills/porter/`)
- [x] Write `SKILL.md` with complete workflow, mapping rules, and examples
- [x] Create `scripts/detect-source-type.sh`
- [x] Create `scripts/parse-frontmatter.sh`
- [x] Create `scripts/validate-output.sh`
- [x] Create `references/tool-mapping.md`
- [x] Create `references/permission-templates.md`
- [x] Create `references/opencode-schema.md`

## Companion Files & Integration

- [x] Create companion command file (`command/porter.md` or `commands/porter.md`)
- [x] Create `porter-report.md` template/example
- [x] Add test/example inputs and expected outputs under `examples/`
- [x] Validate generated artifacts against OpenCode format requirements
- [x] Final review and README update

## Hooks Support (Post-v1 Discovery)

- [x] Research Claude Code hooks system (UserPromptSubmit, PostToolUse, Stop)
- [x] Analyze homunculus hooks.json and scripts (observe.sh, on_stop.sh)
- [x] Create `references/hooks-mapping.md` with translation strategies
- [x] Update `SKILL.md` with hook translation rules (section 3.9)
- [x] Update PRD to reflect hooks are mappable (not out-of-scope)

## Real-World Port: Homunculus Plugin

- [x] Analyze all homunculus artifacts (skills, agents, commands, hooks, scripts)
- [x] Port main skill `homunculus` (combines session-memory + CLAUDE.md)
- [x] Port observer agent to `agent/homunculus-observer.md`
- [x] Port commands: init, status, evolve
- [x] Translate hooks to manual instructions in skill body
- [x] Create `PORT-TEST.md` with test plan and limitations
- [x] Validate all ported files

## Phase: OpenCode YAML Hooks Integration (Homunculus)

> **Goal:** Replace manual observation instructions with automatic hooks using the `opencode-yaml-hooks` plugin, eliminating the need for the user to manually invoke the homunculus skill every time.

### Implementation Plan

- [ ] Install and configure `opencode-yaml-hooks` plugin in `~/.config/opencode/`
- [ ] Create `hooks.yaml` for homunculus capturing:
  - [ ] `tool.after.*` → run `observe.sh tool` (capture tool name, args, result)
  - [ ] `session.created` → run `on_start.sh` (detect new session, increment counter, load context)
  - [ ] `session.idle` / `session.deleted` → run `on_stop.sh` (update lastSession timestamp)
- [ ] Adapt existing homunculus shell scripts (`observe.sh`, `on_stop.sh`) to work with yaml-hooks payload format (JSON over stdin + env vars)
- [ ] Update `skills/homunculus/SKILL.md` to remove manual observation instructions and rely on hooks
- [ ] Update `PORT-TEST.md` with new test flow (automatic vs manual)
- [ ] Validate end-to-end: run OpenCode, execute tools, verify `observations.jsonl` is populated automatically

### Phase 1 Results: Message Events CONFIRMED ✅

**Status:** COMPLETED — OpenCode emits message events through the plugin API.

**Findings:**
- OpenCode emits `message.updated`, `message.part.updated`, `message.part.delta`, `session.updated`, `session.diff`, `session.status`
- The event `message.part.updated` contains the **full prompt text** in `properties.part.text`
- Example payload:
  ```json
  {
    "type": "message.part.updated",
    "properties": {
      "part": {
        "type": "text",
        "text": "say hello",
        "messageID": "msg_...",
        "sessionID": "ses_..."
      }
    }
  }
  ```
- The `yaml-hooks` plugin **does NOT listen** to these events (deliberately out of scope per authors)
- **Conclusion:** Fork of `yaml-hooks` is viable and necessary. See `docs/opencode-hooks-fork-plan.md`.

### Fork Plan: opencode-yaml-hooks with Message Support

**Repository:** `reference-repos/OpenCode-Hooks/`

- [ ] Fork `OpenCode-Hooks` to add `message.part.updated` event
  - [ ] Add `"message.part.updated"` to `SESSION_HOOK_EVENTS` in `src/core/types.ts`
  - [ ] Add handler in `src/core/runtime.ts` to extract `properties.part.text`
  - [ ] Extend `BashHookContext` in `src/core/bash-types.ts` with message fields
  - [ ] Update `src/core/load-hooks.ts` validation (no path conditions, allow async)
  - [ ] Add tests in `test/runtime.test.ts`
  - [ ] Update `docs/hooks-v2-reference.md`
- [ ] Build and install the forked plugin
- [ ] Create `hooks.yaml` for homunculus with all events:
  - `message.part.updated` → capture user prompt
  - `tool.after.*` → capture tool usage
  - `session.created` → detect new session
  - `session.deleted` → session end cleanup
- [ ] Adapt homunculus shell scripts to new payload format
- [ ] Update `skills/homunculus/SKILL.md` to remove manual observation instructions
- [ ] Validate end-to-end

## Optional / Future

- [ ] opencode-power-pack.js plugin loader support
- [ ] Reverse porting (OpenCode → Claude Code)
- [ ] Batch-mode shell driver script
