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

> **Goal:** Replace manual observation instructions with automatic hooks using the `@gabrielassisxyz/opencode-hooks` plugin, eliminating the need for the user to manually invoke the homunculus skill every time.

### Implementation Plan

- [x] Install and configure `@gabrielassisxyz/opencode-hooks` plugin in `~/.config/opencode/`
- [x] Create `hooks.yaml` for homunculus capturing:
  - [x] `tool.after.*` → run `observe.sh tool` (capture tool name, args, result)
  - [x] `session.created` → run `on_start.sh` (detect new session, increment counter, load context)
  - [x] `session.idle` / `session.deleted` → run `on_stop.sh` (update lastSession timestamp)
- [x] Adapt existing homunculus shell scripts (`observe.sh`, `on_stop.sh`) to work with hooks payload format (JSON over stdin + env vars)
- [x] Update `skills/homunculus/SKILL.md` to remove manual observation instructions and rely on hooks
- [x] Update `PORT-TEST.md` with new test flow (automatic vs manual)
- [x] Validate end-to-end: run OpenCode, execute tools, verify `observations.jsonl` is populated automatically

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
- **Conclusion:** Use `@gabrielassisxyz/opencode-hooks` package. See `docs/opencode-hooks-fork-plan.md` for historical context.

### Plugin Plan: opencode-hooks with Message Support

**Repository:** https://github.com/gabrielassisxyz/opencode-hooks

- [x] Extend `opencode-yaml-hooks` with `message.part.updated` event in `@gabrielassisxyz/opencode-hooks`
  - [x] Add `"message.part.updated"` to `SESSION_HOOK_EVENTS` in `src/core/types.ts`
  - [x] Add handler in `src/core/runtime.ts` to extract `properties.part.text`
  - [x] Extend `BashHookContext` in `src/core/bash-types.ts` with message fields
  - [x] Update `src/core/load-hooks.ts` validation (no path conditions, allow async)
  - [x] Add tests in `test/runtime.test.ts`
  - [x] Update `docs/hooks-v2-reference.md`
- [x] Build and publish `@gabrielassisxyz/opencode-hooks` on npm
- [x] Create `hooks.yaml` for homunculus with all events:
  - `message.part.updated` → capture user prompt
  - `tool.after.*` → capture tool usage
  - `session.created` → detect new session
  - `session.deleted` → session end cleanup
- [x] Adapt homunculus shell scripts to new payload format
- [x] Update `skills/homunculus/SKILL.md` to remove manual observation instructions
- [x] Validate end-to-end

## Optional / Future

- [ ] opencode-power-pack.js plugin loader support
- [ ] Reverse porting (OpenCode → Claude Code)
- [ ] Batch-mode shell driver script
