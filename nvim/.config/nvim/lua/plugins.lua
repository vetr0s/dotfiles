local gh = function(repo) return 'https://github.com/' .. repo end

-- Registered before vim.pack.add so a fresh install also builds the parsers.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind ~= 'delete' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end,
})

vim.pack.add({
  gh('neovim/nvim-lspconfig'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  gh('ibhagwan/fzf-lua'),
  gh('lewis6991/gitsigns.nvim'),
  gh('stevearc/conform.nvim'),
  gh('echasnovski/mini.nvim'),
  gh('Mofiqul/vscode.nvim'),
  -- Release tags ship a prebuilt fuzzy matcher, so no Rust toolchain is needed.
  { src = gh('saghen/blink.cmp'), version = vim.version.range('1.*') },
}, { confirm = false })

-- Clears the background so kitty's opacity shows through.
require('vscode').setup({ transparent = true })
vim.cmd.colorscheme('vscode')

local map = vim.keymap.set

require('nvim-treesitter').install({
  'bash',
  'cpp',
  'java',
  'javascript',
  'json',
  'rust',
  'toml',
  'tsx',
  'typescript',
})
vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    -- start() errors when no parser exists for the filetype.
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

local fzf = require('fzf-lua')
fzf.setup({})
map('n', '<leader>f', fzf.files, { desc = 'Find files' })
map('n', '<leader>o', fzf.oldfiles, { desc = 'Recent files' })
map('n', '<leader>b', fzf.buffers, { desc = 'Buffers' })
map('n', '<leader>/', fzf.live_grep, { desc = 'Grep project' })
map('n', '<leader>*', fzf.grep_cword, { desc = 'Grep word under cursor' })
map('x', '<leader>*', fzf.grep_visual, { desc = 'Grep selection' })
map('n', '<leader>l', fzf.blines, { desc = 'Search buffer lines' })
map('n', '<leader>r', fzf.resume, { desc = 'Resume last picker' })
map('n', '<leader>s', fzf.lsp_document_symbols, { desc = 'Document symbols' })
map('n', '<leader>S', fzf.lsp_live_workspace_symbols, { desc = 'Workspace symbols' })
map('n', '<leader>d', fzf.diagnostics_workspace, { desc = 'Diagnostics' })
map('n', '<leader>g', fzf.git_status, { desc = 'Git status' })
map('n', '<leader>k', fzf.keymaps, { desc = 'Keymaps' })
map('n', '<leader>?', fzf.helptags, { desc = 'Help tags' })

require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function bmap(lhs, rhs, desc) map('n', lhs, rhs, { buffer = buf, desc = desc }) end
    bmap(']h', function() gs.nav_hunk('next') end, 'Next hunk')
    bmap('[h', function() gs.nav_hunk('prev') end, 'Previous hunk')
    bmap('<leader>hs', gs.stage_hunk, 'Stage hunk')
    bmap('<leader>hr', gs.reset_hunk, 'Reset hunk')
    bmap('<leader>hp', gs.preview_hunk, 'Preview hunk')
    bmap('<leader>hb', gs.blame_line, 'Blame line')
  end,
})

require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    c = { 'clang-format' },
    cpp = { 'clang-format' },
  },
  format_on_save = { lsp_format = 'fallback' },
})


require('mini.ai').setup()
require('mini.surround').setup()
require('mini.pairs').setup()

require('blink.cmp').setup({})
