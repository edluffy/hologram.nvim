local terminal = require('hologram.terminal')
local fs = require('hologram.fs')
local utils = require('hologram.utils')
local state = require('hologram.state')

local Image = {
    instances = {},
    next_id = 1,
}
Image.__index = Image

function Image:new(source, keys)
    keys = keys or {}
    keys = vim.tbl_extend('keep', keys, {
        format = 100,
        transmission_type = 'f',
        data_width = nil,
        data_height = nil,
        data_size = nil,
        data_offset = nil,
        image_number = nil,
        compressed = nil,
        image_id = nil,
        placement_id = 1,
    })

    if keys.image_id == nil then
        keys.image_id = Image.next_id
        Image.next_id = Image.next_id + 1
    end

    assert(type(source) == 'string', 'Image source is not a valid string')
    if keys.data_width == nil and keys.data_height == nil then
        if source:sub(-4) == '.png' then
            keys.data_width, keys.data_height = fs.get_dims_PNG(source)
        end
    end
    local cols = math.ceil(keys.data_width/state.cell_size.x)
    local rows = math.ceil(keys.data_height/state.cell_size.y)

    keys.action = 't'
    keys.quiet = 2

    terminal.send_graphics_command(keys, source)

    Image.instances[keys.image_id] = setmetatable({
        source = source,
        transmit_keys = keys,
        cols = cols,
        rows = rows,
        vpad = nil,
    }, self)

    return Image.instances[keys.image_id]
end

function Image:display(row, col, buf, keys)
    keys = keys or {}
    keys = vim.tbl_extend('keep', keys, {
        x_offset = nil,
        y_offset = nil,
        width = nil,
        height = nil,
        cell_x = nil,
        cell_y = nil,
        cols = nil,
        rows = nil,
        z_index = 0,
        placement_id = 1,
    })

    keys.action = 'p'
    keys.image_id = self.transmit_keys.image_id
    keys.cursor_movement = 1
    keys.quiet = 2

    -- fit inside buffer
    if vim.api.nvim_buf_is_valid(buf) then
        local win = vim.fn.bufwinid(buf)
        local cs = state.cell_size
        local info = vim.fn.getwininfo(win)[1]

        local rows = self.rows
        local cols = self.cols
        local height = self.transmit_keys.data_height
        local y_offset = 0

        -- resize
        local winwidth = (info.width-info.textoff)
        if cols > winwidth then
            rows = winwidth * (rows/cols)
            cols = winwidth
        end
        local row_factor = self.rows / rows

        -- set filler lines
        self:set_vpad(buf, row, info.width, math.ceil(rows))

        -- check if visible
        if row < info.topline-1 or row > info.botline then
            return false
        end

        -- image is cut off top
        if row == info.topline-1 then
            local topfill = vim.fn.winsaveview().topfill
            local cutoff_rows = math.max(0, rows-topfill)
            y_offset = cutoff_rows * row_factor * cs.y
            rows = topfill
        end

        -- image is cut off bottom
        if row == info.botline then
            local screen_row = utils.buf_screenpos(row, 0, win, buf)
            local screen_winbot = info.winrow+info.height
            local visible_rows = screen_winbot-screen_row
            if visible_rows > 0 then
                rows = visible_rows
                height = visible_rows * row_factor * cs.y
            else
                rows = 0
                height = 1
            end
        end

        rows = math.ceil(rows)
        cols = math.ceil(cols)
        y_offset = math.ceil(y_offset)
        height = math.ceil(height)

        if rows ~= self.rows then
            keys.rows = rows
        end
        if cols ~= self.cols then
            keys.cols = cols
        end
        if height ~= self.transmit_keys.data_height then
            keys.height = height
        end
        if y_offset ~= 0 then
            keys.y_offset = y_offset
        end

        row, col = utils.buf_screenpos(row, col, win, buf)
    end

    terminal.move_cursor(row, col)
    terminal.send_graphics_command(keys)
    terminal.restore_cursor()

    return true
end

function Image:delete(buf, opts)
    opts = opts or {}
    opts = vim.tbl_extend('keep', opts, {
        free = false,
    })

    local set_case = opts.free and string.upper or string.lower

    local keys = {
        action = 'd',
        delete_action = set_case('i'),
        image_id = self.transmit_keys.image_id,
    }

    terminal.send_graphics_command(keys)
    if opts.free then
        self:remove_vpad(buf)
    end
end

function Image:set_vpad(buf, row, cols, rows)
    if self.vpad ~= nil and 
        self.vpad.row == row and 
        self.vpad.cols == cols and 
        self.vpad.rows == rows then
        return
    end

    local text = string.rep(' ', cols)
    local filler = {}
    for i=0,rows-1 do
        filler[#filler+1] = {{text, ''}}
    end

    vim.api.nvim_buf_set_extmark(buf, vim.g.hologram_extmark_ns, row-1, 0, {
        id = self.transmit_keys.image_id,
        virt_lines = filler,
        --virt_lines_leftcol = true,
    })

    self.vpad = {row=row, cols=cols, rows=rows}
end

function Image:remove_vpad(buf)
    if self.vpad ~= nil then
        vim.api.nvim_buf_del_extmark(buf, vim.g.hologram_extmark_ns, self.transmit_keys.image_id)
        self.vpad = nil
    end
end

return Image
