export PATH=/usr/local/mysql/bin:$PATH
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

# lsの色
export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

alias ls="ls -G"
alias gls="gls --color"
alias -g C="| color"

zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

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
# プロンプト
# 色はこのワンライナで確認
# for c in {000..255}; do echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;done;echo

export PR_LINE=1
export HEAVY_PR=0
export VIM_INFO=0
export HOSTNAME_COLOR=200

if [ `hostname` = "R-MBP-13UBH-220" ]; then
export REMOTE_ALERT=""
else
export REMOTE_ALERT="%F{000}%K{$HOSTNAME_COLOR} REMOTE %k%f"
fi

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

# export VIM_NORMAL="%F{196}%K{black}->%k%f"
export VIM_NORMAL="%F{196}->%f"
# export VIM_INSERT="%F{039}%K{black}->%k%f"
export VIM_INSERT="%F{039}->%f"

function zle-line-init zle-keymap-select {
    PROMPT=$PR_BODY"
${${KEYMAP/vicmd/$VIM_NORMAL}/(main|viins)/$VIM_INSERT}"
    zle reset-prompt
}

function show_mode() {
  ((VIM_INFO=!VIM_INFO))
  if (($VIM_INFO)); then
    RPROMPT=""
    zle -N zle-line-init
    zle -N zle-keymap-select
  else
    RPROMPT=""
    zle -D zle-line-init
    zle -D zle-keymap-select
  fi
}

function switch_pr() {
  ((PR_LINE=!PR_LINE))
  if (($PR_LINE)); then
    zstyle ':vcs_info:git:*' formats "%K{226}%F{000} [%b]%c%u %k%f"
    PROMPT=$REMOTE_ALERT"%F{000}%K{046} %n@%m %k%f%F{046}%K{214}%f%F{000} %d %f%k%F{214}%K{045}%f%F{000} %D %T %f%k%F{045}%K{226}%f%k"
    PROMPT=$PROMPT\$vcs_info_msg_0_
    PROMPT=$PROMPT"%F{226}%f"
    export PR_BODY=$PROMPT
    # PROMPT=$PROMPT"%F{226}%f
# %K{196} %k%F{196}%f"
  else
    zstyle ':vcs_info:git:*' formats "%F{226}[%b]%c%u%f"
    # PROMPT=$REMOTE_ALERT"%K{black}%F{046}[%n@%m]%f%F{046}%F{214}[%d]%f%F{045}[%D %T]%f%k"
    PROMPT=$REMOTE_ALERT"%F{046}[%n@%m]%f%F{046}%F{214}[%d]%f%F{045}[%D %T]%f"
    PROMPT=$PROMPT\$vcs_info_msg_0_
    export PR_BODY=$PROMPT
    # PROMPT=$PROMPT"
# %F{196}->%f"
  fi
}

function git_check() {
  ((HEAVY_PR=!HEAVY_PR))
  if (($HEAVY_PR)); then
    zstyle ':vcs_info:git:*' check-for-changes true
  else
    zstyle ':vcs_info:git:*' check-for-changes false
  fi
}

show_mode
switch_pr
git_check

########################################
# path

export PATH=/usr/local/sbin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/sbin/
export PATH=$PATH:/usr/bin
export PATH=$PATH:/sbin
export PATH=$PATH:/bin
export PATH=$PATH:/usr/local/opt/ruby/bin
export PATH="/usr/local/opt/ruby/bin:$PATH"
export GOPATH=$HOME
export PATH=$PATH:$GOPATH
export PATH=$PATH:$GOPATH/bin

HOMEBREW_PREFIX=$(brew --prefix)
if [[ -d "$HOMEBREW_PREFIX/opt/dart/libexec" ]]; then
  export DART_SDK="$HOMEBREW_PREFIX/opt/dart/libexec"
  PATH="$DART_SDK:$PATH"
fi

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
alias -g W='| wc -l'

# editor alias
alias v='vim -p'
alias vim='/usr/local/bin/vim'
alias npvim='vim --noplugin'
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

# env
export PATH="/usr/local/opt/ncurses/bin:$PATH"
## zshrc
# export ZSHRC="$HOME/.zshrc"
export Z="$HOME/.zshrc"
## vimrc
# export VIMRC="$HOME/.vimrc"
export V="$HOME/.vimrc"
# export DEIN="$HOME/.vim/rc/"
export D="$HOME/.vim/rc/"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# eval "$(starship init zsh)"
export TIMES_CHANNEL_ID="C01TCDLQAEP"
export DEBUG_CHANNEL_ID="C027BA3PE8L"

function gitMain() {
  git config --global --unset-all user.name
  git config --global user.name "Shogo Nakamoto"
  git config --global user.email "shnakamo@yahoo-corp.jp"
  git config --list
}

function gitSub() {
  git config --global --unset-all user.name
  git config --global user.name "sh05"
  git config --global user.email "shogonakamoto0107@gmail.com"
  git config --list
}

eval "$(anyenv init -)"
