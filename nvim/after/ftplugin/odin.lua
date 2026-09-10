-- ~/.config/nvim/after/ftplugin/odin.lua
-- Runs after Neovim's own ftplugin/odin.vim, which sets commentstring and
-- suffixesadd. Indentation, :make and format on save are what it leaves out.
--
-- The Emacs half of this is .emacs.d/configs/rc-odin.el. Both editors call
-- odinfmt, so the two agree on formatting and on where a project starts.

-- Tabs, against the spaces init.lua sets everywhere else: the core library and
-- odinfmt both use them. The width has to match odinfmt.json's tabs_width or a
-- level indents to a tab plus padding spaces rather than to one tab.
vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4

-- odin reports a diagnostic as path(line:column) Error:, then echoes the
-- offending line and a caret line under it. %-G discards those two.
vim.bo.errorformat = table.concat({
  [[%f(%l:%c) Syntax %trror: %m]],
  [[%f(%l:%c) %trror: %m]],
  [[%f(%l:%c) %tarning: %m]],
  [[%f(%l:%c) %m]],
  [[%-G%.%#]],
}, ",")

-- A package in Odin is a directory holding .odin files, so a root that holds
-- only subdirectories is not one. The buffer's own directory always is, which
-- is what makes the fallback safe. Mirrors rc-odin--package.
local function holds_odin(dir)
  if not dir or not vim.uv.fs_stat(dir) then
    return false
  end
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:sub(-5) == ".odin" then
      return true
    end
  end
  return false
end

-- A Makefile at the root wins, since it already carries the flags and the
-- -out: path a bare odin build would have to invent.
local buffer_dir = vim.fn.expand("%:p:h")
local root = vim.fs.root(0, { { ".git", "ols.json", "odinfmt.json" } }) or buffer_dir

if vim.uv.fs_stat(root .. "/Makefile") then
  vim.bo.makeprg = "make -C " .. vim.fn.shellescape(root)
else
  local src = root .. "/src"
  local package = (holds_odin(src) and src)
    or (holds_odin(root) and root)
    or buffer_dir
  -- cd first: odin writes the binary into the process working directory, so
  -- without this :make drops it wherever Neovim happens to have been started.
  vim.bo.makeprg = "cd " .. vim.fn.shellescape(root) .. " && odin build "
    .. vim.fn.shellescape(package) .. " -vet -strict-style -debug"
end

-- Format on save, which is what apheleia does for Odin in Emacs. odinfmt reads
-- the project's odinfmt.json, so it runs from the buffer's directory the way
-- apheleia runs it. A machine without odinfmt saves unformatted.
local group = vim.api.nvim_create_augroup("rc_odin", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  buffer = 0,
  desc = "Format Odin through odinfmt",
  callback = function(ev)
    if vim.fn.executable("odinfmt") == 0 then
      return
    end
    local source = table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n")
    local result = vim.system({ "odinfmt", "-stdin" }, {
      stdin = source .. "\n",
      cwd = vim.fn.expand("%:p:h"),
    }):wait(2000)
    -- A syntax error makes odinfmt exit non-zero. Keeping the buffer as typed
    -- beats replacing it with a diagnostic.
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
      local detail = vim.trim(result.stderr or "")
      if detail == "" then
        detail = "exit code " .. tostring(result.code)
      end
      vim.notify("odinfmt failed: " .. detail, vim.log.levels.ERROR)
      return
    end
    local formatted = vim.split(result.stdout:gsub("\n$", ""), "\n", { plain = true })
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, formatted)
    vim.fn.winrestview(view)
  end,
})

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
  .. " | setlocal expandtab< tabstop< shiftwidth< softtabstop<"
  .. " errorformat< makeprg<"
  .. " | lua vim.api.nvim_clear_autocmds({ group = 'rc_odin', buffer = 0 })"
