local map = vim.keymap.set

map('n', '<leader>w', '<cmd>write<CR>', { desc = 'Write buffer' })
map('n', '<leader><Space>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>cc', ':!', { desc = 'Shell command' })
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

map('n', '-', '<cmd>Explore<CR>', { desc = "Open the file's directory" })
map('n', '<leader>e', '<cmd>Lexplore<CR>', { desc = 'Toggle the file tree' })
