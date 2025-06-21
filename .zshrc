autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
compinit

autoload -Uz colors
colors


tmp_cmd="afx"
if ! command -v ${tmp_cmd} &> /dev/null; then
    curl -sL https://raw.githubusercontent.com/b4b4r07/afx/HEAD/hack/install | bash
fi

source <(${tmp_cmd} init)

tmp_cmd="sheldon"
if ! command -v ${tmp_cmd} &> /dev/null; then
    eval "$(${tmp_cmd} source)"
fi

tmp_cmd="starship"
if ! command -v ${tmp_cmd} &> /dev/null; then
    eval "$(${tmp_cmd} init zsh)"
fi



# word split: `-`, `_`, `.`, `=`
export WORDCHARS='*?[]~&;!#$%^(){}<>'

if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi


if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    exec tmux
fi
