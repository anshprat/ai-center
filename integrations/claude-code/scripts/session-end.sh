#!/usr/bin/env bash
# Team AI - Deregister the agent when the Claude Code session ends.
# Wired to the SessionEnd hook (NOT Stop, which fires per-turn).

set -uo pipefail

TEAM_AI_DIR="${HOME}/.team-ai"
TEAM_AI_BIN="${TEAM_AI_DIR}/bin"
SESSIONS_DIR="${TEAM_AI_DIR}/sessions"

[ -x "${TEAM_AI_BIN}/ai-deregister" ] || exit 0

input="$(cat)"
SESSION_ID="$(INPUT="$input" python3 - <<'PY' 2>/dev/null
import json, os
raw = os.environ.get("INPUT", "")
try:
    obj = json.loads(raw) if raw.strip() else {}
except Exception:
    obj = {}
print(obj.get("session_id", "") or "")
PY
)"

[ -n "$SESSION_ID" ] || exit 0

SESSION_FILE="${SESSIONS_DIR}/${SESSION_ID}"
[ -f "$SESSION_FILE" ] || exit 0

AGENT_ID="$(cat "$SESSION_FILE" 2>/dev/null || true)"
if [ -n "$AGENT_ID" ]; then
    "${TEAM_AI_BIN}/ai-deregister" "$AGENT_ID" >/dev/null 2>&1 || true
fi

rm -f "$SESSION_FILE"
exit 0
