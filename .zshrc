### ほぼコピペ

# 環境変数
# export LANG=ja_JP.UTF-8
export LANG=en_US.UTF-8

# 色を使用出来るようにする
autoload -Uz colors
colors

# vim 風キーバインドにする
bindkey -v

# vimモードでescをjjに
bindkey "jj" vi-cmd-mode

# emacs 風キーバインドにする
# bindkey -e

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# Ctrl+Dでzshを終了しない
setopt ignore_eof

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd

# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

# 単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

########################################
# 補完

# 補完機能を有効にする
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
  /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi

########################################
# OS 別の設定
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        alias ls='ls -G'
        # alias ls='ls -G -F'
        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        ;;
esac

########################################
# プロンプト

export PR_LINE=0
export HEAVY_PR=1


#表示毎にPROMPTで設定されている文字列を評価する
setopt prompt_subst

# vcs_info
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

_vcs_precmd () { vcs_info }
add-zsh-hook precmd _vcs_precmd

zstyle ':vcs_info:git:*' stagedstr "[uncomited]"
zstyle ':vcs_info:git:*' unstagedstr "[unstaged]"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

if (($PR_LINE)); then
zstyle ':vcs_info:git:*' formats "%K{226}%F{000} [%b]%c%u %k%f"
PROMPT="%F{000}%K{046} %n@%m %k%f%F{046}%K{214}%f%F{000} %d %f%k%F{214}%K{045}%f%F{000} %D %T %f%k%F{045}%K{226}%f%k"
PROMPT=$PROMPT\$vcs_info_msg_0_
PROMPT=$PROMPT"%F{226}%f
%K{196} %k%F{196}%f"
RPROMPT=""
else
zstyle ':vcs_info:git:*' formats "%F{226}[%b]%c%u%f"
PROMPT="%F{046}[%n@%m]%f%F{046}%F{214}[%d]%f%F{045}[%D %T]%f"
RPROMPT=\$vcs_info_msg_0_
PROMPT=$PROMPT"
%F{196}->%f"
fi

if (($HEAVY_PR)); then
zstyle ':vcs_info:git:*' check-for-changes true
else
zstyle ':vcs_info:git:*' check-for-changes false
fi

########################################
# path

export PATH=/usr/local/sbin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/sbin/
export PATH=$PATH:/usr/bin
export PATH=$PATH:/sbin
export PATH=$PATH:/bin
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH=$PATH:/Applications/MAMP/bin/php/php7.1.1/bin
export PATH=$PATH:$HOME/.nodebrew/current/bin
export PATH=$PATH:$HOME/.composer/vendor/bin
export PATH=/Library/TeX/Root/bin/x86_64-darwin:$PATH

export GOPATH=$HOME
export PATH=$PATH:$GOPATH

########################################
# alias

alias la='ls -a'
alias ll='ls -l'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

alias hisg='cat ~/.zsh_history | grep'

# sudo の後のコマンドでaliasを有効にする
alias sudo='sudo '

# グローバルalias
alias -g L='| less'
alias -g G='| grep'

# editor alias
alias v='vim -p'
alias e='emacs'

# docker alias
alias d='docker'
alias ds='docker ps'
alias dsa='docker ps -a'
alias drun='docker run --rm'
alias dbd='docker build'
alias dim='docker images'
alias dstp='docker stop'
alias drm='docker rm'
alias drmi='docker rmi'

alias dc='docker-compose'
alias dcup='docker-compose up'
alias dcbuild='docker-compose build'
alias dcrun='docker-compose run --rm'


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/nakamotoshogo/res_hot_dev/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/nakamotoshogo/res_hot_dev/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/nakamotoshogo/res_hot_dev/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/nakamotoshogo/res_hot_dev/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="/usr/local/opt/ncurses/bin:$PATH"

# env
export PATH="/usr/local/opt/ncurses/bin:$PATH"
## zshrc
# export ZSHRC="$HOME/.zshrc"
export Z="$HOME/.zshrc"
## vimrc
# export VIMRC="$HOME/.vimrc"
export V="$HOME/.vimrc"
## dein
# export DEIN="$HOME/.vim/rc/"
export D="$HOME/.vim/rc/"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# complettion
eval "$(gh completion -s zsh)"

