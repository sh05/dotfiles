typeset -gx -U path
path=( \
        ~/bin(N-/) \
        "${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin" \
        /opt/homebrew/bin(N-/) \
        ~/.go/bin(N-/) \
        /usr/local/bin(N-/) \
        /usr/sbin(N-/) \
        ~/.local/bin(N-/) \
        ~/.tmux/bin(N-/) \
        ~/.nimble/bin(N-/) \
        ~/.yarn/bin(N-/) \
        ~/.nimble/bin(N-/) \
        ~/.deno/bin(N-/) \
        ~/Library/ApplicationSupport/Coursier/bin(N-/) \
        /usr/local/opt/libpq/bin(N-/) \
        /usr/local/opt/llvm/bin(N-/) \
        ~/.gem/ruby/2.6.0/bin(N-/) \
        ~/Library/Python/3.9/bin(N-/) \
        /opt/homebrew/opt/openjdk@17/bin(N-/) \
        $HOME/.krew/bin(N-/) \
        ~/.luarocks/bin(N-/) \
        ~/Library/Application\ Support/Coursier/bin(N-/) \
        ~/.cargo/bin(N-/) \
        ~/.rd/bin(N-/) \
        ~/.tmux/plugins/tpm/bin(N-/) \
        $HOME/.mySetting(N-/) \
        "$path[@]" \
    )


typeset -gx -U fpath
fpath=( \
        ~/.zsh/Completion(N-/) \
        ~/.zsh/functions(N-/) \
        ~/.zsh/plugins/zsh-completions(N-/) \
        /usr/local/share/zsh/site-functions(N-/) \
        $fpath \
    )

# History
# History file
export HISTFILE=~/.zsh_history
# History size in memory
export HISTSIZE=1000000
# The number of histsize
export SAVEHIST=1000000
# The size of asking history
export LISTMAX=1000000
# Do not add in root
if [[ $UID == 0 ]]; then
    unset HISTFILE
    export SAVEHIST=0
fi

# Config
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
source "$HOME/.cargo/env"

export NPM_CONFIG_PREFIX=${XDG_DATA_HOME:-$HOME/.local/share}/npm-global
export PATH=$NPM_CONFIG_PREFIX/bin:$PATH

export AQUA_GLOBAL_CONFIG=$XDG_CONFIG_HOME/aqua/aqua.yaml
export AQUA_PROGRESS_BAR="true"
export AQUA_POLICY_CONFIG=$XDG_CONFIG_HOME/aqua/aqua-policy.yaml
. "$HOME/.cargo/env"
