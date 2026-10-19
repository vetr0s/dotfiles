-- ~/.config/nvim/lua/align.lua
-- Align a range of lines on the first match of a Vim regex.
--
-- Usage: visually select lines, then  :Align =
--        (or :'<,'>Align [-+*/]\?=   to keep +=, -= etc. together)

local M = {}

function M.align(pattern, first, last)
  local re = vim.regex(pattern)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)

  local splits = {}
  local max_width = 0

  -- Pass 1: split each line at the match, measure the left side
  for i, line in ipairs(lines) do
    local start = re:match_str(line) -- 0-based byte offset of match, or nil
    if start then
      local left = line:sub(1, start):gsub('%s+$', '') -- drop old padding
      local right = line:sub(start + 1)
      splits[i] = { left, right }
      max_width = math.max(max_width, vim.fn.strdisplaywidth(left))
    end
  end

  -- Pass 2: pad every left side to the same width and rejoin
  for i, parts in pairs(splits) do
    local pad = max_width - vim.fn.strdisplaywidth(parts[1])
    lines[i] = parts[1] .. string.rep(' ', pad + 1) .. parts[2]
  end

  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

vim.api.nvim_create_user_command(
  'Align',
  function(opts) M.align(opts.args, opts.line1, opts.line2) end,
  { nargs = 1, range = true, desc = 'Align lines on a regex' }
)

-- In visual mode, ':' auto-inserts '<,'> so this becomes :'<,'>Align
vim.keymap.set('x', '<leader>a', ':Align ', { desc = 'Align selection on regex' })

return M
