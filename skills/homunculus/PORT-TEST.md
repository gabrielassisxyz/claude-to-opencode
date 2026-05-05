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

## Critical Limitations

### 1. Manual Invocation Required

**This is the biggest limitation.**

In Claude Code, hooks fire **automatically**:
- Every prompt → logged
- Every tool use → logged
- Session end → counter updated

In OpenCode, the homunculus skill must be **explicitly invoked**:
- User must say something that matches the description trigger
- OR user must run `/homunculus:status` or similar command
- OR the skill must be loaded manually

**Workaround:** The skill description is optimized to trigger on common phrases like:
- "my homunculus"
- "what have you learned"
- "check in"
- "session memory"

But it's **not automatic**.

### 2. No True Session End Detection

Claude Code's `Stop` hook fires when the session truly ends.
OpenCode has no equivalent. We **inverted** the logic:
- Detect "new session" at start (by checking lastSession > 5 min)
- Update lastSession when the skill is invoked

This means:
- ✅ Session counter increments when user returns after 5+ min
- ❌ Counter doesn't increment if user just keeps working continuously
- ❌ No way to run cleanup at true session end

### 3. Observation Logging is Best-Effort

The skill **instructs** the agent to log observations, but:
- The agent might forget
- The agent might log inconsistently
- There's no enforcement mechanism

In Claude Code, the hook runs **outside** the agent's reasoning. In OpenCode, it's part of the agent's workflow.

### 4. Permission Model Differences

The observer agent needs broad permissions to read/write instincts. In Claude Code, this was implicit. In OpenCode, we had to explicitly grant bash permissions for specific paths under `.opencode/homunculus/`.

---

## Comparison: Claude Code vs OpenCode Homunculus

| Feature | Claude Code | OpenCode | Status |
|---------|-------------|----------|--------|
| Auto prompt capture | ✅ Hook | ⚠️ Manual instruction | Best-effort |
| Auto tool logging | ✅ Hook | ⚠️ Manual instruction | Best-effort |
| Session end detection | ✅ Stop hook | ⚠️ Inverted (start detection) | Partial |
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
