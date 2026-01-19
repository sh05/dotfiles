autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
compinit

autoload -Uz colors
colors

if ! command -v afx &> /dev/null; then
    curl -sL https://raw.githubusercontent.com/b4b4r07/afx/HEAD/hack/install | bash
fi

source <(afx init)
# word split: `-`, `_`, `.`, `=`
export WORDCHARS='*?[]~&;!#$%^(){}<>'

if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi

if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [[ $TERM_PROGRAM != "vscode" ]]; then
    exec tmux
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

. "$HOME/.local/share/../bin/env"

alias claude="$HOME/.claude/local/claude"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section
