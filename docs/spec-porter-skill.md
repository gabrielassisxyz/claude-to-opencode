---
title: "Technical Spec — Porter Skill"
type: spec
created: 2026-05-05
updated: 2026-05-05
status: draft
tags: [spec, opencode, claude-code, porting, skill-architecture]
aliases: [porter-spec, porter-technical-spec]
related:
  - "[[prd-claude-to-opencode-porter]]"
---

# Technical Spec — Porter Skill

## Skill Definition

```
skills/
└── porter/
    ├── SKILL.md              # Main skill file
    ├── scripts/
    │   ├── parse-frontmatter.sh    # Extract YAML from markdown
    │   ├── validate-output.sh      # Lint generated files
    │   └── detect-source-type.sh   # Classify input files
    └── references/
        ├── tool-mapping.md         # Canonical tool translation table
        ├── permission-templates.md # Default permission blocks
        └── opencode-schema.md      # Target format reference
```

## SKILL.md Content

```yaml
---
name: porter
description: Port Claude Code skills, agents, and commands to OpenCode format. Translates frontmatter schemas, maps tool declarations to boolean flags, infers zero-trust permissions, assigns temperature and mode, generates companion command files. Trigger when user mentions porting, migrating, or converting between Claude Code and OpenCode.
license: MIT
---
```

## Workflow Phases

### Phase 1: Discovery

**Input**: path to source (file or directory)

**Actions**:
1. Scan for recognizable Claude Code artifacts:
   - `**/SKILL.md` files (Claude Code skill format)
   - `agents/*.md` or `**/agents/*.md` (sub-agent definitions)
   - `commands/*.md` (slash commands)
   - `CLAUDE.md` (for trigger extraction)
2. Build dependency graph (which skills reference which sub-agents)
3. Output: manifest of files to process with classification

**Script** (`detect-source-type.sh`):
```bash
#!/bin/bash
# Classifies a markdown file as: skill | agent | command | unknown
FILE="$1"
if [[ "$FILE" == */SKILL.md ]]; then
  echo "skill"
elif [[ "$FILE" == */agents/*.md ]] || [[ "$FILE" == */agent/*.md ]]; then
  echo "agent"
elif [[ "$FILE" == */commands/*.md ]] || [[ "$FILE" == */command/*.md ]]; then
  echo "command"
else
  # Check frontmatter for hints
  if grep -q "^tools:" "$FILE" 2>/dev/null; then
    echo "agent"
  elif grep -q "^description:" "$FILE" 2>/dev/null; then
    echo "command"
  else
    echo "unknown"
  fi
fi
```

### Phase 2: Parse

**Actions**:
1. Extract YAML frontmatter (between `---` delimiters)
2. Extract body content (everything after second `---`)
3. Parse tool lists, model refs, description
4. Identify inline references to other agents (`Agent` tool calls, `@mentions`)

**Script** (`parse-frontmatter.sh`):
```bash
#!/bin/bash
# Extracts frontmatter as clean YAML
FILE="$1"
sed -n '/^---$/,/^---$/{ /^---$/d; p }' "$FILE"
```

**Parsed fields** (Claude Code source):
```
name          → string (from frontmatter or directory name)
description   → string
tools         → list<string> (CSV or YAML list)
model         → string (inherit | model-name)
body          → string (markdown content after frontmatter)
sub_agents    → list<path> (from agents/ subdirectory)
triggers      → list<string> (from CLAUDE.md if available)
```

### Phase 3: Classify

Determine target format based on source type and characteristics:

