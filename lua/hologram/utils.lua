local vim = _G.vim
local bit = _G.bit
local ffi = require('ffi')
local cairo = require('hologram.cairo.cairo')
local Rectangle = require('hologram.rectangle')

local m = {}

function m.defaults(v, default_value)
  return type(v) == 'nil' and default_value or v
end

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

-- Unused at the moment
function m.cairo_surface_to_bytes(surface)
  -- convert bgra to argb
  -- PERF: Using ffi primitives could be faster but was causing segfaults

  local width = surface:width()
  local height = surface:height()

  local length = width * height

  local argb = ffi.cast('uint32_t*', surface:data())
  local rgba = {} -- ffi.new('uint32_t[?]', length)

  for line = 0, height - 1 do
    for col = 0, width - 1 do
      local i = line * width + col
      local value = argb[i]

      local alpha = bit.rshift(bit.band(value, 0xff000000), 24)
      local red   = bit.rshift(bit.band(value, 0x00ff0000), 16)
      local green = bit.rshift(bit.band(value, 0x0000ff00),  8)
      local blue  = bit.rshift(bit.band(value, 0x000000ff),  0)

      -- rgba[i] =
      --   bit.lshift(red,   24) +
      --   bit.lshift(green, 16) +
      --   bit.lshift(blue,   8) +
      --   bit.lshift(alpha,  0)

      table.insert(rgba, red)
      table.insert(rgba, green)
      table.insert(rgba, blue)
      table.insert(rgba, alpha)
    end
  end

  -- local bytes = ffi.cast('uint8_t*', rgba)
  -- return bytes, length * 4

  return rgba, length * 4
end

function m.cairo_surface_to_png_bytes(surface)
  local bytes = {}

  surface:save_png(function(_, data, length)
    local byte_data = ffi.cast('uint8_t*', data)

    for i = 0, length - 1 do
      table.insert(bytes, byte_data[i])
    end

    return cairo.enums.CAIRO_STATUS_.success
  end, nil)

  return bytes
end

-- 1-indexed
function m.winpos_to_screenpos(window, row, col)
  local lnum = row + 1
  local position = vim.fn.screenpos(window, lnum, col)

  if position.col ~= 0 then
    return position
  end

  local info = vim.fn.getwininfo(window)[1]
  local result = {
    row = row + info.winrow - (info.topline - 1),
    col = col + info.wincol + info.textoff,
  }

  return result
end

function m.get_window_rectangle(window_id)
  local row, col = unpack(vim.fn.win_screenpos(window_id))
  local x = col - 1
  local y = row - 1
  local width  = vim.fn.winwidth(window_id)  + 1
  local height = vim.fn.winheight(window_id) + 1

  -- separator
  width = width - 1

  -- statusline
  -- TODO: check statusline option
  height = height - 1


  return Rectangle.new(x, y, width, height)
end

return m
