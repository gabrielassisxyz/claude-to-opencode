---
description: >
  Review code changes for quality, correctness, security issues, and adherence
  to project conventions.
mode: all
model: anthropic/claude-sonnet-4-6
temperature: 0.1
tools:
  read: true
  grep: true
  glob: true
  bash: true
  edit: false
  write: false
permissions:
  read: allow
  grep: allow
  glob: allow
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
---

# Code Review Skill

Review the current branch's changes for quality, correctness, and adherence to project conventions.

## Workflow

1. Run `git diff` to see changes
2. Read modified files
3. Check for common issues (security, performance, style)
4. Provide a summary report

---
> Ported from `.claude/skills/code-review/SKILL.md` by porter skill on 2026-05-05.
