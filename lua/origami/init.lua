local M = {}

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function M.base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

--[[
     All Kitty graphics escape codes are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control data> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

function M.show_image(fname)
    local file = io.open(fname, "r")
    local t = file:read("*all")
    --M.write_chunked({a= 'T', f= 100, c= 50, r= 50}, t)
    M.write_chunked({a='T', f='100'}, t)
    io.close(file)
end

function serialize_gr_command(cmd, payload)
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
function M.write_chunked(cmd, data)
    local chunk
    data = M.base64_encode(data)
    local first = true

    local stdout = vim.loop.new_pipe(false)
    stdout:open(2)
    
    while #data > 0 do
        chunk = data:sub(0, 4096)
        data  = data:sub(4097, -1)

        cmd.m = (#data > 0) and '1' or '0'
	local seri = serialize_gr_command(cmd, chunk)
	stdout:write(seri)

	-- Unsure why this must be done
	if first then stdout:write(seri) ; first = false end
        cmd = {}
    end
end

M.show_image('/Users/edluffy/Documents/D4/images/imu5.png')

return M


