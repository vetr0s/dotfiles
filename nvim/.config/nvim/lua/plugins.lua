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
  gh('stevearc/oil.nvim'),
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
map('n', '<leader>f', fzf.files)
map('n', '<leader>/', fzf.live_grep)
map('n', '<leader>b', fzf.buffers)
map('n', '<leader>s', fzf.lsp_document_symbols)

require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function bmap(lhs, rhs) map('n', lhs, rhs, { buffer = buf }) end
    bmap(']h', function() gs.nav_hunk('next') end)
    bmap('[h', function() gs.nav_hunk('prev') end)
    bmap('<leader>hs', gs.stage_hunk)
    bmap('<leader>hr', gs.reset_hunk)
    bmap('<leader>hp', gs.preview_hunk)
    bmap('<leader>hb', gs.blame_line)
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

require('oil').setup({})
map('n', '-', '<cmd>Oil<CR>')

require('mini.ai').setup()
require('mini.surround').setup()
require('mini.pairs').setup()

require('blink.cmp').setup({})
