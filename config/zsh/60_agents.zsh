# AI agent helpers: goose provider switching and herdr pane orchestration.

# --- goose provider wrappers -------------------------------------------------
# Each subscription is reached through goose's subscription-backed provider:
#   g-claude  -> claude-code    drives the `claude` CLI with its own login
#                               (Claude Pro). Not listed in `goose configure`
#                               and needs no setup there, but goose has no
#                               stored model for it, so one must be passed:
#                               defaults to Opus 5.5 (full ID, so it does
#                               not drift like the `opus` alias).
#   g-openai  -> chatgpt_codex  ChatGPT OAuth (ChatGPT Plus); uses the model
#                               stored for it by `goose configure`.
# Override either model with G_CLAUDE_MODEL / G_OPENAI_MODEL, e.g.
# `export G_CLAUDE_MODEL=sonnet` in ~/.zshrc.local.
#
# There is no g-gemini: Gemini CLI stopped serving Google AI Pro accounts on
# 2026-06-18, goose's gemini_oauth is deprecated, and its successor `agy`
# (Antigravity CLI) has no ACP mode and no goose provider. Use `agy` directly.
#
# GOOSE_PROVIDER/GOOSE_MODEL are also read by the sh05.goose hook, which
# hands them to herdr so a restored session resumes on the same provider.
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
# ask-pane <pane-or-agent> <prompt...>
# Send a prompt to the agent (claude / codex / agy / goose) in another pane,
# wait until it is idle/done/blocked, then print its recent output.
if has 'herdr'; then
  ask-pane() {
    if (( $# < 2 )); then
      print -u2 "usage: ask-pane <pane-or-agent> <prompt...>"
      return 2
    fi
    local target_pane="$1"
    shift
    herdr agent prompt "$target_pane" "$*" --wait || return
    herdr agent read "$target_pane"
  }
fi
