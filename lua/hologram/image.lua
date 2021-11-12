local Job = require('hologram.job')

local image = {}

local stdout = vim.loop.new_pipe(false)
stdout:open(1)

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

--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--


function Image:transmit(opts)
    opts = opts or {}
    opts.medium = opts.medium or 'direct'
    local set_case = opts.hide and string.lower or string.upper

    local keys = {
        i = self.id,
        t = opts.medium:sub(1, 1),
        f = opts.format or 100,
        v = opts.height or nil,
        s = opts.width or nil,
        p = 1,
	a = set_case('t'),
    }


    local cmd, args
    if vim.fn.executable('base64') == 1 then
        cmd = 'base64'
        args = {self.source}
    elseif vim.fn.executable('openssl') == 1 then
        cmd = 'openssl'
        args = {'base64', '-A', '-in', self.source}
    else
        vim.api.nvim_err_writeln("No base64 executable found, requires one of:"..
            " coreutils, openssl")
        return
    end

    local out = {}
    Job:new({
        cmd = cmd,
        args = args,
        on_data = function(data) -- arrives in 8192 size chunks
	    data = data:gsub('%s', ''):gsub('\n', '')
            local chunks = {}
	    for i=1,#data, 4096 do
		chunks[#chunks + 1] = data:sub(i, i + 4096 - 1):gsub('%s', '')
	    end

            for i, chunk in ipairs(chunks) do
                if #chunk > 0 then
                    keys.q = 2 -- suppress responses
                    out[#out+1] = '\x1b_G' .. image.keys_to_str(keys) .. ';' .. chunk .. '\x1b\\'
                    keys = {}
                end
            end
        end,
        on_done = vim.schedule_wrap(function()
            if not opts.hide then image.move_cursor(self:pos()) end
            stdout:write(out)
            if not opts.hide then image.restore_cursor() end
        end),
    }):start()
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

    image.move_cursor(self:pos())
    stdout:write('\x1b_Ga=p,' .. image.keys_to_str(keys) .. '\x1b\\')
    image.restore_cursor()
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
        stdout:write('\x1b_Ga=d,' .. image.keys_to_str(keys) .. '\x1b\\')
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

-- Works by calculating offset between cursor and desired position.
-- Bypasses need to translate between terminal cols/rows and nvim window cols/rows ;)
function image.move_cursor(row, col)
    local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
    local dr = row - cur_row
    local dc = col - cur_col

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

function image.restore_cursor()
    stdout:write('\x1b[u')
end

function image.keys_to_str(keys)
    local str = ''
    for k, v in pairs(keys) do
        str = str..k..'='..v..','
    end
    return str:sub(0, -2) -- chop trailing comma
end

return Image
