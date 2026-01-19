## switch to zsh (if exists)
if [ -n "$PS1" ]; then # interactive only
  for prog in /usr/bin/zsh /bin/zsh /usr/local/bin/zsh; do
    [ -x "$prog" ] && exec "$prog" "$@"
  done
fi

complete -C /usr/local/bin/vault vault

. "$HOME/.cargo/env"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

. "$HOME/.local/share/../bin/env"
