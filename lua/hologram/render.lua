local utils = require('hologram.utils')

local render = {}

local stdout = vim.loop.new_pipe(false)
stdout:open(1)

local Renderer = {}
Renderer.__index = Renderer

function Renderer:new(opts)
    opts = opts or {}
    -- asserts go here

    local obj = setmetatable({
        protocol = opts.protocol or render.detect(),
        buf = opts.buf or vim.api.nvim_get_current_buf(),
        items = {},
        -- opts go here
    }, self)

    return obj
end

-- Only redraws items in current view
--function Renderer:redraw()
--    --vim.cmd("mode")
--    --stdout:write('\x1b[2J')
--
--    local cl, cc = unpack(vim.api.nvim_win_get_cursor(0))
--    local visible = vim.api.nvim_buf_get_extmarks(
--        self.buf, 
--        vim.g.hologram_extmark_ns,
--        {vim.fn.line('w0'),  0},
--        {vim.fn.line('w$'), -1},
--    {})
--
--    local async
--    async = vim.loop.new_async(function()
--        for _, v in ipairs(visible) do
--            local ext, l, c = unpack(v)
--            local raw = render.read_source(self._items[ext].source)
--            render.kitty_write_clear({ext}, false)
--
--            -- TODO: rename ext to id
--            render.cursor_write_move(l-cl, c-cc)
--            if self.protocol == 'kitty' then
--                render.kitty_write_chunked(raw, {a='T', f='100', i=ext, q='1'})
--            elseif self.protocol == 'iterm2' then
--                print('Iterm2 support coming soon!')
--            else
--                printf("Renderer cannot write - terminal not compatible")
--            end
--            render.cursor_write_restore()
--        end
--        async:close()
--    end)
--    async:send()
--end
--
--function Renderer:add_item(source, l, c)
--    ext = vim.api.nvim_buf_set_extmark(self.buf, vim.g.hologram_extmark_ns, l, c, {
--        virt_text = {{' Preview Image', 'HologramVirtualText'}}
--    })
--    self._items[ext] = {
--        source = source, 
--        transform = nil,
--    }
--end

function Renderer:set_transform(ext, tr)
    --self._items[ext].transform = tr
end

function Renderer:get_transform(ext)
    --return self._items[ext].transform
end


--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--


--[[ 
        medium  Transmission medium used. Accepted values are
                'direct'(default), 'file', 'temp_file' or 'shared'.

        format  Format in which image data is sent. TODO:

        height 

        width  

        col

        row
--]]
function Renderer:display(id, source, opts)
    if type(opts) ~= 'table' then opts = {} end
    local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- Defaults
    opts.medium = opts.medium or 'direct'
    opts.format = opts.format or 100
    opts.row = opts.row or cur_row
    opts.col = opts.col or cur_col

    local keys = {
        i = id,
        t = opts.medium:sub(1, 1),
        f = opts.format,
        v = opts.height,
        s = opts.width,
    }


    local as
    as = vim.loop.new_async(function()
        local raw, chunk, cmd
        raw = render.read_source(source)

        render.cursor_write_move(opts.row-cur_row, opts.col-cur_col)

        local first = true
        while #raw > 0 do
            chunk = raw:sub(0, 4096)
            raw   = raw:sub(4097, -1)

            keys.m = (#raw > 0) and 1 or 0
            keys.q = 1 -- suppress responses

            cmd = '\x1b_Ga=T,' .. render.keys_to_str(keys) .. ';' .. chunk .. '\x1b\\'
            stdout:write(cmd)

            -- Not sure why this works, but it does
            if first then 
                stdout:write(cmd)
                first = false 
            end

            keys = {}
        end

        render.cursor_write_restore()

        as:close()
    end)
    as:send()

    return id
end

--[[ Every transmitted image can be displayed an arbitrary number of times
     on the screen in different locations. Keys for adjustments:

        z_index  Vertical stacking order of the image 0 by default.
                 Negative z_index will draw below text.

        crop     Cropped region of the image to display in pixels
                 • height: 0 (all)
                 •  width: 0 (all)

        area     Specifies terminal area to display image over,
                 will stretch/squash if necessary
                 • cols: 0 (auto)
                 • rows: 0 (auto)

        edge     TODO:

        offset   Position within first cell at which to begin
                 displaying image in pixels. Must be smaller
                 than size of cell.
                 • x: 0 (auto)
                 • y: 0 (auto)
]]--

function Renderer:adjust(id, opts)
    if type(opts) ~= 'table' then opts = {} end
    opts = vim.tbl_deep_extend('keep', opts, {
        z_index =  0,
        crop    = {0, 0},
        area    = {0, 0},
        edge    = {0, 0},
        offset  = {0, 0},
    })

    local code = '\x1b_Ga=p'
        .. ',i=' .. id
        .. ',z=' .. opts.z_index
        .. ',w=' .. opts.crop[1]
        .. ',h=' .. opts.crop[2]
        .. ',c=' .. opts.area[1]
        .. ',r=' .. opts.area[2]
        .. ',x=' .. opts.edge[1]
        .. ',y=' .. opts.edge[2]
        .. ',X=' .. opts.offset[1]
        .. ',Y=' .. opts.offset[2]
        .. '\x1b\\'
end

--[[    Delete images by either specifying an image 'id' and/or a set of 'opts'.

        free       When deleting image, free stored image data also.
                   Default is false

        all        Clear all images

        z_index    Delete all images that have the specified z-index.

        col  Delete all images that intersect the specified column.

        row  Delete all images that intersect the specified row.

        cell  Delete all images that intersect the specified cell {col, row}
]]--

function Renderer:delete(id, opts)
    if type(opts) ~= 'table' then opts = {} end

    -- Defaults
    opts.free = opts.free or false
    opts.all = opts.all or false

    local set_case = opts.free and string.upper or string.lower

    local keys_set = {}

    if opts.id then
        keys_set[#keys_set+1] = {
            d = set_case('a'),
            i = id,
        }
    end
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
        stdout:write('\x1b_Ga=d,' .. render.keys_to_str(keys) .. '\x1b\\')
    end
end

function render.read_source(source)
    -- TODO: if source is url, create tempfile
    local file = io.open(source, 'r')
    local raw = file:read('*all')
    io.close(file)
    raw = utils.base64_encode(raw)
    return raw
end

function render.detect()
    return 'kitty'
end

function render.cursor_write_move(dr, dc)
    -- Find direction to move in
    local key1, key2

    if dr < 0 then
        key1 = 'A'  -- up
    else 
        key1 = 'B'  -- down
    end

    if dc < 0 then
        key2 = 'D' -- right
    else
        key2 = 'C' -- left
    end

    stdout:write('\x1b[s') -- save position
    stdout:write('\x1b[' .. math.abs(dr) .. key1)
    stdout:write('\x1b[' .. math.abs(dc) .. key2)
end

function render.cursor_write_restore()
    stdout:write('\x1b[u')
end

function render.keys_to_str(keys)
    local str = ''
    for k, v in pairs(keys) do
        str = str..k..'='..v..','
    end
    return str:sub(0, -2) -- chop trailing comma
end

render._Renderer = Renderer

return render
