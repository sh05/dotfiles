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
set shiftwidth=4

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

" 括弧の対応関係を一瞬表示する
set showmatch

" Vimの「%」を拡張する
source $VIMRUNTIME/macros/matchit.vim

" コマンドモードの補完
set wildmenu

" 保存するコマンド履歴の数
set history=5000

" neobundle settings {{{
if has('vim_starting')
  set nocompatible

  " neobundle をインストールしていない場合は自動インストール
  if !isdirectory(expand("~/.vim/bundle/neobundle.vim/"))
    echo "install neobundle..."
    " vim からコマンド呼び出しているだけ neobundle.vim のクローン
    :call system("git clone https://github.com/Shougo/neobundle.vim.git ~/.vim/bundle/neobundle.vim")
  endif
  " runtimepath の追加は必須
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif
call neobundle#begin(expand('~/.vim/bundle'))
let g:neobundle_default_git_protocol='https'

" neobundle#begin - neobundle#end の間に導入するプラグインを記載します。
NeoBundleFetch 'Shougo/neobundle.vim'

"非同期処理を提供してくれる縁の下の力持ち
NeoBundle 'Shougo/vimproc', {
\ 'build' : {
\     'windows' : 'make -f make_mingw32.mak',
\     'cygwin' : 'make -f make_cygwin.mak',
\     'mac' : 'make -f make_mac.mak',
\     'unix' : 'make -f make_unix.mak',
\    },
\ }

" 色
NeoBundle 'tomasr/molokai'

" " 保存時に構文チェック
" NeoBundle 'vim-syntastic/syntastic'
" let g:syntastic_enable_signs=1
" let g:syntastic_auto_loc_list=2
" let g:syntastic_mode_map = {'mode': 'passive'}
" augroup AutoSyntastic
"     autocmd!
"     autocmd InsertLeave,TextChanged * call s:syntastic()
" augroup END
" function! s:syntastic()
"     w
"     SyntasticCheck
" endfunction

 "ifとかの終了宣言を自動で挿入してくれる
NeoBundleLazy 'tpope/vim-endwise', {
  \ 'autoload' : { 'insert' : 1,}}

" ステータスラインの表示内容強化
NeoBundle 'vim-airline/vim-airline'
let g:airline#extensions#tabline#enabled = 1
" テーマ
NeoBundle 'vim-airline/vim-airline-themes'
let g:airline_theme='term'

" インデントの可視化
NeoBundle 'Yggdroot/indentLine'

" " ~/.pyenv/shimsを$PATHに追加
" " jedi-vim や vim-pyenc のロードよりも先に行う必要がある、はず。
" let $PATH = "~/.pyenv/shims:".$PATH
" " pythonのやつ
" NeoBundle 'davidhalter/jedi-vim'
" " pyenv 処理用に vim-pyenv を追加
" " Note: depends が指定されているため jedi-vim より後にロードされる（ことを期待）
" NeoBundleLazy "lambdalisue/vim-pyenv", {
"       \ "depends": ['davidhalter/jedi-vim'],
"       \ "autoload": {
"       \   "filetypes": ["python", "python3"]
"       \ }}

" html
NeoBundle 'mattn/emmet-vim'

"LaTex
NeoBundle 'lervag/vimtex'
filetype plugin on
let tex_flavor = 'latex'
set grepprg=grep\ -nH\ $*
set shellslash
let g:Tex_CompileRule_dvi = 'platex --interaction=nonstopmode $*'
let g:Tex_CompileRule_pdf = 'dvipdfmx $*.dvi'
let g:Tex_FormatDependency_pdf = 'dvi,pdf'

" コメントON/OFFを手軽に実行 ctl と - を二回
NeoBundle 'tomtom/tcomment_vim'

" vimrc に記述されたプラグインでインストールされていないものがないかチェックする
NeoBundleCheck
call neobundle#end()
filetype plugin indent on

" 色セット
syntax on
colorscheme molokai
