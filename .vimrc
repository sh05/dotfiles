" エマージェンシ
set clipboard+=unnamed

" ファイル読み込み時の文字コードの設定
set encoding=utf-8

" Vim script内でマルチバイト文字を使う場合の設定
scriptencoding utf-8

" 保存時の文字コード
set fileencoding=utf-8

" 読み込み時の文字コードの自動判別. 左側が優先される
set fileencodings=ucs-boms,utf-8,euc-jp,cp932

" 改行コードの自動判別. 左側が優先される
set fileformats=unix,dos,mac

" □や○文字が崩れる問題を解決
set ambiwidth=double

" 文字コード表示
set statusline+=[%{has('multi_byte')&&\&fileencoding!=''?&fileencoding:&encoding}]

" タブ入力を複数の空白入力に置き換える
set expandtab

" 画面上でタブ文字が占める幅
set tabstop=4

" 連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set softtabstop=4

" 改行時に前の行のインデントを継続する
set autoindent

" 改行時に前の行の構文をチェックし次の行のインデントを増減する
set smartindent

" smartindentで増減する幅
set shiftwidth=2

" 行番号を表示
set number

" インクリメンタルサーチ. １文字入力毎に検索を行う
set incsearch

" 検索パターンに大文字小文字を区別しない
set ignorecase

" 検索パターンに大文字を含んでいたら大文字小文字を区別する
set smartcase

" 検索結果をハイライト"
set hlsearch

" 矢印キーを無効にする
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>

" insertをjjで抜ける
inoremap <silent> jj <ESC>

" 括弧の対応関係を一瞬表示する
set showmatch

" Vimの「%」を拡張する
source $VIMRUNTIME/macros/matchit.vim

" コマンドモードの補完
set wildmenu

" 保存するコマンド履歴の数
set history=20

" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" 設定開始
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " プラグインリストを収めた TOML ファイル
  " 予め TOML ファイル（後述）を用意しておく
  let g:rc_dir    = expand('~/.vim/rc')
  let s:toml      = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  " TOML を読み込み、キャッシュしておく
  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  " 設定終了
  call dein#end()
  call dein#save_state()
endif

" もし、未インストールものものがあったらインストール
if dein#check_install()
  call dein#install()
endif

filetype plugin indent on

" 色セット
syntax on
colorscheme hybrid
