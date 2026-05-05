# AGENTS.md — Claude-to-OpenCode Porter

> **Context for AI agents and human contributors.**
> This file provides everything needed to understand, use, test, and modify this project.

---

## What This Project Is

A skill and tooling to automatically port Claude Code artifacts (skills, agents, commands) to the OpenCode format.

**Repository:** https://github.com/YOUR_USERNAME/claude-to-opencode
**License:** MIT

### Core Problem

Claude Code and OpenCode share the same philosophy (skills as Markdown + YAML frontmatter) but diverge in:
- Directory structure (`agents/` vs `agent/`, plural vs singular)
- Frontmatter schema (simple vs rich)
- Permission model (trust-based vs zero-trust)
- Tool declarations (CSV list vs boolean flags)
- Trigger mechanism (CLAUDE.md entries vs `description` field)
- Hooks (Claude Code has lifecycle hooks; OpenCode historically did not)

This porter automates the translation between these formats.

### Key Dependency

This project depends on a **fork** of `opencode-yaml-hooks` that adds `message.updated` and `message.part.updated` events:
- **Fork:** https://github.com/gabrielassisxyz/OpenCode-Hooks
- **Why:** The upstream plugin deliberately excludes message events. Our fork adds them to support automatic prompt capture (critical for plugins like homunculus).

---

## Repository Structure

```
claude-to-opencode/
├── skills/porter/                 ← THE PRODUCT (main skill)
│   ├── SKILL.md                   # Complete workflow, mapping rules, examples
│   ├── scripts/
│   │   ├── detect-source-type.sh  # Classify input files
│   │   ├── parse-frontmatter.sh   # Extract YAML from Markdown
│   │   └── validate-output.sh     # Lint generated files
│   └── references/
│       ├── tool-mapping.md        # Canonical tool translation table
│       ├── permission-templates.md # Default permission blocks
│       ├── hooks-mapping.md       # Claude Code hooks → OpenCode strategies
│       └── opencode-schema.md     # Target format reference
│
├── commands/porter.md             # Slash command definition
│
├── examples/
│   ├── input/                     # Sample Claude Code artifacts
│   ├── output-powerpack/          # Expected Power Pack output
│   └── output-native/             # Expected Native Agent output
│   └── homunculus-port/           # FULL PORT EXAMPLE (showcase)
│       ├── SKILL.md               # Ported homunculus skill
│       └── scripts/               # Adapted shell scripts
│
├── docs/
│   ├── prd-claude-to-opencode-porter.md      # Product Requirements
│   ├── spec-porter-skill.md                  # Technical specification
│   ├── spec-porter-SKILL-draft.md            # Draft skill content
│   ├── opencode-hooks-fork-plan.md           # Fork implementation plan
│   └── internal/                             # Development logs
│       ├── progress.md
│       ├── task_plan.md
│       └── porter-report.md
│
├── README.md                      # Public landing page
└── AGENTS.md                      # This file
```

### What Goes Where

| Directory | Purpose |
|-----------|---------|
| `skills/porter/` | **The product.** Main skill definition + scripts + references. |
| `commands/porter.md` | Slash command companion for the skill. |
| `examples/` | Showcases and test fixtures. `homunculus-port/` is a complete real-world example. |
| `docs/` | Public documentation (PRD, specs, architecture). |
| `docs/internal/` | Development logs (progress, plans, reports). Not critical for users. |
| `README.md` | First thing visitors see. Quick start, features, installation. |
| `AGENTS.md` | This file. Context for AI agents and deep-dive contributors. |

---

## How to Use the Porter

### Installation

```bash
# 1. Install the forked yaml-hooks plugin (REQUIRED for full functionality)
bun add opencode-yaml-hooks@git+https://github.com/gabrielassisxyz/OpenCode-Hooks.git

# 2. Add to ~/.config/opencode/opencode.json
{
  "plugin": [
    "opencode-yaml-hooks@git+https://github.com/gabrielassisxyz/OpenCode-Hooks.git"
  ]
}

# 3. Copy the skill
mkdir -p ~/.config/opencode/skills/porter
cp skills/porter/SKILL.md ~/.config/opencode/skills/porter/

# 4. Copy the command
mkdir -p ~/.config/opencode/commands
cp commands/porter.md ~/.config/opencode/commands/

# 5. Restart OpenCode
pkill -f opencode && opencode
```

### Invocation

```
/porter [source_path] [--target-format=powerpack|native|both]
```

