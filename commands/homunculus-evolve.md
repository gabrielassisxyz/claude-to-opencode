---
description: Grow new capabilities from clustered instincts. Evolves the homunculus when patterns have been learned.
---

# Evolve

User wants you to grow. Evolution happens when **instincts cluster**.

## Not Born?

```
Can't evolve what doesn't exist.

/homunculus:init first.
```

## Check For Clustering

```bash
# Count instincts per domain
echo "=== Instinct Clustering ==="
for dir in personal inherited; do
  echo "--- $dir ---"
  grep -h "^domain:" .opencode/homunculus/instincts/$dir/*.md 2>/dev/null | \
    sed 's/domain: "//' | sed 's/"//' | sort | uniq -c | sort -rn
done
```

**Threshold**: 5+ instincts in same domain = evolution opportunity.

## What You Can Grow

| Type | When | Where |
|------|------|-------|
| Command | User-invoked task | `.opencode/homunculus/evolved/commands/[name].md` |
| Skill | Auto-triggered behavior | `.opencode/homunculus/evolved/skills/[name]/SKILL.md` |
| Agent | Deep specialist work | `.opencode/homunculus/evolved/agents/[name].md` |

## Process

1. Check instinct clustering (above)
2. If 5+ in a domain, propose a capability
3. Show the clustered instincts that led to this
4. When they say yes, write the capability
5. Update identity.json with evolved capability name
6. Confirm: `Done. I have /homunculus:[name] now.`

## If No Clustering Yet

```
No clusters yet. You have [N] instincts spread across domains.

Keep working. I'll propose evolution when patterns emerge.
```

---

> Ported from `homunculus/commands/evolve.md` by porter skill on 2026-05-05.
