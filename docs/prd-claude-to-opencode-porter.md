---
title: "PRD — Claude Code to OpenCode Porter"
type: prd
created: 2026-05-05
updated: 2026-05-05
status: draft
tags: [prd, opencode, claude-code, porting, automation, skill]
aliases: [porter-prd, skill-porter, plugin-porter]
related:
  - "[[opencode-power-pack]]"
---

# PRD — Claude Code to OpenCode Porter

## Problem Statement

Claude Code e OpenCode compartilham a mesma filosofia (skills como Markdown + YAML frontmatter) mas divergem em:
- Estrutura de diretórios (`agents/` vs `agent/`, plural vs singular)
- Schema de frontmatter (simples vs rico)
- Modelo de permissões (trust-based vs zero-trust)
- Declaração de tools (lista CSV vs boolean flags)
- Mecanismo de trigger (CLAUDE.md lista triggers vs `description` como trigger)
- Acesso a MCP (via slash commands vs nativo no agent config)

Hoje, portar um plugin/skill exige:
1. Entender ambos os formatos manualmente
2. Traduzir frontmatter campo-a-campo
3. Inferir permissões que não existiam no formato original
4. Adaptar referências a tools/sub-agents
5. Criar arquivos companion (commands/*.md)
6. Validar que o resultado é reconhecido pelo OpenCode

**Meta**: automatizar 100% desse processo, com intervenção humana apenas para decisões ambíguas.

## Target Users

- Desenvolvedores que usam ambos os tools
- Mantenedores de skill packs (como opencode-power-pack)
- Quem quer migrar workflows inteiros entre plataformas

## Success Criteria

1. Dado um diretório de skills Claude Code, produzir equivalentes OpenCode válidos
2. Zero intervenção humana no happy path (skill simples, tools conhecidos)
3. Pause-and-ask para decisões ambíguas (modelo, temperatura, permissões custom)
4. Output validável (`opencode agent list | grep <name>`)
5. Preservação de 100% do conteúdo semântico do prompt/body
6. Atribuição automática (license field citando upstream)

## Scope

### In Scope

| Artefato Source | Artefato Target |
|----------------|-----------------|
| `.claude/skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` (OpenCode format) |
| `.claude/agents/<name>.md` | `agent/<name>.md` (OpenCode agent format) |
| `.claude/commands/<name>.md` | `command/<name>.md` (OpenCode command format) |
| Sub-agents em `agents/` dentro de skills | Sub-skills ou sub-agents separados |
| CLAUDE.md trigger entries | `description` field otimizado para trigger |

### Out of Scope (v1)

- ~~Hooks (Claude Code hooks → não têm equivalente direto)~~ → *Mapeamento documentado em `references/hooks-mapping.md` para skills como homunculus*
- Output styles / formatação
- Settings.json → opencode.json (config migration)
- MCP server configuration (apenas referências em tools)
- Porting reverso (OpenCode → Claude Code)

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              porter skill (SKILL.md)             │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. DISCOVERY ──── scan source dirs             │
│       │                                         │
│  2. PARSE ──────── extract frontmatter + body   │
│       │                                         │
│  3. CLASSIFY ───── skill | agent | command      │
│       │                                         │
│  4. TRANSFORM ──── apply mapping rules          │
│       │            (tools, perms, model, temp)  │
│       │                                         │
│  5. ENHANCE ────── infer permissions            │
│       │            add MCP suggestions          │
│       │            optimize description          │
│       │                                         │
│  6. GENERATE ───── write target files           │
│       │                                         │
│  7. VALIDATE ───── structural lint              │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Mapping Rules

### Tool Name Translation

| Claude Code | OpenCode (boolean) |
|-------------|-------------------|
| `Read` | `read: true` |
| `Edit` | `edit: true` |
| `Write` | `write: true` |
| `Bash` | `bash: true` |
| `Grep` | `grep: true` |
| `Glob` | `glob: true` |
| `Agent` (sub-agent dispatch) | `subagent: true` |
| `WebFetch` | `fetch: true` or MCP tool |
| `WebSearch` | `search: true` or MCP tool |
| `NotebookEdit` | `notebook: true` |

### Model Translation

| Claude Code | OpenCode |
|-------------|----------|
| `inherit` / omitted | omitted (inherits from session) |
| `sonnet` | `anthropic/claude-sonnet-4-6` |
| `opus` | `anthropic/claude-opus-4-6` |
| `haiku` | `anthropic/claude-haiku-4-5-20251001` |
| Explicit model ID | Prefixed with `anthropic/` |

### Temperature Heuristics

| Agent Type (inferred from description) | Temperature |
|---------------------------------------|-------------|
| Code review, security, linting | 0.1 |
| Architecture, planning | 0.2 |
| General coding, refactoring | 0.3 |
| Documentation, explanation | 0.4 |
| Creative writing, brainstorming | 0.6 |
| Default (unknown) | 0.3 |

### Permission Inference

When Claude Code lists `Bash` as a tool:
```yaml
permissions:
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "ls*": allow
    "find*": allow
    "grep*": allow
    "cat*": allow
    "rm -rf*": deny
    "git push --force*": deny
    "*": ask
```

When only `Read`, `Edit`, `Write`:
```yaml
permissions:
  read: allow
  edit: ask
  write: ask
  bash: deny
```

### Mode Assignment

| Condition | Mode |
|-----------|------|
| Standalone skill (top-level, invoked directly) | `primary` |
| Sub-agent (lives inside another skill's `agents/` dir) | `subagent` |
| Utility (can be either) | `all` |

## Decision Points (Require User Input)

O skill deve pausar e perguntar ao usuário quando:

1. **Ambiguidade de modelo**: skill não especifica modelo E description não indica complexidade clara
2. **Bash com padrões desconhecidos**: skill usa Bash para tasks domain-specific onde defaults não cobrem
3. **Conflitos de naming**: target já existe no diretório de destino
4. **MCP enhancement**: sugerir adição de Context7/Perplexity e confirmar
5. **Sub-agent topology**: skill tem sub-agents com interdependências complexas

## Output Structure

Para cada skill portado, gerar:

```
output/
├── skills/
│   └── <skill-name>/
│       └── SKILL.md          # Full OpenCode skill
├── agent/
│   └── <agent-name>.md      # If source was an agent
├── commands/
│   └── <command-name>.md    # Companion command file
└── porter-report.md          # Summary of all transformations
```

## Non-Functional Requirements

- Idempotente: rodar 2x no mesmo source produz o mesmo output
- Preserva encoding e line endings do source
- Não modifica source files (read-only)
- Report inclui diff semântico (o que mudou e por quê)
- Suporta batch (diretório inteiro) e single-file mode

## Open Questions

1. O OpenCode power-pack usa `SKILL.md` format (com `name` em frontmatter), enquanto o artigo descreve `agent/*.md` format (filename como identifier). Suportar ambos os targets?
2. Incluir geração automática do `opencode-power-pack.js` plugin loader?
3. Auto-commit com attribution no git após porting?
