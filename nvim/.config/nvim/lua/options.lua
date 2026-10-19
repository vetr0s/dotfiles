local o = vim.opt

o.number = true
o.cursorline = true
o.colorcolumn = '80'
o.signcolumn = 'yes'
o.scrolloff = 5
o.sidescrolloff = 5

o.ignorecase = true
o.smartcase = true

o.expandtab = true
o.shiftwidth = 4
o.softtabstop = -1
o.shiftround = true

o.confirm = true
o.undofile = true
o.splitbelow = true
o.splitright = true

o.wildmode = 'longest:full,full'
o.wildignorecase = true

o.mouse = ''
o.modeline = false

vim.diagnostic.config({ virtual_text = true })

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
