" Author: Nathan Tebbs
" File: .vimrc
" Modified: 2026-01-24

" BASICS:

" Force vim not vi
set nocompatible
set clipboard=unnamedplus

" Color
set termguicolors

" Relative number
set relativenumber
set number

" Tabstop bullsplish
set tabstop=4
set softtabstop=4
set shiftwidth=4
set noexpandtab

" Autoindent
set autoindent

" netrw (":edit")
filetype plugin indent on
syntax on

" OTHER:

" Scrolloff
set scrolloff=10

" Color column + textwidth (formatting)
set textwidth=79
set colorcolumn=+1

" FINDING FILES:

" Search down into every subdirectory, tab-completion
set path+=**
set wildmenu

" NETRW:

" Tweaks
let g:netrw_banner=0
let g:netrw_browse_split=2
let g:netrw_altv=1
let g:netrw_liststyle=3

" BASIC REMAPS:

nnoremap <C-c><C-p>i :PlugInstall<cr>
nnoremap <C-c><C-p>c :PlugClean<cr>
nnoremap <C-c><C-e> :Ex<cr>

" FZF
nnoremap <C-x>l :BLines<cr>
nnoremap <C-x>b :Buffers<cr>
nnoremap <C-x>f :Files<cr>
nnoremap <C-x>m :Maps<cr>

" Undotree
nnoremap <C-c><C-u> :UndotreeToggle<cr>

" Buffer MGMT
nnoremap <C-x>k :bdelete<cr>

" PLUGINS:

call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim'
Plug 'sheerun/vim-polyglot'
Plug 'sakshamgupta05/vim-todo-highlight'
Plug 'mbbill/undotree'
Plug 'whatyouhide/vim-gotham'
Plug 'c9rgreen/vim-colors-modus'

call plug#end()

" Set colorscheme
set background=dark
colorscheme modus

" Enable lightline
set laststatus=2

" lightline colorscheme
let g:lightline = {
      \ 'colorscheme': 'one',
      \ }
