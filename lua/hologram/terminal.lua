local base64 = require('hologram.base64')

local terminal = {}
local stdout = vim.loop.new_tty(1, false)

--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

local CTRL_KEYS = {
    -- General
    action = 'a',
    delete_action = 'd',
    quiet = 'q',

    -- Transmission
    format = 'f',
    transmission_type = 't',
    data_width = 's',
    data_height = 'v',
    data_size = 'S',
    data_offset = 'O',
    image_id = 'i',
    image_number = 'I',
    compressed = 'o',
    more = 'm',

    -- Display
    placement_id = 'p',
    x_offset = 'x',
    y_offset = 'y',
    width = 'w',
    height = 'h',
    cell_x_offset = 'X',
    cell_y_offset = 'Y',
    cols = 'c',
    rows = 'r',
    cursor_movement = 'C',
    z_index = 'z',

    -- TODO: Animation
}

function terminal.send_graphics_command(keys, payload)
    if payload and string.len(payload) > 4096 then keys.more = 1 else keys.more = 0 end
    local ctrl = ''
    for k, v in pairs(keys) do
        if v ~= nil then
            ctrl = ctrl..CTRL_KEYS[k]..'='..v..','
        end
    end
    ctrl = ctrl:sub(0, -2) -- chop trailing comma

    if payload then
        if keys.transmission_type ~= 'd' then
            payload = base64.encode(payload)
        end
        payload = terminal.get_chunked(payload)
        for i=1,#payload do
            terminal.write('\x1b_G'..ctrl..';'..payload[i]..'\x1b\\')
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
    else
        terminal.write('\x1b_G'..ctrl..'\x1b\\')
    end
end

-- Split into chunks of max 4096 length
function terminal.get_chunked(str)
    local chunks = {}
    for i = 1,#str,4096 do
        local chunk = str:sub(i, i + 4096 - 1):gsub('%s', '')
        if #chunk > 0 then
            table.insert(chunks, chunk)
        end
    end
    return chunks
end

function terminal.move_cursor(row, col)
    terminal.write('\x1b[s')
    terminal.write('\x1b['..row..':'..col..'H')
end

function terminal.restore_cursor()
    terminal.write('\x1b[u')
end

-- glob together writes to stdout
terminal.write = vim.schedule_wrap(function(data)
    stdout:write(data)
end)

return terminal
