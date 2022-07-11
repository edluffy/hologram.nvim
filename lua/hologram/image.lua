local Job = require('hologram.job')
local base64 = require('hologram.base64')
local terminal = require('hologram.terminal')

local image = {}

local Image = {}
Image.__index = Image

-- source, row, col
function Image:new(opts)
    opts = opts or {}

    local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
    opts.row = opts.row or cur_row
    opts.col = opts.col or cur_col

    local buf = vim.api.nvim_get_current_buf()
    local ext = vim.api.nvim_buf_set_extmark(buf, vim.g.hologram_extmark_ns, opts.row, opts.col, {})

    local obj = setmetatable({
        id = buf*100 + ext,
        source = opts.source
    }, self)

    obj:identify()

    return obj
end

function Image:transmit(opts)
    opts = opts or {}
    opts.medium = opts.medium or 'f'
    local set_case = opts.hide and string.lower or string.upper

    local keys = {
        image_id = self.id,
        transmission_type = opts.medium:sub(1, 1),
        format = opts.format or 100,
        placement_id = 1,
        action = set_case('t'),
        quiet = 2, --supress response
    }

    if not opts.hide then terminal.move_cursor(self:pos()) end
    terminal.send_graphics_command(keys, self.source)
    if not opts.hide then terminal.restore_cursor() end

end

function Image:adjust(opts)
    opts = opts or {}
    opts = vim.tbl_extend('keep', opts, {
        z_index = 0,
        crop = {},
        area = {},
        edge = {},
        offset = {},
        placement_id = 1
    })

    local keys = {
        action = 'p',
        image_id = self.id,
        z_index = opts.z_index,
        width = opts.crop[1],
        height = opts.crop[2],
        cols = opts.area[1],
        rows = opts.area[2],
        x_offset = opts.edge[1],
        y_offset = opts.edge[2],
        cell_x_offset = opts.offset[1],
        cell_y_offset = opts.offset[2],
        placement_id = opts.placement_id,
        cursor_movement = 1,
        quiet = 2,
    }

    terminal.move_cursor(self:pos())
    terminal.send_graphics_command(keys)
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
        terminal.send_graphics_command(keys)
    end

    if opts.free then
        vim.api.nvim_buf_del_extmark(self:buf(), vim.g.hologram_extmark_ns, self:ext())
    end
end

function Image:identify()
    -- Get image width + height
    if vim.fn.executable('identify') == 1 then
        Job:new({
            cmd = 'identify',
            args = {'-format', '%hx%w', self.source},
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
    vim.api.nvim_buf_set_extmark(self:buf(), vim.g.hologram_extmark_ns, row, col, {
        id = self:ext()
    })
end

function Image:pos()
    return unpack(vim.api.nvim_buf_get_extmark_by_id(self:buf(), vim.g.hologram_extmark_ns, self:ext(), {}))
end

function Image:buf()
    return math.floor(self.id/100)
end

function Image:ext()
    return self.id % 100
end

return Image
