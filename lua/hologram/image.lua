--
-- NOTE: This file contains the implementation for working with the kitty
-- graphics protocol.
--
-- Reference: https://sw.kovidgoyal.net/kitty/graphics-protocol/
--

local vim = _G.vim
local ffi = require('ffi')
local fs = require('hologram.fs')
local state = require('hologram.state')
local utils = require('hologram.utils')
local cairo = require('hologram.cairo.cairo')
local base64 = require('hologram.base64')
local terminal = require('hologram.terminal')
local Rectangle = require('hologram.rectangle')
local defaults = utils.defaults
local keys_to_string = utils.keys_to_string
local bytes_to_string = utils.bytes_to_string
local winpos_to_screenpos = utils.winpos_to_screenpos
local cairo_surface_to_png_bytes = utils.cairo_surface_to_png_bytes

local Image = {
  instances = {},
}
Image.__index = Image

local SOURCE = {
  FILE = 1,
  RGB  = 2,
  RGBA = 3,
  CAIRO = 4,
}

local TRANSMISSION = {
  DIRECT    = 'd',
  FILE      = 'f',
  TEMPORARY = 't',
  SHARED    = 's',
}

local FORMAT = {
  RGB = 24,
  RGBA = 32,
  PNG = 100,
}

local next_image_id = 1

-- Instance data:
-- image = {
--   id: number,
--   window?: number,
--   buffer: number,
--   extmark?: number,
--   source: SOURCE,
--   row: number,
--   col: number,
--   width: number,
--   height: number,
--   path?: string,
--   data?: number[][]
-- }

-- Constructors

-- source, row, col
local function create(opts)
  opts = opts or {}

  local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  local row = opts.row
  local col = opts.col
  if row == nil then row = cur_row end
  if col == nil then col = cur_col end

  local window  = opts.window or nil
  local buffer  = opts.buffer or nil
  local extmark = nil
  if buffer then
    extmark = vim.api.nvim_buf_set_extmark(
      buffer,
      vim.g.hologram_extmark_ns,
      opts.row,
      opts.col,
      {}
    )
  end

  local instance = setmetatable({
    id = next_image_id,
    window = window,
    buffer = buffer,
    extmark = extmark,
    source = opts.source,
    row = row,
    col = col,
    path = opts.path,
    data = opts.data,
  }, Image)
  next_image_id = next_image_id + 1

  instance:identify()

  table.insert(Image.instances, instance)

  return instance
end

function Image.new(data, opts)
  if opts.buffer == 0 then
    opts.buffer = vim.api.nvim_get_current_buf()
  end

  if opts.buffer ~= nil then
    opts.window = vim.fn.bufwinid(opts.buffer)
  end

  local image = nil
  if type(data) == 'string' then
    image = Image.from_file(data, opts)
  elseif type(data) == 'table' then
    if #(data[1][1]) == 3 then
      image = Image.from_rgb(data, opts)
    elseif #(data[1][1]) == 4 then
      image = Image.from_rgba(data, opts)
    else
      assert(false, 'Unsupported image size')
    end
  elseif type(data) == 'cdata' then
    image = Image.from_surface(data, opts)
  else
    assert(false, 'Unsupported image format')
  end
  return image
end

function Image.from_file(path, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.FILE,
    path = path,
  }))
end

function Image.from_rgb(data, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.RGB,
    data = data,
  }))
end

function Image.from_rgba(data, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.RGBA,
    data = data,
  }))
end

function Image.from_surface(data, opts)
  assert(
    data:bitmap_format() == 'bgra8',
    'Unsupported format: ' .. data:bitmap_format()
  )
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.CAIRO,
    data = data,
  }))
end


-- Instance methods

function Image:transmit(opts)
  opts = defaults(opts, {})
  opts.display = defaults(opts.display, true)

  local action = 't'

  if self.source == SOURCE.FILE then

    -- NOTE using the TRANSMISSION.FILE mode should be faster but I can't
    -- get it to work at the moment. It should work with something like this:
    --
    -- local params = {
    --   t = TRANSMISSION.FILE,
    --   f = FORMAT.PNG,
    --   a = action,
    --   i = self.id,
    --   p = 1, -- placement id
    -- }

    -- vim.schedule_wrap(function ()
    --   self:transmit_data(opts, params, self.path)
    -- end)

    fs.read_file(self.path, vim.schedule_wrap(function(content)
      local params = {
        f = FORMAT.PNG,
        v = self.height or nil,
        s = self.width or nil,
        a = action,
        i = self.id,
        p = 1, -- placement id
      }

      self:transmit_data(opts, params, content)
    end))

  elseif self.source == SOURCE.RGB then
    local params = {
      f = FORMAT.RGB,
      v = self.height,
      s = self.width,
      a = action,
      i = self.id,
      p = 1, -- placement id
    }

    vim.defer_fn(function ()
      self:transmit_data(opts, params, bytes_to_string(self.data))
    end, 0)

  elseif self.source == SOURCE.RGBA then
    local params = {
      f = FORMAT.RGBA,
      v = self.height,
      s = self.width,
      a = action,
      i = self.id,
      p = 1, -- placement id
    }

    vim.defer_fn(function ()
      self:transmit_data(opts, params, bytes_to_string(self.data))
    end, 0)

  elseif self.source == SOURCE.CAIRO then
    local params = {
      f = FORMAT.PNG,
      v = self.height,
      s = self.width,
      a = action,
      i = self.id,
      p = 1, -- placement id
    }

    vim.defer_fn(function ()
      self:transmit_data(opts, params, cairo_surface_to_png_bytes(self.data))
    end, 0)

  else
    assert(false, 'Invalid source image type: ' .. tostring(self.source))
  end
