local terminal = require('hologram.terminal')
local utils = {}

function utils.buf_screenpos(row, col, win, buf)
    local top = vim.fn.line('w0', win)
    local filler = utils.filler_above(row, win, buf)
    row = row-top+filler+1
    return utils.win_screenpos(row, col, win)
end

function utils.win_screenpos(row, col, win)
    local info = vim.fn.getwininfo(win)[1]
    row = row + info.winrow
    col = col + info.wincol + info.textoff
    return row, col
end

function utils.filler_above(row, win, buf)
    local top = vim.fn.line('w0', win)
    row = row-1 -- row exclusive
    if row <= top then
        return 0
    else
        local filler = vim.fn.winsaveview().topfill
        local exts = vim.api.nvim_buf_get_extmarks(buf,
            vim.g.hologram_extmark_ns,
            {top-1, 0},
            {row-1, -1},
            {details=true}
        )
        for i=1,#exts do
            local opts = exts[i][4]
            if opts.virt_lines then filler = filler + #opts.virt_lines end
        end
        return filler
    end
end

-- shallow
function utils.tbl_compare(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    return true
end

return utils
