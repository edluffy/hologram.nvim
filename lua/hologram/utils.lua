local bit = _G.bit
local ffi = require('ffi')
local Rectangle = require('hologram.rectangle')

local m = {}

function m.keys_to_string(keys)
  local entries = {}
  for k, v in pairs(keys) do
    table.insert(entries, k .. '=' .. v)
  end
  return table.concat(entries, ',')
end

function m.bytes_to_string(data, length, start)
  local bytes = data
  if type(data) == 'table' then
    bytes = vim.tbl_flatten(data)
  end

  if length == nil then
    length = #bytes
  end
  if start == nil then
    start = 1
  end

  local s = {}
  local offset = start - 1
  for i = start, length + offset do
    table.insert(s, string.char(bytes[i]))
  end
  return table.concat(s)
end

function m.cairo_surface_to_bytes(surface)
  -- convert bgra to argb

  local width = surface:width()
  local height = surface:height()

  local length = width * height

  local argb = ffi.cast('uint32_t*', surface:data())
  local rgba = ffi.new('uint32_t[?]', length)

  for line = 0, height - 1 do
    for col = 0, width - 1 do
      local i = line * width + col
      local value = argb[i]

      local alpha = bit.rshift(bit.band(value, 0xff000000), 24)
      local red   = bit.rshift(bit.band(value, 0x00ff0000), 16)
      local green = bit.rshift(bit.band(value, 0x0000ff00),  8)
      local blue  = bit.rshift(bit.band(value, 0x000000ff),  0)

      rgba[i] =
        bit.lshift(red,   24) +
        bit.lshift(green, 16) +
        bit.lshift(blue,   8) +
        bit.lshift(alpha,  0)
    end
  end

  local bytes = ffi.cast('uint8_t*', rgba)

  return bytes, length * 4
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

  -- separator
  width = width - 1

  -- statusline
  -- TODO: check statusline option
  height = height - 1


  return Rectangle.new(x, y, width, height)
end

return m
