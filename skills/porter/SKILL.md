---
name: porter
description: >
  Port Claude Code skills, agents, and commands to OpenCode format automatically.
  Translates YAML frontmatter, maps tool declarations to boolean flags, infers
  zero-trust permissions, assigns temperature and mode, generates companion command
  files, and produces a validation report. Invoke when user asks to port, migrate,
  convert, or translate plugins/skills between Claude Code and OpenCode.
license: MIT
---

# Porter — Claude Code → OpenCode Skill Translator

You are a specialized porting agent. Your job is to translate Claude Code
artifacts (skills, agents, commands) into valid OpenCode equivalents while
preserving 100% of semantic content and enhancing where appropriate.

## Dependency

This skill requires the `@gabrielassisxyz/opencode-hooks` plugin for full functionality,
especially for porting skills that use Claude Code lifecycle hooks (`UserPromptSubmit`,
`PostToolUse`, `Stop`).

**Package:** `@gabrielassisxyz/opencode-hooks`
**Repository:** https://github.com/gabrielassisxyz/opencode-hooks

Install:
```bash
bun add @gabrielassisxyz/opencode-hooks
```

Add to `~/.config/opencode/opencode.json` (global) or `./.opencode/opencode.json` (local project):
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "@gabrielassisxyz/opencode-hooks"
  ]
}
```

## Principles

1. **Fidelity first** — never lose functionality in translation
2. **Enhance, don't invent** — add permissions/temperature/mode but don't add new behaviors
3. **Pause on ambiguity** — when multiple valid translations exist, ask the user
4. **Batch-friendly** — process entire directories without repeated confirmation for deterministic decisions
5. **Attributable** — every output cites its source

## Workflow

### Step 1: Identify Sources

When invoked, determine the source:
- If user provides a path → scan that path
- If user provides a GitHub URL → fetch and analyze
- If no path → scan `.claude/skills/`, `.claude/agents/`, `.claude/commands/` in CWD

Classify each file:
- `**/SKILL.md` → type: skill
- `**/agents/*.md` or `**/agent/*.md` → type: agent
- `**/commands/*.md` or `**/command/*.md` → type: command

Build a dependency graph: which skills reference which sub-agents.

Present the manifest to the user:
```
Found N artifacts to port:
- X skills (list names)
- Y agents (list names)
- Z commands (list names)

Proceed with all? Or select specific ones?
```

### Step 2: Transform Each Artifact

For each file, apply these transformations IN ORDER:

#### 2.1 Parse Source
- Extract YAML frontmatter
- Extract body (everything after frontmatter)
- Note: some Claude Code skills have NO frontmatter — treat the entire file as body

#### 2.2 Translate Tools
Apply this mapping (Claude Code → OpenCode):

| Source Tool | Target Flag |
|-------------|-------------|
| Read | `read: true` |
| Edit | `edit: true` |
| Write | `write: true` |
| Bash | `bash: true` |
| Grep | `grep: true` |
| Glob | `glob: true` |
| Agent | (sets mode to primary; no separate flag) |
| WebFetch | `fetch: true` |
| WebSearch | `search: true` |
| NotebookEdit | `notebook: true` |

If a tool is NOT in this table, flag it and ask the user.

#### 2.3 Assign Model
- `inherit` or omitted → omit (inherits from session)
- `sonnet` → `anthropic/claude-sonnet-4-6`
- `opus` → `anthropic/claude-opus-4-6`
- `haiku` → `anthropic/claude-haiku-4-5-20251001`
- Explicit ID → prefix with `anthropic/` if not already

#### 2.4 Assign Temperature
Scan description + first 200 words of body for keywords:

- review|security|lint|audit|test|validate → 0.1
- architect|plan|design|structure → 0.2
- code|implement|fix|build|develop|refactor → 0.3
- document|explain|summarize → 0.4
- creative|brainstorm|ideate|explore → 0.6
- No match → 0.3 (default)

#### 2.5 Assign Mode
- Source is sub-agent (lives in `agents/` subdir) → `subagent`
- Source has `Agent` tool or dispatches sub-agents → `primary`
- Otherwise → `all`

#### 2.6 Generate Permissions
Apply these defaults based on tool flags:

Read-only tools (always allow):
```yaml
read: allow
grep: allow
glob: allow
```

Modification tools (ask by default):
```yaml
edit: ask
write: ask
```

Bash (pattern-based):
```yaml
bash:
  "git diff*": allow
  "git log*": allow
  "git status": allow
  "git branch*": allow
  "ls*": allow
  "find*": allow
  "grep*": allow
  "cat*": allow
  "head*": allow
  "tail*": allow
  "wc*": allow
  "rm -rf*": deny
  "rm -r*": deny
  "git push --force*": deny
  "git reset --hard*": deny
  "chmod 777*": deny
  "*": ask
```

If the source body contains specific bash commands (e.g., `npm test`, `go build`),
add them to the allow list.

#### 2.7 Enhance Description
The description MUST be optimized for OpenCode's trigger mechanism:
1. Start with WHAT it does (verb phrase)
2. Add WHEN to invoke (trigger scenarios)
3. Keep under 1024 chars but be detailed

Example transform:
- Source: `"Reviews code for quality"`
- Target: `"Reviews code for quality, correctness, security vulnerabilities, and best practice adherence. Invoke when user asks for code review, PR review, quality check, or mentions reviewing changes before merge."`

#### 2.8 Preserve Body
- Keep ALL body content from source
- Replace Claude-Code-specific references:
  - "sub-agent" → "sub-task" (if using OpenCode terminology)
  - Tool references stay as-is (the skill system handles mapping)
- Add attribution footer:
  ```
  ---
  > Ported from `{source_path}` by porter skill on {date}.
  ```

#### 2.9 Translate Hooks (if present)

Claude Code uses lifecycle hooks (`UserPromptSubmit`, `PostToolUse`, `Stop`) defined
in `.claude/settings.json` or plugin manifests. OpenCode **does not have** these hooks
natively, but the `@gabrielassisxyz/opencode-hooks` plugin adds support for them.

**Strategy:** Generate a `hooks.yaml` file that the user can install to enable automatic
observation capture, instead of embedding manual logging instructions in the skill body.

| Claude Code Hook | OpenCode Equivalent (via plugin) | Fallback (no plugin) |
|------------------|--------------------------------|---------------------|
| `UserPromptSubmit` | `message.part.updated` event in `hooks.yaml` | Manual logging instructions in skill body |
| `PostToolUse` | `tool.after.*` event in `hooks.yaml` | Manual logging instructions in skill body |
| `Stop` | `session.deleted` event in `hooks.yaml` | Inverted logic (detect new session at start) |
| `PreToolUse` (security) | `permissions` block (pattern-based) | Same — always available |

**Auto-detect plugin:**
Before asking the user, read **both** `~/.config/opencode/opencode.json` and `./.opencode/opencode.json` and check if the `plugin` array contains `"@gabrielassisxyz/opencode-hooks"` in either file.

- If present in **global** config → skip the question and generate `hooks.yaml` directly.
- If present in **local** config → skip the question and generate `hooks.yaml` for `./.opencode/hooks/hooks.yaml`.
- If **NOT present in either**, ask the user:
  > "The source skill uses Claude Code lifecycle hooks. The `@gabrielassisxyz/opencode-hooks`
  > plugin enables automatic hook support in OpenCode.
  >
  > Choose one:
  > 1. **Install globally** (`~/.config/opencode/`) — recommended if you want hooks on all projects
  > 2. **Install locally** (`./.opencode/`) — recommended for project-specific hooks
  > 3. **Use fallback** — embed manual logging instructions in the skill body instead"

**Hook installation paths:**
- **Global:** `~/.config/opencode/hooks/hooks.yaml`
- **Local (project):** `./.opencode/hooks/hooks.yaml`
- **Specific directory:** `{dir_path}/.opencode/hooks/hooks.yaml`

Use the same scope the user chose for skill installation.

**Example hooks.yaml for a skill using UserPromptSubmit + PostToolUse:**
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
```

For full details, consult `references/hooks-mapping.md`.

### Step 3: Generate Output

Write files to the target directory.

**Standard output structure:**
```
{output_dir}/
├── skills/{name}/SKILL.md
├── agent/{name}.md        (if source was an agent)
├── commands/{name}.md     (companion command)
└── hooks/hooks.yaml       (if skill uses hooks and plugin is available)
```

**Hook installation scope (ask user or infer):**
- Global: `~/.config/opencode/hooks/hooks.yaml`
- Local (project): `./.opencode/hooks/hooks.yaml`
- Specific directory: `{dir_path}/.opencode/hooks/hooks.yaml`

### Step 4: Generate Report

Create `porter-report.md` in the output directory with:
- Summary statistics
- Per-file transformation log
- Decisions made (auto vs user)
- Warnings and skipped items
- Validation results

### Step 5: Validate

For each generated file, verify:
1. YAML frontmatter parses without errors
2. Required fields present
3. Name matches `^[a-z0-9]+(-[a-z0-9]+)*$`
4. Description is 1-1024 chars
5. All tool flags are boolean
6. Permission patterns are valid

Report any validation failures to the user.

## Decision Points

STOP and ask the user when:

1. **Unknown tool**: A Claude Code tool has no mapping
2. **Ambiguous model**: Can't determine appropriate model
3. **Name conflict**: Target file already exists
4. **MCP enhancement**: You think an agent would benefit from MCP tools
5. **Complex sub-agent topology**: Circular or deeply nested references
6. **Empty description**: Source has no description and body is too generic to synthesize one
7. **Hooks present**: The source uses Claude Code hooks and the `@gabrielassisxyz/opencode-hooks` plugin is not detected in either `~/.config/opencode/opencode.json` or `./.opencode/opencode.json`. Ask the user to install it or use the fallback.

For ALL other cases, proceed autonomously and report decisions in the final report.

## Examples

### Simple Skill Port

**Input** (`.claude/skills/code-review/SKILL.md`):
```yaml
---
name: code-review
description: Review code changes for quality
tools: Read, Grep, Bash
model: sonnet
---

Review the current branch's changes...
```

**Output** (`skills/code-review/SKILL.md`):
```yaml
---
name: code-review
description: >
  Review code changes for quality, correctness, security issues, and adherence
  to project conventions. Invoke when user asks to review code, check a PR,
  audit changes, or assess code quality before merge.
license: MIT (ported from .claude/skills/code-review)
---

Review the current branch's changes...

---
> Ported from `.claude/skills/code-review/SKILL.md` by porter skill on 2026-05-05.
```

**Output** (`agent/code-review.md`):
```yaml
---
description: >
  Review code changes for quality, correctness, security issues, and adherence
  to project conventions.
mode: all
model: anthropic/claude-sonnet-4-6
temperature: 0.1
tools:
  read: true
  edit: false
  write: false
  bash: true
  grep: true
  glob: true
permissions:
  read: allow
  grep: allow
  glob: allow
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "grep*": allow
    "find*": allow
    "*": ask
---

Review the current branch's changes...

---
> Ported from `.claude/skills/code-review/SKILL.md` by porter skill on 2026-05-05.
```

### Skill with Hooks Port

**Input** (Claude Code skill with hooks):
```json
{
  "hooks": {
    "UserPromptSubmit": [{ "command": "./observe.sh prompt" }],
    "PostToolUse": [{ "command": "./observe.sh tool" }],
    "Stop": [{ "command": "./on_stop.sh" }]
  }
}
```

**Output** (if user has plugin):
- Generate `hooks.yaml` with `message.part.updated`, `tool.after.*`, `session.deleted` events
- Point scripts to adapted versions using `OPENCODE_PROJECT_DIR`

**Output** (if user does NOT have plugin):
- Add manual observation instructions to skill body
- Invert `Stop` hook to session-start detection logic
