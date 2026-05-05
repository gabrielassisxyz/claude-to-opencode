# Homunculus Port — Test Plan & Limitations

## Files Ported

| Source (Claude Code) | Target (OpenCode) | Type |
|---------------------|-------------------|------|
| `homunculus/CLAUDE.md` + `skills/session-memory/SKILL.md` | `skills/homunculus/SKILL.md` | Skill |
| `agents/observer.md` | `agent/homunculus-observer.md` | Agent |
| `commands/init.md` | `commands/homunculus-init.md` | Command |
| `commands/status.md` | `commands/homunculus-status.md` | Command |
| `commands/evolve.md` | `commands/homunculus-evolve.md` | Command |

## How to Test

### 1. Install the Skill

Copy to your OpenCode skills directory:

```bash
# From this repo
mkdir -p ~/.config/opencode/skills/homunculus
cp skills/homunculus/SKILL.md ~/.config/opencode/skills/homunculus/SKILL.md

# Or symlink for development
ln -s $(pwd)/skills/homunculus ~/.config/opencode/skills/homunculus
```

### 2. Install Commands

```bash
mkdir -p ~/.config/opencode/commands
cp commands/homunculus-*.md ~/.config/opencode/commands/
# Or symlink
ln -s $(pwd)/commands/homunculus-*.md ~/.config/opencode/commands/
```

### 3. Install Observer Agent

```bash
mkdir -p ~/.config/opencode/agent
cp agent/homunculus-observer.md ~/.config/opencode/agent/
```

### 4. Restart OpenCode

```bash
pkill -f opencode
opencode
```

### 5. Test Flow

#### Birth (Init)
```
/homunculus:init
```
- Should create `.opencode/homunculus/` directory structure
- Should create `identity.json`
- Should greet with the ASCII art

#### Check In (Status)
```
/homunculus:status
```
- Should show session count, instincts, evolution readiness

#### Invoke Skill Directly
```
My homunculus, what have you learned?
```
- Should trigger the skill (description match)
- Should detect if it's a new session (> 5 min since last)
- Should greet with context

#### Simulate Work Session
Do some coding work. The homunculus skill, when invoked, should:
- Log observations manually (as instructed in body)
- Apply instincts if any exist

#### Run Observer
```
@homunculus-observer analyze my observations
```
- Should read `observations.jsonl`
- Should create instincts in `instincts/personal/`

#### Evolve
```
/homunculus:evolve
```
- Should check instinct clustering
- Should propose evolution if 5+ in same domain

---

## How to Test (Automatic Hooks)

### 5. Install yaml-hooks Plugin

```bash
# The forked plugin is already configured in ~/.config/opencode/opencode.json
# It will be installed automatically on next OpenCode startup
```

### 6. Verify hooks.yaml

```bash
cat ~/.config/opencode/hook/hooks.yaml
```

### 7. Test Automatic Capture

Start OpenCode and type any prompt. The yaml-hooks plugin will automatically:
- Log your prompt to `.opencode/homunculus/observations.jsonl`
- Log tool usage automatically
- Track session start/end

Verify:
```bash
cat .opencode/homunculus/observations.jsonl
```

---

## Critical Limitations (RESOLVED with yaml-hooks fork)

### 1. ✅ Automatic Prompt Capture

**RESOLVED:** The forked `opencode-yaml-hooks` plugin listens to `message.part.updated` and automatically captures user prompts.

### 2. ✅ Automatic Tool Logging

**RESOLVED:** The `tool.after.*` hook automatically logs tool usage.

### 3. ✅ Session Lifecycle

**RESOLVED:** `session.created` and `session.deleted` hooks handle session start/end automatically.

### 4. Manual Observer Invocation (REMAINS)

The observer agent (`@homunculus-observer`) still needs to be invoked manually to process observations into instincts. This is by design — processing observations is compute-intensive and should not run automatically on every session.

---

## Comparison: Claude Code vs OpenCode Homunculus

| Feature | Claude Code | OpenCode (with fork) | Status |
|---------|-------------|---------------------|--------|
| Auto prompt capture | ✅ Hook | ✅ `message.part.updated` | **Works** |
| Auto tool logging | ✅ Hook | ✅ `tool.after.*` | **Works** |
| Session end detection | ✅ Stop hook | ✅ `session.deleted` | **Works** |
| Observer spawning | ✅ Auto on session start | ⚠️ Manual or @mention | Requires user action |
| Instinct application | ✅ Implicit | ✅ Explicit in body | Works |
| Evolution proposal | ✅ Auto when clustering | ✅ Same logic | Works |
| Identity tracking | ✅ Automatic | ✅ Same logic | Works |
| Check-in | ✅ /command | ✅ /command | Works |
| Init/Birth | ✅ /command | ✅ /command | Works |

---

## Recommendation

This port is **functional but requires behavioral adaptation**:

1. **User must consciously interact with the homunculus** — it's not ambient
2. **Invoke `/homunculus:status` regularly** to trigger observation logging and session tracking
3. **Run `@homunculus-observer` periodically** to process accumulated observations
4. **Consider this a "companion" rather than a "background process"**

If fully automatic behavior is required, the only path is:
- **Feature request to OpenCode** for lifecycle hooks/events
- **Wrapper script** around the opencode binary (adds complexity)

---

*Ported from homunculus plugin by porter skill on 2026-05-05.*
