# Plugin JS Template — Claude Code Plugin → OpenCode Native Plugin

## When to Use

Generate a `.opencode/plugins/{name}.js` file when the source is a **Claude Code plugin bundle** (has `plugin.json` with `skills`, `agents`, `commands`, `hooks` keys).

This reproduces the "always loaded" behavior of Claude Code plugins, where skills are always in context rather than probabilistically triggered by description match.

## Plugin Structure

```javascript
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let _bootstrapCache = undefined;

// Extract frontmatter + body from SKILL.md
const extractSkill = (content) => {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, body: content };
  return { frontmatter: match[1], body: match[2] };
};

// Load all skill bodies into a single bootstrap string
const getBootstrapContent = () => {
  if (_bootstrapCache !== undefined) return _bootstrapCache;

  const skillsDir = path.resolve(__dirname, '../skills');
  let bootstrap = '';

  if (fs.existsSync(skillsDir)) {
    const dirs = fs.readdirSync(skillsDir, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);

    for (const dir of dirs) {
      const skillPath = path.join(skillsDir, dir, 'SKILL.md');
      if (fs.existsSync(skillPath)) {
        const content = fs.readFileSync(skillPath, 'utf8');
        const { body } = extractSkill(content);
        bootstrap += `\n---\n# Skill: ${dir}\n${body}\n`;
      }
    }
  }

  // Load personality file (CLAUDE.md, README.md, etc.)
  const personalityFiles = ['CLAUDE.md', 'README.md', 'PERSONALITY.md'];
  for (const file of personalityFiles) {
    const filePath = path.resolve(__dirname, `../../${file}`);
    if (fs.existsSync(filePath)) {
      bootstrap += `\n---\n# ${file.replace('.md', '')}\n${fs.readFileSync(filePath, 'utf8')}\n`;
      break; // Only load the first one found
    }
  }

  _bootstrapCache = bootstrap || null;
  return _bootstrapCache;
};

export const {Name}Plugin = async ({ client, directory, worktree }) => {
  const skillsDir = path.resolve(__dirname, '../skills');
  const commandsDir = path.resolve(__dirname, '../commands');

  return {
    // 1. Register skill directory in config
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (fs.existsSync(skillsDir) && !config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },

    // 2. Inject skill content into first user message of every session
    'experimental.chat.messages.transform': async (_input, output) => {
      const bootstrap = getBootstrapContent();
      if (!bootstrap || !output.messages?.length) return;

      const firstUser = output.messages.find(m => m.info?.role === 'user');
      if (!firstUser || !firstUser.parts?.length) return;

      // Guard: skip if already injected
      if (firstUser.parts.some(p => p.type === 'text' && p.text?.includes('PORTED_PLUGIN_CONTEXT'))) {
        return;
      }

      const ref = firstUser.parts[0];
      firstUser.parts.unshift({
        ...ref,
        type: 'text',
        text: `[PORTED_PLUGIN_CONTEXT]\n${bootstrap}\n[/PORTED_PLUGIN_CONTEXT]\n`
      });
    },

    // 3. Session start — equivalent to session-memory skill activation
    'session.created': async (event) => {
      // Check if this is a new session (> 5 min since last)
      // Check for pending observations
      // Optionally log or trigger background work
    },

    // 4. Session end — equivalent to Stop hook
    'session.deleted': async (event) => {
      // Update session count, timestamps
    },

    // 5. Optional: react to tool execution (equivalent to PostToolUse)
    'tool.execute.after': async (input, output) => {
      // Log tool usage if needed
    },

    // 6. Optional: message events (requires @gabrielassisxyz/opencode-hooks)
    // These are handled by hooks.yaml, not the JS plugin, to avoid duplication
  };
};
```

## Key Differences from Claude Code Plugin

| Claude Code Plugin | OpenCode Native Plugin |
|-------------------|------------------------|
| `plugin.json` declares bundle | `.opencode/plugins/{name}.js` exports plugin function |
| Skills always in context (via plugin registration) | Skills injected via `experimental.chat.messages.transform` |
| Hooks in `hooks.json` (declarative) | Hooks in `hooks.yaml` (via `@gabrielassisxyz/opencode-hooks`) |
| Agent spawn via `Task` tool in skill body | Can spawn via `client` SDK or user instruction |
| `.claude/` directory prefix | `.opencode/` directory prefix |

## Registration

After generating the plugin, the user must add it to `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "./.opencode/plugins/{name}.js"
  ]
}
```

Or for global installation:
```bash
# Copy plugin to global plugins directory
mkdir -p ~/.config/opencode/plugins
cp .opencode/plugins/{name}.js ~/.config/opencode/plugins/
```

Then in `~/.config/opencode/opencode.json`:
```json
{
  "plugin": [
    "{name}"
  ]
}
```

## Hybrid Approach (Plugin JS + Hooks YAML)

For plugins with observation hooks, use BOTH:
1. **JS Plugin** — for always-loaded skills and session management
2. **Hooks YAML** — for automatic observation capture (via `@gabrielassisxyz/opencode-hooks`)

The JS plugin handles the "persona" and "context" that the original plugin provided.
The hooks.yaml handles the 100% reliable event capture that the original hooks.json provided.

## Notes

- The `experimental.chat.messages.transform` hook may change in future OpenCode versions
- Bootstrap content is cached per session to avoid repeated disk reads
- The `[PORTED_PLUGIN_CONTEXT]` guard prevents double-injection
- Skills directory must exist at the path referenced by the plugin
- Commands may need manual registration or symlink if `config.commands.paths` is not supported
