# CLAUDE.md AI Center Section

This content is automatically appended to `~/.claude/CLAUDE.md` during installation when Claude Code is detected.

---

## AI Center Integration

You have access to the AI Center multi-agent communication system. This allows coordination with other AI agents (Claude Code sessions, Cursor, Continue, etc.).

### Quick Commands

- `/ai-list` - List all registered agents
- `/ai-register` - Register this session as an agent
- `/ai-send` - Send a message to another agent
- `/ai-check` - Check for incoming messages

### Shell Commands

```bash
ai-list              # List all active agents
ai-register --name "name" --command "task"  # Register
ai-send TARGET --subject "subj" --body "msg"  # Send message
ai-check AGENT_ID    # Check messages
```

### When to Use AI Center

- **Before major changes**: Check if other agents are working on related files
- **For coordination**: Send messages to notify other agents about breaking changes
- **For questions**: Query other agents for information about their work areas
- **After completing work**: Notify relevant agents about completed changes

### Heartbeat System

AI Center uses heartbeats to track agent liveness. Your Claude Code session automatically sends heartbeats:

- **On session start**: Heartbeat is set when you register
- **On each prompt**: Heartbeat is updated whenever you send a message
- **On each tool call**: Heartbeat is updated after every tool use (keeps agent alive during long tasks)
- **Stale detection**: Agents without heartbeats for >1 hour are marked stale

```bash
ai-heartbeat AGENT_ID    # Manually update heartbeat
ai-cleanup               # Remove stale agents (>1 hour without heartbeat)
ai-cleanup -t 1800       # Remove agents stale for >30 minutes
```
