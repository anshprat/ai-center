---
name: ai-center-awareness
description: Provides AI Center context when user mentions "other agents", "send message", "check messages", "AI Center", "multi-agent", "coordinate", "collaborate with", "other Claude"
version: 1.0.0
---
# AI Center Awareness

You are part of a multi-agent system called **AI Center**. This allows multiple AI agents (Claude Code sessions, Cursor, Continue, etc.) to be aware of each other and communicate.

## Available Commands

Use these slash commands for AI Center operations:

| Command | Description |
|---------|-------------|
| `/ai-register` | Register this session as an agent |
| `/ai-list` | List all active agents |
| `/ai-send` | Send a message to another agent |
| `/ai-check` | Check for incoming messages |

## When This Skill Activates

This skill activates when users mention:
- Other agents or AI assistants
- Sending or checking messages between agents
- Coordinating work across multiple sessions
- Multi-agent collaboration

## Quick Reference

### Check if AI Center is installed
```bash
which ai-list
```

### List active agents
```bash
ai-list
```

### Register this session
```bash
AGENT_ID=$(ai-register --name "my-task" --command "working on X")
```

### Send a message
```bash
ai-send TARGET_ID --subject "Subject" --body "Message content"
```

### Check messages
```bash
ai-check AGENT_ID
```

## Coordination Patterns

### 1. Before Making Breaking Changes
Check if other agents are working on related files:
```bash
ai-list -v  # Check working directories and current tasks
```

If conflicts are possible, send a heads-up:
```bash
ai-send other-agent -s "Heads up: API changes" -b "I'm modifying the auth module" -t info
```

### 2. Request Assistance
When you need help from another specialized agent:
```bash
ai-send db-agent -s "Schema question" -b "What indexes exist on users table?" -t query
```

### 3. Share Completed Work
After finishing a task that affects others:
```bash
ai-send all-agents -s "Auth module updated" -b "New endpoint: POST /v2/auth/refresh" -t info
```

## Important Notes

- AI Center uses the filesystem at `~/.ai-center/`
- Agents have unique UUIDs
- Messages are stored as markdown files
- The system works across different AI tools (Claude Code, Cursor, Continue, etc.)

## Proactive Suggestions

When appropriate, suggest to the user:
1. **At session start**: "Would you like to register with AI Center to coordinate with other agents?"
2. **Before major changes**: "Should I check if other agents are working on related files?"
3. **After completing tasks**: "Want to notify other agents about these changes?"
