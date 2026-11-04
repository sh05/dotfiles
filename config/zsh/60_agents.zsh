# Provider-neutral Herdr pane orchestration.
# Goose provider-specific wrappers live in config/zsh/61_goose_provider_helpers.zsh.
# That generated file is present only when selected by the typed host policy.
# ask-pane <pane-id-or-agent-name> <prompt...>
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
