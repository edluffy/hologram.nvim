local Job = require('hologram.job')
local base64 = require('hologram.base64')
local fs = require('hologram.fs')
local terminal = require('hologram.terminal')

local function keys_to_string(keys)
  local entries = {}
  for k, v in pairs(keys) do
    table.insert(entries, k .. '=' .. v)
  end
  return table.concat(entries, ',')
end


local Image = {}
Image.__index = Image

local SOURCE = {
  FILE = 1,
  RGB  = 2,
  RGBA = 3
}

local next_image_id = 1

-- Instance data:
-- image = {
--   id: number,
--   buffer: number,
--   extmark: number,
--   source: SOURCE,
--   row: number,
--   col: number,
--   path?: string,
--   data?: number[][]
-- }

-- source, row, col
local function create(opts)
    opts = opts or {}

    local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
    local row = opts.row
    local col = opts.col
    if row == nil then row = cur_row end
    if col == nil then col = cur_col end

    local buffer  = vim.api.nvim_get_current_buf()
    local extmark = vim.api.nvim_buf_set_extmark(
      buffer,
      vim.g.hologram_extmark_ns,
      opts.row,
      opts.col,
      {}
    )

    local instance = setmetatable({
        id = next_image_id,
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

    return instance
end

function Image:from_file(path, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.FILE,
    path = path,
  }))
end

function Image:from_rgb(data, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.RGB,
    data = data,
  }))
end

function Image:from_rgba(data, opts)
  return create(vim.tbl_extend('keep', opts or {}, {
    source = SOURCE.RGBA,
    data = data,
  }))
end

function Image:transmit(opts)
    opts = opts or {}
    opts.medium = opts.medium or 'direct'
    local set_case = opts.hide and string.lower or string.upper

    fs.read_file(self.path, vim.schedule_wrap(function(content)
        local data = base64.encode(content)

        if not opts.hide then terminal.move_cursor(self:pos()) end

        -- Split into chunks of max 4096 length
        local chunks = {}
        for i = 1, #data, 4096 do
            local chunk = data:sub(i, i + 4096 - 1):gsub('%s', '')
            if #chunk > 0 then
                table.insert(chunks, chunk)
            end
        end

        local keys = {
            i = self.id,
            t = opts.medium:sub(1, 1),
            f = opts.format or 100,
            v = opts.height or nil,
            s = opts.width or nil,
            p = 1,
            a = set_case('t'),
            q = 2, --supress response
        }

        local parts = {}
        for i, chunk in ipairs(chunks) do
            local is_last = i == #chunks

            if not is_last then
                keys.m = 1
            else
                keys.m = 0
            end

            local part = '\x1b_G' .. keys_to_string(keys) .. ';' .. chunk .. '\x1b\\'
            table.insert(parts, part)
            keys = {}
        end

        terminal.write(parts)

        if not opts.hide then terminal.restore_cursor() end
    end))
end

function Image:adjust(opts)
    opts = opts or {}
    opts.crop = opts.crop or {}
    opts.area = opts.area or {}
    opts.edge = opts.edge or {}
    opts.offset = opts.offset or {}

    local keys = {
        i = self.id,
        z = opts.z_index,
        w = opts.crop[1],
        h = opts.crop[2],
        c = opts.area[1],
        r = opts.area[2],
        x = opts.edge[1],
        y = opts.edge[2],
        X = opts.offset[1],
        Y = opts.offset[2],
        q = 2, -- suppress responses
        p = 1,
    }

    terminal.move_cursor(self:pos())
    terminal.write('\x1b_Ga=p,' .. keys_to_string(keys) .. '\x1b\\')
    terminal.restore_cursor()
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

    if opts.free then
        vim.api.nvim_buf_del_extmark(self.buffer, vim.g.hologram_extmark_ns, self.extmark)
    end
end

function Image:identify()
    if self.source ~= SOURCE.FILE then
        return
    end

    -- Get image width + height
    if vim.fn.executable('identify') == 1 then
        Job:new({
            cmd = 'identify',
            args = {'-format', '%hx%w', self.path},
            on_data = function(data)
                data = {data:match("(.+)x(.+)")}
                self.height = tonumber(data[1])
                self.width  = tonumber(data[2])
            end,
        }):start()
    else
        vim.api.nvim_err_writeln("Unable to run command 'identify'."..
            " Make sure ImageMagick is installed.")
    end
end

function Image:move(row, col)
    vim.api.nvim_buf_set_extmark(self.buffer, vim.g.hologram_extmark_ns, row, col, {
        id = self.extmark
    })
end

function Image:pos()
    return unpack(vim.api.nvim_buf_get_extmark_by_id(
        self.buffer, vim.g.hologram_extmark_ns, self.extmark, {}))
end

return Image
