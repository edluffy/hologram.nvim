local Rectangle = require('hologram.rectangle')

local m = {}

function m.keys_to_string(keys)
  local entries = {}
  for k, v in pairs(keys) do
    table.insert(entries, k .. '=' .. v)
  end
  return table.concat(entries, ',')
end

function m.bytes_to_string(data)
  local bytes = vim.tbl_flatten(data)
  local s = {}
  for i = 1, #bytes do
    s[i] = string.char(bytes[i])
  end
  return table.concat(s)
end

function m.winpos_to_screenpos(window, row, col)
  local lnum = row + 1
  local position = vim.fn.screenpos(window, lnum, col)
  return position
end

function m.get_window_rectangle(window_id)
  local y, x = unpack(vim.fn.win_screenpos(window_id))
  local width  = vim.fn.winwidth(window_id)
  local height = vim.fn.winheight(window_id)

  -- statusline
  -- TODO: check statusline option
  height = height - 1

  return Rectangle.new(x, y, width, height)
end

return m
