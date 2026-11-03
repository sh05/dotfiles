#!/usr/bin/env bash
# herdr action: open a new "goose" tab in the current workspace, in the
# invoking pane's cwd, and start `goose session` there.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"

# Actions run with the plugin directory as cwd, so look up the invoking
# pane's cwd. Fall back to $HOME — never $PWD, which would start goose inside
# this dotfiles checkout.
CWD=""
if [ -n "${HERDR_PANE_ID:-}" ]; then
  CWD=$("$HERDR" pane get "$HERDR_PANE_ID" 2>/dev/null \
    | jq -r '.result.pane.foreground_cwd // .result.pane.cwd // empty' 2>/dev/null) || true
fi
[ -d "$CWD" ] || CWD="$HOME"

new_pane=$("$HERDR" tab create --workspace "${HERDR_WORKSPACE_ID:?}" \
  --cwd "$CWD" --label goose --focus \
  | jq -r '.result.root_pane.pane_id // empty')

if [ -z "$new_pane" ]; then
  echo "sh05.goose: could not determine the new tab's pane id" >&2
  exit 1
fi

"$HERDR" pane run "$new_pane" goose session
