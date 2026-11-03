# shellcheck shell=bash
# Shared helpers for sh05.goose scripts. Sourced, not executed.

# Print the working directory of the pane the action was invoked from.
# Plugin commands run with the plugin directory as cwd, so $PWD is only a
# last resort.
resolve_cwd() {
  if [ -n "${HERDR_CWD:-}" ]; then
    printf '%s\n' "$HERDR_CWD"
    return
  fi
  local cwd=""
  if [ -n "${HERDR_BIN_PATH:-}" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
    cwd=$("$HERDR_BIN_PATH" pane get "$HERDR_PANE_ID" 2>/dev/null \
      | jq -r '.result.pane.foreground_cwd // .result.pane.cwd // empty' 2>/dev/null)
  fi
  printf '%s\n' "${cwd:-$PWD}"
}
