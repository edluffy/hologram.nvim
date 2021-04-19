local ffi = require("ffi")

ffi.cdef [[

int ioctl(int fd, int request, void *argp);

typedef struct winsize{
    unsigned short ws_row, ws_col;
    unsigned short ws_xpixel, ws_ypixel;
} winsize;

]]

local utils = {}

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function utils.base64_encode(data)
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

-- TIOCGWINZ is 1074295912
function utils.get_cell_size()
    local sz = ffi.new('winsize')
    ffi.C.ioctl(0, 1074295912, sz)

    local cell_sz = {
        y = sz.ws_ypixel/sz.ws_row, 
        x = sz.ws_xpixel/sz.ws_col,
    }

    return cell_sz
end

-- Must be a better way?
function utils.get_image_size(path)
    local out = vim.loop.new_pipe(false)
    local err = vim.loop.new_pipe(false)

    local img_sz = {}

    function on_read(err, data)
        for p in data:gmatch("%S+") do 
            img_sz[#img_sz+1] = p+0 -- to number
        end
    end

    handle = vim.loop.spawn('identify', {
        args = {'-format', '%h %w', path},
        stdio = {out, err},
    },
    function()
        out:read_stop()
        err:read_stop()
        out:close()
        err:close()
        handle:close()
    end)

    out:read_start(on_read)
    err:read_start(on_read)

    return img_sz
end

return utils
