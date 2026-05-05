# Claude Code → OpenCode Porter

A skill and tooling to automatically port Claude Code skills, agents, and commands to the OpenCode format.

## What It Does

Given a directory of Claude Code artifacts (`.claude/skills/`, `.claude/agents/`, `.claude/commands/`), this porter:

1. **Discovers** all skills, agents, and commands
2. **Parses** YAML frontmatter and body content
3. **Classifies** each artifact by type
4. **Transforms** frontmatter fields using canonical mapping rules
5. **Infers** zero-trust permissions, temperature, and mode
6. **Generates** valid OpenCode output (Power Pack or Native Agent format)
7. **Validates** all generated files structurally
8. **Reports** decisions, warnings, and statistics

## Mapping Highlights

| Claude Code | OpenCode |
|-------------|----------|
| `tools: Read, Edit, Bash` | `tools: { read: true, edit: true, bash: true }` |
| `model: sonnet` | `model: anthropic/claude-sonnet-4-6` |
| `model: inherit` | *(omitted — inherits from session)* |
| `agents/` subdir | `mode: subagent` |
| `Agent` tool listed | `mode: primary` |
| CSV tool list | Boolean flags per tool |

## Structure

```
.
├── skills/
│   └── porter/
│       ├── SKILL.md                          # Main skill definition
│       ├── scripts/
│       │   ├── detect-source-type.sh         # Classify input files
│       │   ├── parse-frontmatter.sh          # Extract YAML from Markdown
│       │   └── validate-output.sh            # Lint generated files
│       └── references/
│           ├── tool-mapping.md               # Canonical tool translation table
│           ├── permission-templates.md         # Default permission blocks
│           ├── hooks-mapping.md              # Claude Code hooks → OpenCode strategies
│           └── opencode-schema.md            # Target format reference
├── commands/
│   └── porter.md                             # Slash command definition
├── examples/
│   ├── input/                                # Sample Claude Code artifacts
│   ├── output-powerpack/                     # Expected Power Pack output
│   ├── output-native/                        # Expected Native Agent output
│   └── homunculus-port/                      # Full real-world port example
│       ├── SKILL.md
│       └── scripts/
├── docs/
│   ├── prd-claude-to-opencode-porter.md      # Product Requirements Document
│   ├── spec-porter-skill.md                  # Technical specification
│   ├── spec-porter-SKILL-draft.md            # Draft SKILL.md content
│   ├── opencode-hooks-fork-plan.md           # Fork implementation plan
│   └── internal/                             # Development logs
├── README.md                                 # This file
└── AGENTS.md                                 # Context for AI agents
```

## Key Dependency

This project uses the `@gabrielassisxyz/opencode-hooks` plugin that adds `message.updated` and `message.part.updated` events for automatic prompt capture:

```bash
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

See `docs/opencode-hooks-fork-plan.md` for historical implementation details.

## Usage

### As an OpenCode Skill

Copy `skills/porter/` to your OpenCode skills directory and invoke with:

```
/porter [source_path] [--target-format=powerpack|native|both]
```

### Standalone Scripts

```bash
# Classify a file
./skills/porter/scripts/detect-source-type.sh path/to/file.md

# Extract frontmatter
./skills/porter/scripts/parse-frontmatter.sh path/to/file.md

# Validate generated output
./skills/porter/scripts/validate-output.sh path/to/output.md
```

## Output Formats

### Power Pack (`--target-format=powerpack`)

For shared repositories like [opencode-power-pack](https://github.com/waybarrios/opencode-power-pack):

```
output/
├── skills/
│   └── {name}/
│       └── SKILL.md
└── commands/
    └── {name}.md
```

### Native Agent (`--target-format=native`)

For local `~/.config/opencode/` installation:

```
output/
├── agent/
│   └── {name}.md
└── command/
    └── {name}.md
```

## Decision Points

The porter pauses and asks the user when:

- An unknown Claude Code tool is encountered
- The appropriate model cannot be inferred
- A target file already exists
- MCP tool enhancement is suggested
- Complex sub-agent topology is detected
- The source description is empty or too generic

For all other cases, the porter proceeds autonomously and logs decisions in `porter-report.md`.

## Temperature Heuristics

| Keywords Detected | Temperature |
|-------------------|-------------|
| review, security, lint, audit, test, validate | 0.1 |
| architect, plan, design, structure | 0.2 |
| code, implement, fix, build, develop, refactor | 0.3 |
| document, explain, summarize | 0.4 |
| creative, brainstorm, ideate, explore | 0.6 |
| *(none matched)* | 0.3 |

## Validation

All generated files are checked for:

- Valid YAML frontmatter
- Required fields (`name` + `description` for skills; `description` + `mode` for agents)
- Name format matching `^[a-z0-9]+(-[a-z0-9]+)*$`
- Description length 1–1024 characters
- Boolean tool flags
- Valid permission patterns

## Contributing

See `AGENTS.md` for detailed context on architecture, design decisions, and how to make changes.

## License

MIT
