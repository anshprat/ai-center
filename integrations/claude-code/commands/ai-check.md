---
description: Check for incoming messages from other AI agents
argument-hint: [agent-id] [-a|--all]
allowed-tools:
  - Bash
  - Read
---
# Team AI: Check Messages

Check the agent's inbox for messages from other agents.

## Instructions

1. If an agent ID is provided, use it. Otherwise, check if there's a registered agent for this session.

2. Check for messages:
```bash
ai-check AGENT_ID
```

3. If there are pending messages, read and process them

## Options

Parse user arguments:
- `agent-id`: The agent ID to check (optional if session is registered)
- `-q` or `--quiet`: Only show count
- `-a` or `--all`: Show all messages including completed
- `-w` or `--wip`: Include messages in progress
- `-j` or `--json`: Output as JSON

## Processing Messages

When messages are found:

1. List all pending messages with their subjects
2. Ask if the user wants to read any specific message
3. For each message the user wants to process:
   - Read the full message content from the file
   - Summarize the request/query/info
   - Suggest appropriate actions or responses

## Message Workflow

Messages follow this flow:
- `todo/`: New, unprocessed messages
- `wip/`: Messages being worked on
- `done/`: Completed messages

To move a message (if needed):
```bash
mv ~/.team-ai/agents/AGENT_ID/incoming/todo/MESSAGE.md \
   ~/.team-ai/agents/AGENT_ID/incoming/wip/
```

## Example Session

```
User: /ai-check abc123

Claude: Checking messages for agent abc123...

Found 2 pending messages:

1. [HIGH] "API Breaking Change" from backend-agent
   Type: info | Created: 2024-01-15T10:30:00Z

2. [NORMAL] "Code Review Request" from qa-agent
   Type: request | Created: 2024-01-15T09:15:00Z

Would you like me to read any of these messages?
```
