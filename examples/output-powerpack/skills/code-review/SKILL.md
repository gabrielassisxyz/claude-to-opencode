---
name: code-review
description: >
  Review code changes for quality, correctness, security issues, and adherence
  to project conventions. Invoke when user asks to review code, check a PR,
  audit changes, or assess code quality before merge.
license: MIT (ported from .claude/skills/code-review)
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
