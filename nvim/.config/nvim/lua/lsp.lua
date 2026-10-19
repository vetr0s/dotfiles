vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
    },
  },
})

-- Same JDT LS install that Doom uses.
vim.lsp.config('jdtls', {
  cmd = { vim.fn.expand('~/.local/share/jdtls/bin/jdtls') },
})

vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = { check = { command = 'clippy' } },
  },
})

vim.lsp.enable({ 'lua_ls', 'tsc', 'clangd', 'jdtls', 'rust_analyzer' })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev) vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf }) end,
})
