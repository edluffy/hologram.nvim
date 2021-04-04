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
    --M.write_chunked({'a': 'T', 'f': 100, 'c': 50, 'r': 50}, t)
    M.write_chunked({a='T', f=100}, t)
    io.close(file)
end

function serialize_gr_command(cmd, payload)
    local cmd_str = ''
    for k, v in pairs(cmd) do
        cmd_str = cmd_str..k..'='..v..','
    end
    cmd_str = string.sub(cmd_str, 0, -2) -- chop trailing comma
    print(cmd_str)

    ans = '\x1b_G'..cmd_str
    if payload then
        ans = ans..';'..payload
    end
    ans = ans..'\x1b\\'

    return ans
end

function M.write_chunked(cmd, data)
    data = M.base64_encode(data)
    local chunk
    while string.len(data) > 0 do
        chunk = string.sub(data, 0, 4096)
        data = string.sub(data, 4096)
        if string.len(data) > 0 then cmd.m=1 else cmd.m=0 end

        io.stdout:write(serialize_gr_command(cmd, chunk))
        io.stdout:flush()
        cmd = {}
    end
    
end


return M


