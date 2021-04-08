local utils = require('origami.utils')

local M = {}

--[[
     All Kitty graphics escape codes are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control data> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

function M.kitty_show_image(fname, opts)
    local file = io.open(fname, "r")
    local t = file:read("*all")
    --M.kitty_write_chunked({a= 'T', f= 100, c= 50, r= 50}, t)
    M.kitty_write_chunked({a='T', f='100'}, t)
    io.close(file)
end

function M.kitty_serialize_cmd(cmd, payload)
    local code = '\x1b_G'

    if cmd then -- Lua table to string
        for k, v in pairs(cmd) do
            code = code..k..'='..v..','
        end
        code = code:sub(0, -2) -- chop trailing comma
    end

    if payload then
        code = code..';'..payload
    end

    return code..'\x1b\\'
end

-- Split data into 4096 byte chunks
function M.kitty_write_chunked(cmd, data)
    local chunk
    local first = true
    data = utils.base64_encode(data)

    local stdout = vim.loop.new_pipe(false)
    stdout:open(1)
    
    while #data > 0 do
        chunk = data:sub(0, 4096)
        data  = data:sub(4097, -1)

        cmd.m = (#data > 0) and '1' or '0'
	local seri = M.kitty_serialize_cmd(cmd, chunk)
	stdout:write(seri)

	-- Unsure why this must be done
	if first then stdout:write(seri) ; first = false end

        cmd = {}
    end
end

M.kitty_show_image('/Users/edluffy/Documents/D4/images/imu5.png')

return M


