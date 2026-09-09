-- ~/.config/nvim/lsp/ols.lua
-- ols, the Odin language server. It is built from the same checkout as
-- odinfmt by util/scripts/install-ols.sh, and init.lua only enables it when
-- the binary is on PATH.
--
-- ols reads ols.json at the workspace root for collections and checker flags.
-- Without one it still resolves the core library and the current package, so
-- the marker list falls back to the same roots ftplugin/odin.lua builds from.

return {
  cmd = { "ols" },
  filetypes = { "odin" },
  root_markers = { "ols.json", "odinfmt.json", ".git" },
}
