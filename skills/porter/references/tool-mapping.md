# Tool Mapping — Claude Code → OpenCode

| Claude Code Tool | OpenCode Flag | Category | Default Permission |
|-----------------|---------------|----------|-------------------|
| Read | read | filesystem | allow |
| Edit | edit | filesystem | ask |
| Write | write | filesystem | ask |
| Bash | bash | execution | pattern-based |
| Grep | grep | search | allow |
| Glob | glob | search | allow |
| Agent | (mode=primary) | orchestration | n/a |
| WebFetch | fetch | network | ask |
| WebSearch | search | network | ask |
| NotebookEdit | notebook | specialized | ask |
| Monitor | monitor | execution | ask |
| TodoRead | todo_read | state | allow |
| TodoWrite | todo_write | state | ask |

## Notes
- `Agent` doesn't map to a tool flag; it changes the agent's `mode` to `primary`
- `WebFetch`/`WebSearch` may alternatively map to MCP tools (context7, perplexity)
- Tools not in this table require user decision