| Source | Has sub-agents? | Target Format |
|--------|----------------|---------------|
| SKILL.md | Yes | SKILL.md + separate sub-agent files |
| SKILL.md | No | SKILL.md only |
| agents/*.md | — | agent/*.md |
| commands/*.md | — | command/*.md |

### Phase 4: Transform

Core translation logic. Each field has deterministic mapping rules:

#### 4.1 Frontmatter Translation

**Input** (Claude Code):
```yaml
name: code-review
description: Reviews code for quality and correctness
tools: Read, Edit, Grep, Bash
model: inherit
```

**Output** (OpenCode SKILL.md format):
```yaml
name: code-review
description: >
  Reviews code for quality, correctness, security vulnerabilities,
  and adherence to best practices. Invoke when user asks for code review,
  PR review, or quality check on changes.
license: MIT (ported from claude-code)
```

**Output** (OpenCode agent format):
```yaml
description: >
  Reviews code for quality, correctness, security vulnerabilities,
  and adherence to best practices.
mode: primary
model: anthropic/claude-sonnet-4-6
temperature: 0.1
tools:
  read: true
  edit: true
  grep: true
  bash: true
  glob: true
  write: false
permissions:
  read: allow
  edit: ask
  grep: allow
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "grep*": allow
    "find*": allow
    "rm*": deny
    "git push*": deny
    "*": ask
```

#### 4.2 Description Enhancement

O `description` no OpenCode é o mecanismo primário de trigger. Deve ser:
- Detalhado (explica O QUE faz E QUANDO invocar)
- "Pushy" (usa verbos imperativos que matcham intent do usuário)
- 1-1024 caracteres

**Regra de transformação**:
1. Se source `description` < 50 chars → expandir com contexto do body
2. Append trigger phrases: "Invoke when user asks for [X], mentions [Y], or needs [Z]"
3. Se CLAUDE.md tinha trigger phrases → incorporar no description

#### 4.3 Tool Mapping

Aplicar tabela canônica (ver PRD). Regras adicionais:
- Se tool não está na tabela → marcar como `unknown_tool: true` no report
- Se `Agent` está na lista → `mode: primary` (pode dispatchar sub-agents)
- Se `WebFetch`/`WebSearch` → sugerir MCP enhancement (decision point)

#### 4.4 Permission Generation

Algoritmo:
```
for each tool in translated_tools:
  if tool == "read" or tool == "grep" or tool == "glob":
    permissions[tool] = "allow"  # Read-only, safe
  elif tool == "bash":
    permissions[tool] = BASH_PERMISSION_TEMPLATE  # Pattern-based
  elif tool == "edit" or tool == "write":
    permissions[tool] = "ask"  # Modifications need confirmation
  elif tool starts with MCP prefix:
    permissions[tool] = "ask"  # External calls need confirmation
```

#### 4.5 Temperature Assignment

Algoritmo (keyword matching no description + body):
```
keywords_low  = [review, security, lint, audit, test, validate]  → 0.1
keywords_med  = [architect, plan, design, structure, refactor]   → 0.2
keywords_std  = [code, implement, fix, build, develop]           → 0.3
keywords_doc  = [document, explain, summarize, write docs]       → 0.4
keywords_high = [creative, brainstorm, ideate, explore options]  → 0.6

score = weighted_match(description + first_100_words_body, keywords_*)
temperature = score_to_temp(score)
```

#### 4.6 Mode Assignment

```
if source is sub-agent (in agents/ subdir):
  mode = "subagent"
elif source has Agent tool OR dispatches sub-agents:
  mode = "primary"
elif source is standalone skill:
  mode = "all"  # Can function as either
```

### Phase 5: Enhance

Optional improvements beyond 1:1 translation:

1. **MCP Suggestions**: Se o agent faz research/documentation, sugerir:
   ```yaml
   tools:
     context7*: true   # Documentation lookup
     perplexity*: true # Web research
   ```
   → Decision point: confirmar com usuário

2. **Cross-reference**: Se source tinha sub-agents, adicionar ao body:
   ```markdown
   ## Sub-agents
   - `@code-explorer` — navigates codebase structure
   - `@code-reviewer` — reviews implementation quality
   ```

3. **Attribution**: Adicionar ao body:
   ```markdown
   ---
   > Ported from `claude-code/<original-path>` by porter skill.
   ```

### Phase 6: Generate

**SKILL.md format** (para skills packs como opencode-power-pack):
```markdown
---
name: {name}
description: {enhanced_description}
license: MIT (ported from {source_path})
---

{transformed_body}
```

**Agent format** (para `~/.config/opencode/agent/`):
```markdown
---
description: {enhanced_description}
mode: {mode}
model: {model_path}
temperature: {temperature}
tools:
  {tool_flags}
permissions:
  {permission_block}
---

{transformed_body}
```

**Command format** (para slash commands):
```markdown
---
description: {short_description}
---

# {Title}

{full_body_content}
```

### Phase 7: Validate

**Structural validation**:
1. YAML frontmatter is valid
2. Required fields present (`name`/`description` for SKILL.md, `description`/`mode` for agent)
3. `name` matches regex `^[a-z0-9]+(-[a-z0-9]+)*$`
4. `description` is 1-1024 characters
5. All tool references resolve to known tools
6. No circular sub-agent references

**Script** (`validate-output.sh`):
```bash
#!/bin/bash
FILE="$1"
ERRORS=0

# Check frontmatter exists
if ! head -1 "$FILE" | grep -q "^---$"; then
  echo "ERROR: Missing frontmatter"
  ERRORS=$((ERRORS + 1))
fi

# Check name format (for SKILL.md)
NAME=$(sed -n 's/^name: *//p' "$FILE")
if [[ -n "$NAME" ]] && ! echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "ERROR: Invalid name format: $NAME"
  ERRORS=$((ERRORS + 1))
