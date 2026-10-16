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

vim.lsp.enable({ 'lua_ls', 'tsc', 'clangd', 'jdtls' })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev) vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf }) end,
})