- `source_path`: Path to `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, or a specific file. Defaults to current directory.
- `--target-format`: Output format. Default is `powerpack`.

### Supported Mappings

| Claude Code | OpenCode |
|-------------|----------|
| `tools: Read, Edit, Bash` | `tools: { read: true, edit: true, bash: true }` |
| `model: sonnet` | `model: anthropic/claude-sonnet-4-6` |
| `model: inherit` | *(omitted — inherits from session)* |
| `agents/` subdir | `mode: subagent` |
| `Agent` tool listed | `mode: primary` |
| CSV tool list | Boolean flags per tool |
| `PreToolUse` (security) | `permissions` block (pattern-based) |
| `UserPromptSubmit` | `message.part.updated` (via forked yaml-hooks) |
| `PostToolUse` | `tool.after.*` |
| `Stop` | `session.deleted` / `session.idle` |

---

## How to Test

### 1. Validate a Ported File

```bash
./skills/porter/scripts/validate-output.sh path/to/output.md
```

Checks:
- Valid YAML frontmatter
- Required fields present
- Name format (`^[a-z0-9]+(-[a-z0-9]+)*$`)
- Description length (1–1024 chars)
- Boolean tool flags

### 2. Run Examples

The `examples/` directory contains:
- `input/`: Claude Code artifacts
- `output-powerpack/`: Expected Power Pack output
- `output-native/`: Expected Native Agent output

Compare your port output against these.

### 3. Test the Homunculus Showcase

The `examples/homunculus-port/` directory contains a complete real-world port.

```bash
# Install the homunculus skill
mkdir -p ~/.config/opencode/skills/homunculus
cp examples/homunculus-port/SKILL.md ~/.config/opencode/skills/homunculus/

# Test commands
/homunculus:init      # Creates .opencode/homunculus/ structure
/homunculus:status    # Check session count, instincts, evolution
```

### 4. Test the Forked Plugin

```bash
# Verify hooks.yaml is loaded
cat ~/.config/opencode/hook/hooks.yaml

# Start OpenCode, type a prompt, verify observations are logged
cat .opencode/homunculus/observations.jsonl
```

---

## How to Make Changes

### Adding a New Tool Mapping

1. Edit `skills/porter/references/tool-mapping.md`
2. Add the mapping to the table
3. Update `skills/porter/SKILL.md` section 3.2 (Translate Tools)
4. Update `skills/porter/references/opencode-schema.md`
5. Run `./skills/porter/scripts/validate-output.sh` on a test file

### Adding a New Permission Template

1. Edit `skills/porter/references/permission-templates.md`
2. Add the new template block
3. Update `skills/porter/SKILL.md` section 3.6 (Generate Permissions)

### Modifying the Forked Plugin

The fork lives at `~/repositories/OpenCode-Hooks-fork/` (or wherever you moved it).

```bash
cd ~/repositories/OpenCode-Hooks-fork
# Make changes
bun run build
bun test
# Push to your fork
git push origin main
```

Then update `~/.config/opencode/opencode.json` to point to your fork.

### Adding a New Example

1. Create `examples/input/my-example-SKILL.md`
2. Run the porter to generate output
3. Save output to `examples/output-powerpack/` and `examples/output-native/`
4. Validate with `./skills/porter/scripts/validate-output.sh`

---

## Architecture & Design Decisions

### Why a Fork of yaml-hooks?

The upstream `opencode-yaml-hooks` deliberately excludes message events (documented as "explicit non-goals"). To support automatic prompt capture for the homunculus showcase, we needed `message.part.updated`. Rather than a hybrid approach (yaml-hooks + TypeScript plugin), we forked to keep everything in one technology stack.

**Trade-off:** We now maintain a fork. Mitigation: the fork is small, focused, and could be upstreamed via PR.

### Why Manual Instructions for the Original Port?

OpenCode v1.14.x does not have automatic lifecycle hooks. The original homunculus port required the agent to consciously log observations. The forked plugin eliminates this limitation.

### Temperature Heuristics

| Keywords | Temperature |
|----------|-------------|
| review, security, lint, audit, test, validate | 0.1 |
| architect, plan, design, structure | 0.2 |
| code, implement, fix, build, develop, refactor | 0.3 |
| document, explain, summarize | 0.4 |
| creative, brainstorm, ideate, explore | 0.6 |
| (none matched) | 0.3 |

### Mode Assignment

| Source | Mode |
|--------|------|
| Sub-agent (lives in `agents/` subdir) | `subagent` |
| Has `Agent` tool or dispatches sub-agents | `primary` |
| Standalone skill | `all` |

---

## Common Issues & Solutions

| Issue | Cause | Fix |
|-------|-------|-----|
| `message.part.updated` not firing | Plugin not installed | Verify `opencode.json` has the fork |
| Hooks not loading | `hooks.yaml` syntax error | Run through a YAML validator |
| Validation fails on name | Name has spaces or special chars | Use kebab-case: `my-skill-name` |
| Tool mapping missing | New tool not in table | Add to `references/tool-mapping.md` |
| Session count not incrementing | `session.created` not firing | Check `scope: main` in hooks.yaml |

---

## Development Workflow

1. **Plan:** Update `docs/internal/task_plan.md`
2. **Implement:** Make changes in `skills/porter/` or the fork
3. **Test:** Run `validate-output.sh`, compare against `examples/`
4. **Document:** Update `README.md`, `AGENTS.md`, or `docs/`
5. **Log:** Update `docs/internal/progress.md`

---

## Contact & Contributing

- **Issues:** Open a GitHub issue
- **PRs:** Welcome! Please include tests for new mappings.
- **Fork:** The yaml-hooks fork is at https://github.com/gabrielassisxyz/OpenCode-Hooks

---

*Last updated: 2026-05-05*
