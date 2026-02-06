#!/bin/bash
# Team AI message checker
# Can be called periodically or on-demand

TEAM_AI_DIR="${HOME}/.team-ai"

# Check if agent ID is provided or set in environment
AGENT_ID="${1:-$TEAM_AI_AGENT_ID}"

if [ -z "${AGENT_ID}" ]; then
    echo "Usage: check-messages.sh AGENT_ID"
    echo "Or set TEAM_AI_AGENT_ID environment variable"
    exit 1
fi

AGENT_DIR="${TEAM_AI_DIR}/agents/${AGENT_ID}"

if [ ! -d "${AGENT_DIR}" ]; then
    echo "Agent not found: ${AGENT_ID}"
    exit 1
fi

TODO_DIR="${AGENT_DIR}/incoming/todo"

# Count pending messages
if [ -d "${TODO_DIR}" ]; then
    pending=$(ls -1 "${TODO_DIR}"/*.md 2>/dev/null | wc -l | tr -d ' ')

    if [ "${pending}" -gt 0 ]; then
        echo "You have ${pending} pending message(s):"
        echo ""

        for msg in "${TODO_DIR}"/*.md; do
            if [ -f "${msg}" ]; then
                filename=$(basename "${msg}")
                subject=$(grep -m1 "^# Subject:" "${msg}" 2>/dev/null | sed 's/^# Subject: //' || echo "(no subject)")
                priority=$(grep -m1 "^priority:" "${msg}" 2>/dev/null | cut -d':' -f2 | tr -d ' ' || echo "normal")

                echo "  [${priority^^}] ${subject}"
                echo "         File: ${filename}"
            fi
        done

        echo ""
        echo "Use 'ai-check ${AGENT_ID}' for full details"
    else
        echo "No pending messages"
    fi
else
    echo "No pending messages"
fi
