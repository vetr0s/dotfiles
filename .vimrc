" Author: Nathan Tebbs
" File: .vimrc
" Modified: 2026-01-22

" BASICS:

" Force vim not vi
set nocompatible

" Relative number
set relativenumber
set number

" Clipboard
set clipboard=unnamedplus

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
nnoremap <C-x><C-s> :so %<cr>
nnoremap <C-c><C-i> :PlugInstall<cr>
nnoremap <C-c><C-c> :PlugClean<cr>
nnoremap <C-c>e :Ex<cr>

" FZF
nnoremap <C-s>l :BLines<cr>
nnoremap <C-s>b :Buffers<cr>
nnoremap <C-s>f :Files<cr>
nnoremap <C-s>k :Maps<cr>

" Undotree
nnoremap <C-c><C-u> :UndotreeToggle<cr>

" PLUGINS:
call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'sheerun/vim-polyglot'
Plug 'sakshamgupta05/vim-todo-highlight'
Plug 'mbbill/undotree'
Plug 'whatyouhide/vim-gotham'

call plug#end()

" Set colorscheme
set background=dark
colorscheme gotham

" Enable lightline
set laststatus=2

" lightline colorscheme
let g:lightline = {
      \ 'colorscheme': 'one',
      \ }
