#!/usr/bin/env bash
# herdr action: open a new tab named "goose" in the current workspace, in the
# invoking pane's cwd, and start `goose session` there.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/lib.sh
. "$HERE/lib.sh"

HERDR="${HERDR_BIN_PATH:-herdr}"
CWD="$(resolve_cwd)"

ws=()
[ -n "${HERDR_WORKSPACE_ID:-}" ] && ws=(--workspace "$HERDR_WORKSPACE_ID")

new_pane=$("$HERDR" tab create "${ws[@]}" --cwd "$CWD" --label goose --focus \
  | jq -r '.. | objects | .pane_id? // empty' | head -n 1)

if [ -z "$new_pane" ]; then
  echo "sh05.goose: could not determine the new tab's pane id" >&2
  exit 1
fi

"$HERDR" pane run "$new_pane" goose session