fi

# Check description length
DESC=$(sed -n 's/^description: *//p' "$FILE")
if [[ ${#DESC} -gt 1024 ]]; then
  echo "ERROR: Description exceeds 1024 chars"
  ERRORS=$((ERRORS + 1))
fi

exit $ERRORS
```

## Porter Report

After processing, generate `porter-report.md`:

```markdown
# Porter Report — {timestamp}

## Summary
- Source: {source_path}
- Files processed: {count}
- Skills ported: {count}
- Agents ported: {count}
- Commands generated: {count}
- Decision points encountered: {count}
- Errors: {count}

## Transformations

| Source | Target | Type | Changes |
|--------|--------|------|---------|
| .claude/skills/code-review/SKILL.md | skills/code-review/SKILL.md | skill | tools expanded, description enhanced |
| .claude/agents/explorer.md | agent/explorer.md | agent | +permissions, +temperature, mode=subagent |

## Decisions Made
- [AUTO] code-review: temperature=0.1 (keyword: review, security)
- [AUTO] feature-dev: mode=primary (has Agent tool)
- [USER] explorer: added perplexity MCP (user confirmed)

## Warnings
- Unknown tool "CustomTool" in agent X — skipped, needs manual mapping
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Malformed YAML in source | Report error, skip file, continue batch |
| Unknown tool name | Map to `unknown: true`, flag in report |
| File already exists at target | Decision point: overwrite / rename / skip |
| Description empty in source | Synthesize from body (first paragraph) |
| No tools declared | Default to `read: true, grep: true, glob: true` |
| Circular sub-agent refs | Break cycle, warn in report |

## Integration Points

### With OpenCode Power Pack

Se o target é um power-pack style repo:
1. Gerar SKILL.md em `skills/<name>/`
2. Gerar companion command em `commands/<name>.md`
3. Atualizar `package.json` se existir (bump version)
4. NÃO tocar em `opencode-power-pack.js` (auto-discovers from skills dir)

### With OpenCode Native

Se o target é `~/.config/opencode/`:
1. Gerar agent em `agent/<name>.md`
2. Gerar command em `command/<name>.md`
3. Sugerir restart: `opencode` deve ser reiniciado
4. Oferecer validação: `opencode agent list | grep <name>`

## Future Enhancements (v2)

- Porting reverso (OpenCode → Claude Code)
- Diff mode: comparar versão portada com upstream, mostrar divergências
- Auto-sync: watch mode que detecta mudanças no source e re-porta
- Plugin loader generation (opencode-power-pack.js)
- Test generation: criar test cases que validam behavior equivalence
- Multi-platform: suportar outros targets (Cursor, Windsurf, Cline)
