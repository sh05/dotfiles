" leader
let mapleader = "\<Space>"

" <Leader>i でコードをインデント整形
map <Leader>i gg=<S-g><C-o><C-o>zz

nmap <Leader>p3 :!python3 %
nmap <Leader>py :!python %

autocmd QuickFixCmdPost *grep* cwindow

" nmap <Leader>v V
let maplocalleader = ","

set shell=zsh

" クリップボードを共有
set clipboard+=unnamed

set nf=alpha
" ファイル読み込み時の文字コードの設定
set encoding=utf-8
" Vim script内でマルチバイト文字を使う場合の設定
scriptencoding utf-8
" 保存時の文字コード
set fileencoding=utf-8
" 読み込み時の文字コードの自動判別. 左側が優先される
set fileencodings=ucs-boms,utf-8,euc-jp,cp932

set binary noeol

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

" tex
set conceallevel=0
let g:tex_conceal = ""

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
highlight Folded guibg=grey guifg=blue
highlight FoldColumn guibg=darkgrey guifg=white

" netrwのデフォルトをtreeにする
" let g:netrw_liststyle = 3
" netrwのvで開く方向を右にする
let g:netrw_altv = 1
" netrwのoで開く方向を右にする
let g:netrw_alto = 1
" netrwのEnterでPと同じにする
let g:netrw_browse_split = 4

" ウィンドウを閉じずにバッファを閉じる
command! Bd :bp | :sp | :bn | :bd
" 保存してバッファを閉じる
command Wd write|bdelete

" set sessionoptions-=globals
" set sessionoptions-=localoptions
" set sessionoptions-=options
set sessionoptions+=options

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


  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
    " for vim-delve
    call dein#add('Shougo/vimshell.vim')
    call dein#add('Shougo/vimproc.vim', {'build' : 'make'})
  endif

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

let s:removed_plugins = dein#check_clean()
if len(s:removed_plugins) > 0
  call map(s:removed_plugins, "delete(v:val, 'rf')")
  call dein#recache_runtimepath()
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

set completeopt+=menuone
autocmd BufNewFile,BufRead *.log set filetype=log
autocmd BufNewFile,BufRead .zshrc set filetype=sh
set conceallevel=0

" setting for lsp
function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  imap <c-n> <Plug>(asyncomplete_force_refresh)
  imap <c-p> <Plug>(asyncomplete_force_refresh)
  imap <c-x> <Plug>(asyncomplete_force_refresh)
  inoremap <expr> <cr> pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
  nmap <buffer> <Leader>ca <plug>(lsp-code-action)
  nmap <buffer> <Leader>cl <plug>(lsp-code-lens)
  nmap <buffer> <Leader>td <plug>(lsp-type-definition)
  nmap <buffer> <Leader>gd <plug>(lsp-definition)
  nmap <buffer> <Leader>im <plug>(lsp-implementation)
  nmap <buffer> <Leader>rn <plug>(lsp-rename)
  nmap <buffer> <Leader>rf <plug>(lsp-references)
  nmap <buffer> <Leader>dd <plug>(lsp-document-diagnostics)
  nmap <buffer> <Leader>df <plug>(lsp-document-format)
  nnoremap <leader>pc :pclose<CR>
  nnoremap <leader>ph :LspHover<CR>
  nnoremap <leader>pn :LspNextDiagnostic<CR>
  " Hide signcolumn.
  " Show diagnostics message to status line
  let g:asyncomplete_auto_completeopt = 1
  let g:asyncomplete_auto_popup = 1
  let g:asyncomplete_log_file = expand('~/asyncomplete.log')
  let g:asyncomplete_popup_delay = 200
  let g:asyncomplete_remove_duplicates = 1
  let g:asyncomplete_smart_completion = 1
  let g:lsp_async_completion = 1
  let g:lsp_auto_enable = 1
  let g:lsp_diagnostics_enabled = 1
  let g:lsp_diagnostics_echo_cursor = 1
  let g:lsp_diagnostics_float_cursor = 1
  let g:lsp_diagnostics_signs_enabled = 0
  let g:lsp_fold_enabled = 0
  let g:lsp_highlight_references_enabled = 1
  let g:lsp_highlights_enabled = 1
  let g:lsp_insert_text_enabled = 0
  let g:lsp_log_file = expand('~/vim-lsp.log')
  let g:lsp_log_verbose = 0
  let g:lsp_preview_autoclose = 0
  let g:lsp_preview_doubletap = 0
  let g:lsp_preview_float = 1
  let g:lsp_preview_keep_focus = 0
  let g:lsp_settings_filetype_go = ['gopls', 'golangci-lint-langserver']
  let g:lsp_signature_help_enabled = 0
  let g:lsp_signs_enabled = 1
  let g:lsp_signs_error = {'text': ' '}
  let g:lsp_signs_hint = {'text': ' '}
  let g:lsp_signs_warning = {'text': ' '}
  let g:lsp_text_edit_enabled = 1
  let g:lsp_textprop_enabled = 0
  let g:lsp_virtual_text_enabled = 0

  " Highlight LSP warnings strongly (like errors)
  highlight link LspWarningHighlight Error

  set completeopt-=preview
  inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"
  function! s:check_back_space() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~ '\s'
  endfunction
  inoremap <silent><expr> <TAB>
    \ pumvisible() ? "\<C-n>" :
    \ <SID>check_back_space() ? "\<TAB>" :
    \ asyncomplete#force_refresh()
  inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
endfunction

augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

let g:lsp_settings = {
      \    'gopls': {
      \      'workspace_config': {
      \        'usePlaceholders': v:true,
      \        'analyses': { 'fillstruct': v:true, },
      \      },
      \      'initialization_options': {
      \        'usePlaceholders': v:true,
      \        'analyses': { 'fillstruct': v:true, },
      \      },
      \    },
      \    'pylsp-all': {
      \      'workspace_config': {
      \        'pylsp': {
      \          'configurationSources': ['flake8'],
      \          'plugins': {
      \            'flake8': { 'enabled': 1 },
      \            'mccabe': { 'enabled': 0 },
      \            'pycodestyle': { 'enabled': 0 },
      \            'pyflakes': { 'enabled': 0 },
      \            'pylsp_mypy': {'enabled': 0},
      \            'comment': {'mypyはpylspのvenvに入れる必要がある': '~/.local/share/vim-lsp-settings/servers/pylsp-all/venv/bin/pip3 install pylsp-myp'}
      \          }
      \        }
      \      }
      \    }
      \  }
