# 少し凝った zshrc
# License : MIT
# http://mollifier.mit-license.org/

########################################
# 環境変数
export LANG=ja_JP.UTF-8


# 色を使用出来るようにする
autoload -Uz colors
colors

# emacs 風キーバインドにする
#bindkey -e

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# プロンプト
# 1行表示
# PROMPT="%~ %# "
# 2行表示
PROMPT="%{${fg[green]}%}[%d]%{${reset_color}%}
 ${fg[red]}%}->%{${reset_color} "


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
# vcs_info
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:*' formats '%F{yello}%b %f'
zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}
add-zsh-hook precmd _update_vcs_info_msg

## RPROMPT
#RPROMPT=$'`branch-status-check`'
#setopt prompt_subst #表示毎にPROMPTで設定されている文字列を評価する

# {{{ methods for RPROMPT
# fg[color]表記と$reset_colorを使いたい
# @see https://wiki.archlinux.org/index.php/zsh
#autoload -U colors; colors
#function branch-status-check {
#    local prefix branchname suffix
#        # .gitの中だから除外
#        if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
#            return
#        fi
#        branchname=`get-branch-name`
#        # ブランチ名が無いので除外
#        if [[ -z $branchname ]]; then
#            return
#        fi
#        prefix=`get-branch-status` #色だけ返ってくる
#        suffix='%{'${reset_color}'%}'
#        echo ${prefix}'\ue0a0'${branchname}${suffix}
#}
#function get-branch-name {
#    # gitディレクトリじゃない場合のエラーは捨てます
#    echo `git rev-parse --abbrev-ref HEAD 2> /dev/null`
#}
#function get-branch-status {
#    local res color
#        output=`git status --short 2> /dev/null`
#        if [ -z "$output" ]; then
#            res=':' # status Clean
#            color='%{'${fg[green]}'%}'
#        elif [[ $output =~ "[\n]?\?\? " ]]; then
#            res='?:' # Untracked
#            color='%{'${fg[yellow]}'%}'
#        elif [[ $output =~ "[\n]? M " ]]; then
#            res='M:' # Modified
#            color='%{'${fg[red]}'%}'
#        else
#            res='A:' # Added to commit
#            color='%{'${fg[cyan]}'%}'
#        fi
#        # echo ${color}${res}'%{'${reset_color}'%}'
#        echo ${color} # 色だけ返す
#}
# }}}

########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# Ctrl+Dでzshを終了しない
#setopt ignore_eof

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

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

########################################
# エイリアス

alias la='ls -a'
alias ll='ls -l'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

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
        alias ls='ls -G -F'
        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        ;;
esac

# vim:set ft=zsh:
export PATH=/bin:/usr/bin:/usr/local/bin:/usr/bin:/usr/local/bin:/Users/nakamotoshogo/.composer/vendor/bin:/usr/sbin/:/sbin

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export PATH=/Applications/MAMP/bin/php/php7.1.1/bin:/usr/local/Cellar/pyenv-virtualenv/1.1.0/shims:/Users/nakamotoshogo/.pyenv/shims:/Users/nakamotoshogo/.pyenv/bin:/bin:/usr/bin:/usr/local/bin:/usr/bin:/usr/local/bin:/Users/nakamotoshogo/.composer/vendor/bin:/usr/sbin/:/sbin
