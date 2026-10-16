-- Neovim config built on 0.12 built-ins and a short plugin list.
-- Vim keeps the portable setup in vim/.vimrc. This file does not source it.
vim.g.mapleader = ' '

require('options')
require('keymaps')
require('plugins')
require('lsp')
