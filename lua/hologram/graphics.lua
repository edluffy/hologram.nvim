local utils = require('hologram.utils')

local graphics = {}

function graphics.write_cmds(cmds)
    local stdout = vim.loop.new_pipe(false)
    stdout:open(1)
	for _, cmd in ipairs(cmds) do
        stdout:write(cmds)
    end
end

function graphics.cursor_move_cmd(l, c)
	return '\x1b[s\x1b['..l..';'..c..'H'
end

function graphics.cursor_revert_cmd()
	return '\x1b[u'
end

--[[
     All Kitty graphics escape codes are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control data> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--


-- Split data into 4096 byte chunks
function graphics.kitty_write_chunked(cmd, data, out)
    data = utils.base64_encode(data)
    local chunk
    local first = true
	local s

    while #data > 0 do
        chunk = data:sub(0, 4096)
        data  = data:sub(4097, -1)

        cmd.m = (#data > 0) and '1' or '0'
		s = graphics.kitty_serialize_cmd(cmd, chunk)
		out[#out+1] = s

        if first then out[#out+1] = s ; first = false end
        cmd = {}
    end
end

function graphics.kitty_serialize_cmd(cmd, payload)
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

return graphics
