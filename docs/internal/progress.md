# Progress Log — Claude Code to OpenCode Porter

## 2026-05-05

### Task: Create companion command file
- **Status**: completed
- **Details**: Created `commands/porter.md` with usage examples, target format options, and description of the porter workflow.
- **Files changed**: `commands/porter.md`

### Task: Create porter-report.md template/example
- **Status**: completed
- **Details**: Created `porter-report.md` with full report structure: summary table, transformations log, decisions made, warnings, validation results, file tree, and attribution.
- **Files changed**: `porter-report.md`

### Task: Add test/example inputs and expected outputs under examples/
- **Status**: completed
- **Details**: Created 4 input examples (code-review skill, feature-dev skill, explorer agent, docs command) and their corresponding expected outputs in both Power Pack and Native Agent formats.
- **Files changed**:
  - `examples/input/code-review-SKILL.md`
  - `examples/input/feature-dev-SKILL.md`
  - `examples/input/explorer-agent.md`
  - `examples/input/docs-command.md`
  - `examples/output-powerpack/skills/code-review/SKILL.md`
  - `examples/output-powerpack/skills/feature-dev/SKILL.md`
  - `examples/output-native/agent/code-review.md`
  - `examples/output-native/agent/docs.md`
  - `examples/output-native/agent/explorer.md`
  - `examples/output-native/agent/feature-dev.md`

### Task: Validate generated artifacts against OpenCode format requirements
- **Status**: completed
- **Details**: Ran `validate-output.sh` against all generated example outputs. All 5 files passed validation (VALID).
- **Files changed**: none (validation only)

### Task: Final review and README update
- **Status**: completed
- **Details**: Created comprehensive `README.md` covering: what it does, mapping highlights, project structure, usage instructions, output formats, decision points, temperature heuristics, and validation checklist.
- **Files changed**: `README.md`

### Task: Research and map Claude Code hooks to OpenCode
- **Status**: completed
- **Details**: Analyzed homunculus hooks.json (UserPromptSubmit, PostToolUse, Stop) and corresponding scripts (observe.sh, on_stop.sh). Determined OpenCode has no automatic lifecycle hooks. Created mapping strategies: manual logging instructions in body, session-start detection (inverting Stop hook), and permissions block for PreToolUse security. Documented full translation with homunculus-specific example.
- **Files changed**: `references/hooks-mapping.md`, `skills/porter/SKILL.md` (added section 3.9), `docs/prd-claude-to-opencode-porter.md`

### Task: Port homunculus plugin to OpenCode
- **Status**: completed
- **Details**: Ported the complete homunculus plugin from Claude Code to OpenCode format. Main skill combines session-memory + CLAUDE.md meta-prompt. Observer agent converted to subagent with explicit permissions. Commands (init, status, evolve) preserved. All paths changed from `.claude/` to `.opencode/`. Hooks translated to manual observation instructions in skill body. Created PORT-TEST.md documenting critical limitations: manual invocation required, no true session end detection, best-effort logging.
- **Files changed**:
  - `skills/homunculus/SKILL.md`
  - `agent/homunculus-observer.md`
  - `commands/homunculus-init.md`
  - `commands/homunculus-status.md`
  - `commands/homunculus-evolve.md`
  - `skills/homunculus/PORT-TEST.md`

### Task: Phase 1 — Verify OpenCode emits message events
- **Status**: completed
- **Details**: Created a minimal TypeScript plugin (`event-logger.ts`) that listens to all OpenCode plugin events and logs them. Ran `opencode run` to trigger events. Discovered that OpenCode emits `message.updated`, `message.part.updated`, `message.part.delta`, `session.updated`, `session.diff`, and `session.status` through the plugin API. The `message.part.updated` event contains the full prompt text in `properties.part.text`. Confirmed that yaml-hooks deliberately excludes these events (explicit non-goals). Fork is viable.
- **Files changed**: `~/.config/opencode/plugins/event-logger.ts`, `docs/opencode-hooks-fork-plan.md`
- **Key finding**: `message.part.updated` payload contains user prompt text:
  ```json
  {"properties":{"part":{"type":"text","text":"say hello","messageID":"msg_...","sessionID":"ses_..."}}}
  ```

## 2026-05-05 (Update)

### Task: Rename plugin references from fork to `@gabrielassisxyz/opencode-hooks`
- **Status**: completed
- **Details**: Updated all project files to reference the published npm package `@gabrielassisxyz/opencode-hooks` instead of the git fork. Added auto-detection instructions in SKILL.md. Documented global/local/specific hook installation paths. Updated AGENTS.md, README.md, hooks-mapping.md, commands/porter.md, and homunculus-port files.
- **Files changed**: `skills/porter/SKILL.md`, `skills/porter/references/hooks-mapping.md`, `commands/porter.md`, `README.md`, `AGENTS.md`, `examples/homunculus-port/SKILL.md`, `examples/homunculus-port/PORT-TEST.md`

### Previously Completed
- Created skill directory structure (`skills/porter/`)
- Wrote `SKILL.md` with complete workflow, mapping rules, and examples
- Created `scripts/detect-source-type.sh`
- Created `scripts/parse-frontmatter.sh`
- Created `scripts/validate-output.sh`
- Created `references/tool-mapping.md`
- Created `references/permission-templates.md`
- Created `references/opencode-schema.md`
