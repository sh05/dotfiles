" クリップボードを共有
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
" set smartcase

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

" カーソルの左右移動で行末から次の行の行頭への移動が可能になる
" set whichwrap=b,s,h,l,<,>,[,],~

" 行が折り返し表示されていた場合、行単位ではなく表示行単位でカーソルを移動する
nnoremap j gj
nnoremap k gk
nnoremap <down> gj
nnoremap <up> gk

if &term =~ "xterm"
  let &t_SI .= "\e[?2004h"
  let &t_EI .= "\e[?2004l"
  let &pastetoggle = "\e[201~"

  function XTermPasteBegin(ret)
    set paste
    return a:ret
  endfunction

  inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif

" バックスペースキーの有効化
set backspace=indent,eol,start

set cursorline " カーソルラインをハイライト

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

" コードの折り畳み、最初は展開されている状態にする
set foldmethod=indent
set foldcolumn=4
autocmd BufRead * normal zR

" netrwのデフォルトをtreeにする
let g:netrw_liststyle = 3
" netrwのvで開く方向を右にする
let g:netrw_altv = 1
" netrwのoで開く方向を右にする
let g:netrw_alto = 1
" netrwのEnterでPと同じにする
let g:netrw_browse_split = 4

" ウィンドウを閉じずにバッファを閉じる
command! Bd :bp | :sp | :bn | :bd

" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" set filetypes as typescriptreact
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

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
set background=dark

" テキスト背景色
au ColorScheme * hi Normal ctermbg=none

" 括弧対応
au ColorScheme * hi MatchParen cterm=bold ctermfg=214 ctermbg=black

" スペルチェック
au Colorscheme * hi SpellBad ctermfg=23 cterm=none ctermbg=none
set background=dark

au VimEnter * call dein#call_hook('post_source')

" 色いじったりしてキャッシュが邪魔なとき用
" call dein#recache_runtimepath()

highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight LineNr ctermbg=none
highlight Folded ctermbg=none
highlight EndOfBuffer ctermbg=none 

" netrwをツリースタイルにしているとsession読み込み時に反映されないから開き直す
au SessionLoadPost NetrwTreeListing Ex

" golang lsp
function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> <C-]> <plug>(lsp-definition)
  nmap <buffer> <f2> <plug>(lsp-rename)
  nmap <buffer> <Leader>d <plug>(lsp-type-definition)
  nmap <buffer> <Leader>r <plug>(lsp-references)
  nmap <buffer> <Leader>i <plug>(lsp-implementation)
  inoremap <expr> <cr> pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
endfunction

augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
command! LspDebug let lsp_log_verbose=1 | let lsp_log_file = expand('~/lsp.log')

let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
" let g:asyncomplete_auto_popup = 1
" let g:asyncomplete_auto_completeopt = 0
let g:asyncomplete_popup_delay = 200
let g:lsp_text_edit_enabled = 1
let g:lsp_preview_float = 1
let g:lsp_diagnostics_float_cursor = 1
let g:lsp_settings_filetype_go = ['gopls', 'golangci-lint-langserver']

let g:lsp_settings = {}
let g:lsp_settings['gopls'] = {
  \  'workspace_config': {
  \    'usePlaceholders': v:true,
  \    'analyses': {
  \      'fillstruct': v:true,
  \    },
  \  },
  \  'initialization_options': {
  \    'usePlaceholders': v:true,
  \    'analyses': {
  \      'fillstruct': v:true,
  \    },
  \  },
  \}

if executable('dart')                                                                                          
    augroup LspDart
        au!
        autocmd User lsp_setup call lsp#register_server({
                    \ 'name': 'analysis_server.dart.snapshot',
                    \ 'cmd': {server_info->[
                    \           $DART_SDK.'/usr/local/bin/dart',
                    \           $DART_SDK.'/bin/snapshots/analysis_server.dart.snapshot',
                    \           '--lsp',
                    \           ]},
                    \ 'root_uri':{server_info->lsp#utils#path_to_uri(
                    \     lsp#utils#find_nearest_parent_file_directory(
                    \         lsp#utils#get_buffer_path(),
                    \         ['.git/', 'analysis_options.yaml']
                    \     ))},
                    \ 'allowlist': ['dart'],
                    \ 'initialization_options': v:null,
                    \ 'config': {},
                    \ 'workspace_config': {},
                    \ })
        autocmd FileType dart setlocal omnifunc=lsp#complete
    augroup END
endif

" For snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

set completeopt+=menuone
