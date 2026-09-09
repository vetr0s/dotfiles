local root = vim.fn.tempname()
local ok, err = xpcall(function()
  local nested = root .. "/nested/package"
  vim.fn.mkdir(root .. "/.git", "p")
  vim.fn.mkdir(nested, "p")
  vim.fn.writefile({ "{}" }, nested .. "/odinfmt.json")
  vim.fn.writefile({ "all:" }, nested .. "/Makefile")

  local path = nested .. "/probe.odin"
  vim.fn.writefile({ "package probe" }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = "odin"

  local real_nested = assert(vim.uv.fs_realpath(nested))
  assert(
    vim.bo.makeprg == "make -C " .. real_nested,
    "Odin did not use the nearest root marker: " .. vim.bo.makeprg
  )
  if vim.fn.executable("ols") == 1 then
    local attached = vim.wait(3000, function()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "ols" })) do
        if client.root_dir == real_nested then
          return true
        end
      end
      return false
    end)
    assert(attached, "OLS did not attach at the nearest root marker")
  end

  local before = vim.api.nvim_get_autocmds({
    group = "rc_odin",
    buffer = 0,
    event = "BufWritePre",
  })
  assert(#before == 1, "Odin formatter autocmd was not created")

  vim.bo.filetype = "lua"
  local after = vim.api.nvim_get_autocmds({
    group = "rc_odin",
    buffer = 0,
    event = "BufWritePre",
  })
  assert(#after == 0, "Odin formatter survived the filetype change")

  local markers = dofile(vim.fn.getcwd() .. "/nvim/lsp/ols.lua").root_markers
  assert(type(markers[1]) == "table", "OLS root markers do not have equal priority")

end, debug.traceback)

vim.fn.delete(root, "rf")

if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd.cquit(1)
end

vim.cmd.quitall({ bang = true })
