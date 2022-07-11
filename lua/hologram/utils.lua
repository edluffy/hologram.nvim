local utils = {}

-- (1, 1) indexed
function utils.winbounds(win)
    if win == 0 then win = vim.api.nvim_get_current_win() end
    local info = vim.fn.getwininfo(win)[1]
    local left = info.textoff + info.wincol
    local top = info.winrow
    local right = info.wincol + info.width
    local bot = info.height + 1

    return {left=left, top=top, right=right, bot=bot}
end

return utils
