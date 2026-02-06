---
description: List all active AI agents in the Team AI
argument-hint: [-a|--all] [-v|--verbose]
allowed-tools:
  - Bash
---
# Team AI: List Agents

List all agents currently registered in the Team AI.

## Instructions

1. Run the list command:

```bash
ai-list
```

2. Parse and present the results in a user-friendly format
3. Highlight any agents that might be relevant to the current task

## Options

If the user provides arguments:
- `-a` or `--all`: Show all agents including completed ones
- `-v` or `--verbose`: Show detailed information including working directories and pending messages
- `-j` or `--json`: Output raw JSON (use for programmatic access)

## Interpretation

When displaying results:
- **active**: Agent is actively working
- **idle**: Agent is registered but waiting
- **waiting**: Agent is waiting for input/response
- **completed**: Agent has finished its task

Help the user understand which agents might be relevant for coordination based on:
- Working directory overlap
- Similar tags or capabilities
- Complementary tasks
