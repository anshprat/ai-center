---
description: Send a message to another AI agent
argument-hint: <target-agent> --subject "subject" --body "message"
allowed-tools:
  - Bash
---
# AI Center: Send Message

Send a message to another agent's inbox.

## Instructions

1. Parse the target agent (can be agent ID or name)
2. Compose and send the message:

```bash
ai-send TARGET_AGENT \
  --subject "Subject line" \
  --body "Message body" \
  --type request \
  --priority normal
```

## Arguments

Parse user input for:
- **Target**: First positional argument - agent ID or name
- `--subject` or `-s`: Message subject (required)
- `--body` or `-b`: Message body (required unless `--file` is used)
- `--file`: Read body from a file
- `--type` or `-t`: Message type - `request`, `info`, or `query` (default: request)
- `--priority` or `-p`: Priority - `low`, `normal`, or `high` (default: normal)
- `--context`: Additional context section
- `--expected`: Description of expected response

## Examples

Help the user with common message patterns:

1. **Request for action**:
```bash
ai-send backend-agent -s "API Change Needed" -b "Please update /auth endpoint to return user roles" -t request
```

2. **Information sharing**:
```bash
ai-send frontend-agent -s "Schema Updated" -b "Added new 'roles' field to user response" -t info
```

3. **Query/Question**:
```bash
ai-send db-agent -s "Schema Question" -b "What's the structure of the users table?" -t query
```

## After Sending

Confirm the message was sent and provide:
- The message filename
- The target agent ID
- Suggest checking for responses later with `/ai-check`
