#!/bin/bash
# Team AI - Auto-register Claude Code session on start
# This script is called by Claude Code's SessionStart hook

TEAM_AI_BIN="${HOME}/.team-ai/bin"

# Check if ai-register exists
if [ ! -x "${TEAM_AI_BIN}/ai-register" ]; then
    exit 0
fi

# Generate agent name from current directory
DIR_NAME=$(basename "$(pwd)")
AGENT_NAME="claude-${DIR_NAME}"

# Register the agent
AGENT_ID=$("${TEAM_AI_BIN}/ai-register" \
    --name "${AGENT_NAME}" \
    --command "Claude Code session in $(pwd)" \
    --model "claude-code" \
    2>/dev/null)

if [ -n "${AGENT_ID}" ] && [ -n "${CLAUDE_ENV_FILE}" ]; then
    # Export the agent ID so it's available throughout the session
    echo "export TEAM_AI_AGENT_ID=\"${AGENT_ID}\"" >> "${CLAUDE_ENV_FILE}"
fi

# Show status
AGENT_COUNT=$("${TEAM_AI_BIN}/ai-list" 2>/dev/null | grep -c "^[a-f0-9]" || echo "0")
echo "Team AI: Registered as ${AGENT_NAME} (${AGENT_COUNT} agent(s) active)"

exit 0
