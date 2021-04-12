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
        _items = opts.items or {},
        -- opts go here
    }, self)
    return obj
end

-- Only redraws items in current view
function Renderer:redraw()
    --vim.cmd("mode")
    --stdout:write('\x1b[2J')

    local cl, cc = unpack(vim.api.nvim_win_get_cursor(0))
    local visible = vim.api.nvim_buf_get_extmarks(
        self.buf, 
        vim.g.hologram_extmark_ns,
        {vim.fn.line('w0'),  0},
        {vim.fn.line('w$'), -1},
    {})

    local async
    async = vim.loop.new_async(function()
        for _, v in ipairs(visible) do
            local ext, l, c = unpack(v)
            local raw = render.read_source(self._items[ext].source)
            render.kitty_write_clear({ext}, false)

            -- TODO: rename ext to id
            render.cursor_write_move(l-cl, c-cc)
            if self.protocol == 'kitty' then
                render.kitty_write_chunked(raw, {a='T', f='100', i=ext, q='1'})
            elseif self.protocol == 'iterm2' then
                print('Iterm2 support coming soon!')
            else
                printf("Renderer cannot write - terminal not compatible")
            end
            render.cursor_write_restore()
        end
        async:close()
    end)
    async:send()
end

function Renderer:add_item(source, l, c)
    ext = vim.api.nvim_buf_set_extmark(self.buf, vim.g.hologram_extmark_ns, l, c, {
        virt_text = {{' Preview Image', 'HologramVirtualText'}}
    })
    self._items[ext] = {
        source = source, 
        transform = nil,
    }
end

function Renderer:set_transform(ext, tr)
    self._items[ext].transform = tr
end

function Renderer:get_transform(ext)
    return self._items[ext].transform
end

function render.read_source(source)
    -- TODO: if source is url, create tempfile
    local file = io.open(source, 'r')
    local raw = file:read('*all')
    io.close(file)
    return raw
end

function render.detect()
    return 'kitty'
end

function render.cursor_write_move(dl, dc)
    --vim.api.nvim_win_set_cursor(0, {l, c})
    --stdout:write('\x1b[s\x1b['..l..';'..c..'H')

    -- Find direction to move in
    local seq1, seq2

    if dl < 0 then
        seq1 = 'A'  -- up
    else 
        seq1 = 'B'  -- down
    end

    if dc < 0 then
        seq2 = 'D' -- right
    else
        seq2 = 'C' -- left
    end

    stdout:write('\x1b[s') -- save position
    stdout:write('\x1b[' .. math.abs(dl) .. seq1)
    stdout:write('\x1b[' .. math.abs(dc) .. seq2)
end

function render.cursor_write_restore()
    stdout:write('\x1b[u')
end

--[[
     All Kitty graphics escape codes are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--


-- Split data into 4096 byte chunks
function render.kitty_write_chunked(data, ctrl_data)
    data = utils.base64_encode(data)
    local chunk, cmd
    local first = true

    while #data > 0 do
        chunk = data:sub(0, 4096)
        data  = data:sub(4097, -1)

        ctrl_data.m = (#data > 0) and '1' or '0'
        cmd = render.kitty_serialize_cmd(ctrl_data, chunk)
        stdout:write(cmd)

        -- Not sure why this works, but it does
        if first then stdout:write(cmd) ; first = false end
        ctrl_data = {}
    end
end

function render.kitty_serialize_cmd(ctrl, payload)
    local code = '\x1b_G'

    if ctrl then -- Lua table to string
        for k, v in pairs(ctrl) do
            code = code..k..'='..v..','
        end
        code = code:sub(0, -2) -- chop trailing comma
    end

    if payload then
        code = code..';'..payload
    end

    return code..'\x1b\\'
end

function render.kitty_write_clear(ids, free)
    local seq
    if free then seq = 'I' else seq = 'i' end
    for _, id in ipairs(ids) do
        stdout:write('\x1b_Ga=d,d=' .. seq .. ',i=' .. id)
    end
end

-- TODO: properly rewrite all sequences

--[[ 
        display Whether to display image immediately after 
                transmission. Default is 1.

        medium  Transmission medium used. Accepted values are
                'direct'(default), 'file', 'temp_file' or 'shared'.

        format  Format in which image data is sent. TODO:

        size    Dimensions of the image being sent
                • height: 0 (auto)
                •  width: 0 (auto)
--]]
function Renderer:transmit(id, keys)
    keys = keys or {}
    vim.tbl_deep_extend('keep', keys, {
        display = 1,
        medium  = 'direct',
        format  = 32,
        size    = {0, 0},
    })

    local d
    if keys.display then d = 'T' else d = 't' end

    local code = '\x1b_Ga=' .. d
        .. ',i=' .. id
        .. ',t=' .. keys.medium:sub(1, 1)
        .. ',f=' .. keys.format
        .. ',s=' .. keys.size[1]
        .. ',V=' .. keys.size[2]
        .. '\x1b\\'
end

--[[ Every transmitted image can be displayed an arbitrary number of times
     on the screen in different locations. Keys for display:

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

function Renderer:display(id, keys)
    keys = keys or {}
    vim.tbl_deep_extend('keep', keys, {
        z_index =  0,
        crop    = {0, 0},
        area    = {0, 0},
        edge    = {0, 0},
        offset  = {0, 0},
    })

    local code = '\x1b_Ga=p'
        .. ',i=' .. id
        .. ',z=' .. keys.z_index
        .. ',w=' .. keys.crop[1]
        .. ',h=' .. keys.crop[2]
        .. ',c=' .. keys.area[1]
        .. ',r=' .. keys.area[2]
        .. ',x=' .. keys.edge[1]
        .. ',y=' .. keys.edge[2]
        .. ',X=' .. keys.offset[1]
        .. ',Y=' .. keys.offset[2]
        .. '\x1b\\'
end

--[[    Delete images by either specifying an image 'id' or a set of 'keys'.
        To clear all images, set id=-1.

        free       When deleting image, free stored image data also.
                   Default is false

        z_index    Delete all images that have the specified z-index.

        col  Delete all images that intersect the specified column.

        row  Delete all images that intersect the specified row.

        cell  Delete all images that intersect the specified cell {col, row}
]]--

function Renderer:delete(id, keys)
    keys = keys or {}
    vim.tbl_deep_extend('keep', keys, {
        free = false,
        z_index = nil,
        col = nil,
        row = nil,
        cell = nil,
    })

    local case
    if keys.free then
        case = function(k) return k:upper() end
    else
        case = function(k) return k:lower() end
    end

    if id then
        if id == -1 then
            stdout:write('x1b_Ga=d,d='..case('a')..'\x1b\\')
        else
            stdout:write('x1b_Ga=d,d='..case('i')..',i='..id..'\x1b\\')
        end
        
    else
        if keys.z_index then
            stdout:write('x1b_Ga=d,d='..case('z')..',z='..keys.z_index..'\x1b\\')
        end

        if keys.col then
            stdout:write('x1b_Ga=d,d='..case('x')..',x='..keys.col..'\x1b\\')
        end

        if keys.row then
            stdout:write('x1b_Ga=d,d='..case('y')..',y='..keys.row..'\x1b\\')
        end

        if keys.cell then
            stdout:write('x1b_Ga=d,d='..case('p')..',x='..keys.cell[1]..',y='..keys.cell[2]..'\x1b\\')
        end
    end
end

render._Renderer = Renderer

return render
