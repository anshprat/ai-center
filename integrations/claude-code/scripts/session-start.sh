#!/usr/bin/env bash
# Team AI - Auto-register Claude Code session on start.
# Invoked by Claude Code's SessionStart hook with a JSON payload on stdin.
# Registers a new agent (or reuses one for resumed sessions) and emits
# additionalContext so the model knows the agent ID.

set -uo pipefail

TEAM_AI_DIR="${HOME}/.team-ai"
TEAM_AI_BIN="${TEAM_AI_DIR}/bin"
SESSIONS_DIR="${TEAM_AI_DIR}/sessions"

# Bail quietly if Team AI isn't installed.
[ -x "${TEAM_AI_BIN}/ai-register" ] || exit 0

mkdir -p "${SESSIONS_DIR}"

# Hook input arrives as JSON on stdin. We need session_id, cwd, and source.
input="$(cat)"

read_field() {
    INPUT="$input" python3 - "$1" <<'PY' 2>/dev/null
import json, os, sys
raw = os.environ.get("INPUT", "")
try:
    obj = json.loads(raw) if raw.strip() else {}
except Exception:
    obj = {}
print(obj.get(sys.argv[1], "") or "")
PY
}

SESSION_ID="$(read_field session_id)"
HOOK_CWD="$(read_field cwd)"
HOOK_SOURCE="$(read_field source)"

# Fallbacks if the payload is missing (e.g., manual run).
[ -z "$SESSION_ID" ] && SESSION_ID="manual-$$"
[ -z "$HOOK_CWD" ] && HOOK_CWD="$(pwd)"

SESSION_FILE="${SESSIONS_DIR}/${SESSION_ID}"

# If we've already registered an agent for this session_id (resume/clear),
# verify the agent still exists and reuse it. Otherwise, register fresh.
AGENT_ID=""
if [ -f "$SESSION_FILE" ]; then
    EXISTING_ID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
    if [ -n "$EXISTING_ID" ] && [ -d "${TEAM_AI_DIR}/agents/${EXISTING_ID}" ]; then
        AGENT_ID="$EXISTING_ID"
        "${TEAM_AI_BIN}/ai-heartbeat" "$AGENT_ID" >/dev/null 2>&1 || true
    fi
fi

if [ -z "$AGENT_ID" ]; then
    DIR_NAME="$(basename "$HOOK_CWD")"
    AGENT_NAME="claude-${DIR_NAME}"
    AGENT_ID="$(
        cd "$HOOK_CWD" 2>/dev/null
        "${TEAM_AI_BIN}/ai-register" \
            --name "$AGENT_NAME" \
            --command "Claude Code session in ${HOOK_CWD}" \
            --model "claude-code" \
            --tags "claude-code,interactive" \
            --capabilities "code,analysis,refactoring" \
            --session-id "$SESSION_ID" \
            2>/dev/null
    )"
    if [ -n "$AGENT_ID" ]; then
        printf '%s' "$AGENT_ID" > "$SESSION_FILE"
    fi
fi

# Emit additionalContext so the model sees the registration result.
if [ -n "$AGENT_ID" ]; then
    AGENT_COUNT="$("${TEAM_AI_BIN}/ai-list" 2>/dev/null | grep -c "^[a-f0-9]" || echo 0)"
    MSG="Team AI: registered as agent ${AGENT_ID} (${AGENT_COUNT} active). Source: ${HOOK_SOURCE:-unknown}."
    MSG="$MSG" python3 - <<'PY'
import json, os
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ.get("MSG", ""),
    }
}))
PY
fi

exit 0
