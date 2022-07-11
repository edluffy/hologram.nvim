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
    --data_width = 's',
    --data_height = 'v',
    data_size = 'S',
    data_offset = 'O',
    image_id = 'i',
    --image_number = 'I',
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
    local ctrl = ''
    for k, v in pairs(keys) do
        ctrl = ctrl..CTRL_KEYS[k]..'='..v..','
    end
    ctrl = ctrl:sub(0, -2) -- chop trailing comma

    if payload then
        if keys.transmission_type ~= 'd' then
            payload = base64.encode(payload)
        end
        payload = terminal.get_chunked(payload)
        for i=1,#payload do
            stdout:write('\x1b_G'..ctrl..';'..payload[i]..'\x1b\\')
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
    else
        stdout:write('\x1b_G'..ctrl..'\x1b\\')
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

-- Works by calculating offset between cursor and desired position.
-- Bypasses need to translate between terminal cols/rows and nvim window cols/rows ;)
function terminal.move_cursor(row, col)
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

function terminal.restore_cursor()
    stdout:write('\x1b[u')
end

return terminal
