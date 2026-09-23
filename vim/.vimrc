" A small, predictable Vim for terminals and remote sessions.
syntax enable
filetype plugin indent on

set number
set cursorline
set colorcolumn=80
set scrolloff=5
set sidescrolloff=5
set laststatus=2
set statusline=%f\ %m%r%h%w%=%y\ %l:%c\ %p%%

if has('termguicolors')
  set termguicolors
endif
set background=dark

set ignorecase
set smartcase
set incsearch
set hlsearch
set showmatch

set backspace=indent,eol,start
set autoindent
set expandtab
set shiftwidth=4
set softtabstop=-1
set shiftround
set hidden
set confirm

set splitbelow
set splitright

set wildmenu
set wildmode=longest:full,full
set wildignorecase

set mouse=
set belloff=all
set nomodeline

let mapleader = " "
nnoremap <leader>w :write<CR>
nnoremap <silent> <leader><Space> :nohlsearch<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
