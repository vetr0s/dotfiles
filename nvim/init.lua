-- ~/.config/nvim/init.lua
-- Minimal Neovim config based ../.vimrc for desktop environment usage
-- Author: Nathan Tebbs
-- Created: 2026-01-24

-- =====================
-- Options
-- =====================
vim.opt.compatible = false -- harmless; Neovim is nocompatible by default
vim.opt.clipboard = "unnamedplus"

vim.opt.relativenumber = true
vim.opt.number = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false

vim.opt.autoindent = true

vim.opt.scrolloff = 10

vim.opt.textwidth = 79
vim.opt.colorcolumn = "+1"

-- Finding files
vim.opt.path:append("**")
vim.opt.wildmenu = true

-- True color (good default in Neovim)
vim.opt.termguicolors = true

-- =====================
-- netrw tweaks
-- =====================
vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 2
vim.g.netrw_altv = 1
vim.g.netrw_liststyle = 3

-- =====================
-- Keymaps (same intent)
-- =====================
local map = vim.keymap.set
map("i", "<C-h>", "<C-w>")
map("i", "<C-BS>", "<C-w>")
map("i", "<C-Backspace>", "<C-w>")
map("n", "<C-c><C-p>i", "<cmd>Lazy sync<cr>", { desc = "Plugins: install/update" })
map("n", "<C-c><C-p>c", "<cmd>Lazy clean<cr>", { desc = "Plugins: clean" })
map("n", "<C-c><C-e>", "<cmd>Ex<cr>", { desc = "netrw" })

-- FZF (provided by fzf.vim)
map("n", "<C-x>l", "<cmd>BLines<cr>")
map("n", "<C-x>b", "<cmd>Buffers<cr>")
map("n", "<C-x>f", "<cmd>Files<cr>")
map("n", "<C-x>m", "<cmd>Maps<cr>")

-- Undotree
map("n", "<C-c><C-u>", "<cmd>UndotreeToggle<cr>")

-- Buffer mgmt
map("n", "<C-x>k", "<cmd>bdelete<cr>")

-- =====================
-- Plugins
-- =====================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- FZF
  { "junegunn/fzf", build = function() vim.fn["fzf#install"]() end },
  { "junegunn/fzf.vim" },

  -- Your Vim plugins
  { "tpope/vim-surround" },
  { "itchyny/lightline.vim" },

  { "windwp/nvim-autopairs" },

  { "sheerun/vim-polyglot" },
  { "sakshamgupta05/vim-todo-highlight" },
  { "mbbill/undotree" },

  -- Colors
  { "whatyouhide/vim-gotham" },
  { "c9rgreen/vim-colors-modus" },
})

-- =====================
-- UI / Theme
-- =====================
vim.opt.background = "dark"
vim.cmd.colorscheme("modus")

vim.opt.laststatus = 2
vim.g.lightline = { colorscheme = "one" } -- keep exactly what you had