end

function Image:transmit_data(opts, params, content)

  -- Encode in base64 format
  local data =
    type(content) == 'string'
      and base64.encode(content)
       or base64.encode_bytes(content)

  -- Split into chunks of max 4096 length
  local chunks = {}
  for i = 1, #data, 4096 do
    local chunk = data:sub(i, i + 4096 - 1):gsub('%s', '')
    if #chunk > 0 then
      table.insert(chunks, chunk)
    end
  end

  params.q = 2 -- suppress response

  local parts = {}
  for i, chunk in ipairs(chunks) do
    local is_last = i == #chunks

    if not is_last then
      params.m = 1
    else
      params.m = 0
    end

    local part = '\x1b_G' .. keys_to_string(params) .. ';' .. chunk .. '\x1b\\'
    table.insert(parts, part)
    params = {} -- params only need to be present on the first part
  end

  terminal.write(parts)

  if opts.display then
    self:display(opts)
  end
end

function Image:display(opts)
  opts = opts or {}

  local crop_area = opts.screen or state.dimensions.screen
  if self.window ~= nil then
    crop_area =
      utils.get_window_rectangle(self.window)
        :to_pixels(state.dimensions.cell_pixels)
  end

  local screen_position
  if self.window then
    local position = self:pos()
    local row = position[1]
    local col = position[2]

    screen_position = winpos_to_screenpos(self.window, row, col)
  else
    screen_position = { row = self.row + 1, col = self.col + 1 }
  end

  local cell_pixels   = state.dimensions.cell_pixels

  local position_x = (screen_position.col - 1) * cell_pixels.width
  local position_y = (screen_position.row - 1) * cell_pixels.height

  local region = Rectangle.new(position_x, position_y, self.width, self.height)
  local visible_region = region:crop_to(crop_area)
  local visible_region_cells = visible_region:to_cells(state.dimensions.cell_pixels)
  local offset = region:offset_to(visible_region)

  if visible_region.width == 0 or visible_region.height == 0 then
    self:delete({ free = false })
    return
  end

  local keys = {
    a = 'p',
    z = opts.z_index,

    w = visible_region.width,
    h = visible_region.height,
    x = offset.x,
    y = offset.y,

    i = self.id,
    p = 1,
    q = 2, -- suppress responses
  }

  terminal.move_cursor_absolute(
    visible_region_cells.x,
    visible_region_cells.y
  )
  terminal.write(('\x1b_G' .. keys_to_string(keys) .. '\x1b\\'))
  terminal.restore_cursor()
end

function Image:adjust(opts)
  self:display(opts)
end

function Image:delete(opts)
  opts = opts or {}
  opts.free = opts.free or false
  opts.all = opts.all or false

  local set_case = opts.free and string.upper or string.lower

  local keys_set = {}

  keys_set[#keys_set+1] = {
    i = self.id,
  }

  if opts.all then
    keys_set[#keys_set+1] = {
      d = set_case('a'),
    }
  end
  if opts.z_index then
    keys_set[#keys_set+1] = {
      d = set_case('z'),
      z = opts.z_index,
    }
  end
  if opts.col then
    keys_set[#keys_set+1] = {
      d = set_case('x'),
      x = opts.col,
    }
  end
  if opts.row then
    keys_set[#keys_set+1] = {
      d = set_case('y'),
      y = opts.row,
    }
  end
  if opts.cell then
    keys_set[#keys_set+1] = {
      d = set_case('p'),
      x = opts.cell[1],
      y = opts.cell[2],
    }
  end

  for _, keys in ipairs(keys_set) do
    terminal.write('\x1b_Ga=d,' .. keys_to_string(keys) .. '\x1b\\')
  end

  if opts.free and self.extmark then
    vim.api.nvim_buf_del_extmark(self.buffer, vim.g.hologram_extmark_ns, self.extmark)
  end
end

function Image:identify()
  if self.source == SOURCE.RGB or self.source == SOURCE.RGBA then
    local lines = self.data
    self.height = #(lines)
    self.width  = #(lines[1])
    return
  end

  if self.source == SOURCE.CAIRO then
    self.width  = self.data:width()
    self.height = self.data:height()
    return
  end

  if self.source == SOURCE.FILE then
    -- Get image width + height
    if vim.fn.executable('identify') ~= 1 then
      vim.api.nvim_err_writeln(
        'Unable to run command "identify".' ..
        ' Make sure ImageMagick is installed.')
      return
    end

    local output = vim.fn.system('identify -format %hx%w ' .. self.path)
    local data = {output:match("(.+)x(.+)")}
    self.height = tonumber(data[1])
    self.width  = tonumber(data[2])
    return
  end
end

function Image:move(row, col)
  -- TODO: handle absolute images
  if not self.extmark then
    return
  end
  vim.api.nvim_buf_set_extmark(self.buffer, vim.g.hologram_extmark_ns, row, col, {
    id = self.extmark
  })
end

function Image:pos()
  -- TODO: handle absolute images
  if not self.extmark then
    return
  end
  return vim.api.nvim_buf_get_extmark_by_id(
    self.buffer, vim.g.hologram_extmark_ns, self.extmark, {})
end

return Image
