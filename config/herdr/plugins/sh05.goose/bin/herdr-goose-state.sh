#!/usr/bin/env bash
# goose hook -> herdr agent state bridge.
#
#   herdr-goose-state.sh <idle|working|blocked|unknown|release> [message]
#
# Reads the hook's JSON payload on stdin. Must never fail or block goose:
# every herdr call is guarded, and outside a herdr pane this is a no-op.
set -u

STATE="${1:-}"
MSG="${2:-}"

# Always drain stdin so goose never blocks writing the payload.
PAYLOAD="$(cat 2>/dev/null || true)"

if [ "${HERDR_ENV:-}" != "1" ] || [ -z "${HERDR_PANE_ID:-}" ] || [ -z "${HERDR_BIN_PATH:-}" ]; then
  exit 0
fi
[ -n "$STATE" ] || exit 0

SOURCE="sh05-goose"
AGENT="goose"

# Milliseconds since the epoch: monotonic across processes and restarts,
# which herdr requires (reports with a non-increasing seq are dropped).
SEQ="$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000' 2>/dev/null || date +%s000)"

SESSION_ID=""
if [ -n "$PAYLOAD" ] && command -v jq >/dev/null 2>&1; then
  SESSION_ID="$(printf '%s' "$PAYLOAD" | jq -r '.session_id // .sessionId // empty' 2>/dev/null || true)"
fi

if [ "$STATE" = "release" ]; then
  "$HERDR_BIN_PATH" pane release-agent "$HERDR_PANE_ID" \
    --source "$SOURCE" --agent "$AGENT" --seq "$SEQ" >/dev/null 2>&1 || true
  exit 0
fi

args=(pane report-agent "$HERDR_PANE_ID"
  --source "$SOURCE" --agent "$AGENT" --state "$STATE" --seq "$SEQ")
[ -n "$MSG" ] && args+=(--message "$MSG")

if [ -n "$SESSION_ID" ]; then
  args+=(--agent-session-id "$SESSION_ID")
  # Resume command for herdr's session restore (herdr >= 0.9.2). The first
  # token must be a bare command name; no argument may contain an apostrophe.
  resume=(goose session --resume --session-id "$SESSION_ID")
  [ -n "${GOOSE_PROVIDER:-}" ] && resume+=(--provider "$GOOSE_PROVIDER")
  [ -n "${GOOSE_MODEL:-}" ] && resume+=(--model "$GOOSE_MODEL")
  case "${resume[*]}" in
    *"'"*) ;;
    *) args+=(-- "${resume[@]}") ;;
  esac
fi

"$HERDR_BIN_PATH" "${args[@]}" >/dev/null 2>&1 || true
exit 0
