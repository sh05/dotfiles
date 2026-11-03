# AI agent helpers: goose provider switching and herdr pane orchestration.

# --- goose provider wrappers (see CLAUDE.md "Herdr") -------------------------
#   g-claude -> claude-code   (model: G_CLAUDE_MODEL, default claude-opus-5-5)
#   g-openai -> chatgpt_codex (model: G_OPENAI_MODEL, default: goose's stored one)
# The sh05.goose hook forwards GOOSE_PROVIDER/GOOSE_MODEL into herdr's resume
# command, so a restored session comes back on the same provider.
_goose_with() {
  local provider="$1" model="$2"
  shift 2
  if [[ -n "$model" ]]; then
    GOOSE_PROVIDER="$provider" GOOSE_MODEL="$model" goose session "$@"
  else
    GOOSE_PROVIDER="$provider" goose session "$@"
  fi
}

if has 'goose'; then
  g-claude() { _goose_with claude-code "${G_CLAUDE_MODEL:-claude-opus-5-5}" "$@"; }
  g-openai() { _goose_with chatgpt_codex "${G_OPENAI_MODEL:-}" "$@"; }
fi

# --- herdr pane orchestration ------------------------------------------------
# ask-pane <pane-id-or-agent-name> <prompt...>
# Send a prompt to the agent in another pane (see `herdr agent list`), wait
# until it is idle/done/blocked, then print its recent output. Gives up after
# ASK_PANE_TIMEOUT_MS (default 10 min) instead of waiting forever.
if has 'herdr'; then
  ask-pane() {
    if (( $# < 2 )); then
      print -u2 "usage: ask-pane <pane-id-or-agent-name> <prompt...>"
      return 2
    fi
    local target_pane="$1"
    shift
    herdr agent prompt "$target_pane" "$*" --wait \
      --timeout "${ASK_PANE_TIMEOUT_MS:-600000}" || return
    herdr agent read "$target_pane"
  }
fi
