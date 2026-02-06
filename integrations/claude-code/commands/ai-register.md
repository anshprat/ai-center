---
description: Register this agent with Team AI for multi-agent coordination
argument-hint: [--name "agent-name"] [--tags "tag1,tag2"]
allowed-tools:
  - Bash
---
# Team AI: Register Agent

Register this Claude Code session as an agent in the Team AI system.

## Instructions

1. Generate a descriptive agent name based on the current working directory and task context
2. Run the registration command with appropriate parameters:

```bash
AGENT_ID=$(ai-register \
  --name "claude-code-$(basename $(pwd))" \
  --command "Claude Code session in $(pwd)" \
  --model "claude-opus-4-5" \
  --tags "claude-code,interactive" \
  --capabilities "code,analysis,refactoring")
```

3. Store the AGENT_ID for use in subsequent commands
4. Confirm registration to the user with the agent ID

## Parameters

If the user provides arguments, parse them:
- `--name NAME`: Use this as the agent name instead of auto-generating
- `--tags TAGS`: Additional comma-separated tags to include
- `--capabilities CAPS`: Specific capabilities to advertise

## Output

After successful registration, inform the user:
- Their agent ID
- How to check messages: `ai-check $AGENT_ID`
- How to send messages to other agents: `ai-send TARGET_ID --subject "..." --body "..."`
- How to list other agents: `ai-list`
