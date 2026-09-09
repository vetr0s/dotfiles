" Author: Nathan Tebbs
" File: .vimrc
" Modified: 2026-09-08
"
" A .vimrc suppresses vim's defaults.vim, so anything that file would have
" given us has to be spelled out here. Everything below is stock vim; the
" plugin block at the bottom is optional and guarded.

" BASICS:

" Force vim not vi
set nocompatible

set encoding=utf-8
set fileformats=unix,dos

" macOS vim is built without +X11, where unnamedplus is silently ignored
set clipboard=unnamed
if has('unnamedplus')
  set clipboard=unnamedplus,unnamed
endif

" Color
if has('termguicolors')
  " Truecolor sequences, needed when vim runs inside tmux
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Relative number
set relativenumber
set number

" Tabstop bullsplish. Spaces everywhere; clang-format is UseTab: Never and
" gofmt is handled by vim's own ftplugin/go.vim, which sets noexpandtab.
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Autoindent
set autoindent

" netrw (":edit")
filetype plugin indent on
syntax enable

" BEHAVIOR:

" Let modified buffers go to the background instead of blocking :bdelete
set hidden
set confirm

set backspace=indent,eol,start
set autoread
set history=1000
set display=truncate

" Interrupt vim before it walks every #include for a keyword completion
set complete-=i

" Otherwise <C-a> reads 007 as octal
set nrformats-=octal

" Terminal escape sequences resolve fast; mappings still get a full second
set ttimeout
set ttimeoutlen=50

set laststatus=2
set ruler
set showcmd
set splitbelow
set splitright

" FILES:

" Undo, swap, and backups belong in ~/.vim, not next to the file being edited
let s:vimdir = expand('~/.vim')
for s:sub in ['undo', 'swap', 'backup']
  if !isdirectory(s:vimdir . '/' . s:sub)
    call mkdir(s:vimdir . '/' . s:sub, 'p', 0700)
  endif
endfor

" Trailing slash encodes the full path, so same-named files cannot collide
let &directory = s:vimdir . '/swap//'
let &backupdir = s:vimdir . '/backup//'
if has('persistent_undo')
  let &undodir = s:vimdir . '/undo//'
  set undofile
  set undolevels=10000
endif

augroup vimrc_files
  autocmd!
  " Pick up changes made outside vim
  autocmd FocusGained,BufEnter * silent! checktime
  " Reopen a file where it was left, except for commit messages
  autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &filetype !~# 'commit'
        \ |   execute "normal! g`\""
        \ | endif
augroup END

" SEARCH:

set incsearch
set hlsearch
set ignorecase
set smartcase

" OTHER:

" Scrolloff
set scrolloff=10

" textwidth (formatting)
set textwidth=79

" FINDING FILES:

" Search down into every subdirectory, tab-completion
set path+=**
set wildmenu
set wildmode=longest:full,full
set wildignorecase

" Keeps ":find" and path=** usable in a repo with vendored dependencies
set wildignore+=*.o,*.obj,*.a,*.so,*.dylib,*.pyc,*.class
set wildignore+=.git/**,node_modules/**,target/**,build/**,dist/**

" NETRW:

" Tweaks
let g:netrw_banner=0
let g:netrw_browse_split=2
let g:netrw_altv=1
let g:netrw_liststyle=3

" REMAPS:

" Everything of mine hangs off the leader, so vim keeps its own Ctrl keys.
" Must precede every mapping that uses it.
let mapleader = ' '
nnoremap <Space> <Nop>

" Finding things (fzf)
nnoremap <silent> <leader>f :Files<cr>
nnoremap <silent> <leader>b :Buffers<cr>
nnoremap <silent> <leader>l :BLines<cr>
nnoremap <silent> <leader>/ :Rg<cr>
nnoremap <silent> <leader>m :Maps<cr>

" Files and buffers
nnoremap <silent> <leader>e :Explore<cr>
nnoremap <silent> <leader>k :bdelete<cr>
nnoremap <silent> <leader>w :write<cr>

" Undotree
nnoremap <silent> <leader>u :UndotreeToggle<cr>

" Redraw and drop the search highlight
nnoremap <silent> <C-l> :nohlsearch<cr><C-l>

" D and C act to end of line; Y should not be an exception
nnoremap Y y$

" Keep the selection after shifting it
xnoremap < <gv
xnoremap > >gv

" PLUGINS:

" Nothing above depends on these, so a missing vim-plug is not an error
if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/plugged')

  Plug 'junegunn/fzf', { 'commit': '029b241dbb685e60bc86bb9b5abc293e5d17119c', 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim', { 'commit': 'ddc14a6a5471147e2a38e6b32a7268282f669b0a' }
  Plug 'tpope/vim-surround', { 'commit': '3d188ed2113431cf8dac77be61b842acb64433d9' }
  Plug 'sakshamgupta05/vim-todo-highlight', { 'commit': 'f63723ef9f3a1cf0a3fd63b84b161c287fea398f' }
  Plug 'mbbill/undotree', { 'commit': '178d19e00a643f825ea11d581b1684745d0c4eda' }

  call plug#end()
endif
