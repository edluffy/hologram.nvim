local Image = require('hologram.image')
local utils = require('hologram.utils')
local Job = require('hologram.job')

local hologram = {}

local DEFAULT_OPTS = {
    mappings = {},
    protocol = 'kitty', -- hologram.detect()
}

local ws = {}
local global_images = {}

function hologram.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts)

    vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')
    vim.cmd("highlight default link HologramVirtualText LspDiagnosticsDefaultHint")

    hologram.create_autocmds()
    hologram.get_window_size()
end

function hologram.get_window_size()
    ws.col = vim.api.nvim_get_option('columns')
    ws.row = vim.api.nvim_get_option('lines')
    if vim.fn.executable('kitty') == 1 then
        Job:new({
            cmd = 'kitty',
            args = {'+kitten', 'icat', '--print-window-size'},
            on_data = function(data) 
                data = {data:match("(.+)x(.+)")}
                ws.xpixel = tonumber(data[1])
                ws.ypixel  = tonumber(data[2])
            end,
        }):start()
    else
        vim.api.nvim_err_writeln("Unable to find Kitty executable")
    end
end

-- Returns {top, bot, left, right} area of image that can be displayed.
-- nil if completely hidden
function hologram.check_region(img)
    if not (img.height and img.width) then
        return nil
    end

    local cellsize = {
        y = ws.ypixel/ws.row, 
        x = ws.xpixel/ws.col,
    }

    local wintop = vim.fn.line('w0')
    local winbot = vim.fn.line('w$')
    local winleft = 0
    local winright = vim.fn.winwidth(0)

    local row, col = img:pos()
    local top = math.max(0, (wintop-row)*cellsize.y)
    local bot = math.min(img.height, (winbot-row+1)*cellsize.y)
    local right = winright*cellsize.x - col*cellsize.x

    if top > bot-1 then
        return nil
    end

    return {top=top, bot=bot, left=0, right=right}
end

-- Get all extmarks in viewport (and within winwidth/2 of viewport bounds)
function hologram.get_ext_loclist(buf)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('w$')

    local view_top = math.floor(math.max(0, top-(bot-top)/2))
    local view_bot = math.floor(bot+(bot-top)/2)

    return vim.api.nvim_buf_get_extmarks(buf,
        vim.g.hologram_extmark_ns,
        {view_top, 0},
        {view_bot, -1},
    {})
end

function hologram.update_images(buf)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    for _, ext_loc in ipairs(hologram.get_ext_loclist()) do
        local ext, row, col = unpack(ext_loc)

        local img = hologram.get_image(buf, ext)
        local rg = hologram.check_region(img)

        if rg then
            img:adjust({ 
                edge = {rg.left, rg.top},
                crop = {rg.right, rg.bot},
            })
        else
            img:delete({free = false})
        end
    end
end

function hologram.clear_images(buf)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    for _, i in ipairs(global_images) do
        if i:buf() == buf then
            i:delete({free = true})
        end
    end
end

function hologram.add_image(buf, source, row, col)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    img = Image:new({
        source = source,
        buf = buf,
        row = row-1,
        col = 0,
    })
    img:transmit({hide = true})

    global_images[#global_images+1] = img
end

-- Return image in 'buf' linked to 'ext'
function hologram.get_image(buf, ext)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    local img = nil
    for _, i in ipairs(global_images) do 
        if i:buf() == buf and i:ext() == ext then
            img = i
        end
    end
    return img
end

function hologram.gen_images(buf, ft)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end
    ft = ft or vim.bo.filetype

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    if ft == 'markdown' then
        for row, line in ipairs(lines) do
            local image_link = line:match('!%[.-%]%(.-%)')
            if image_link then
                local source = image_link:match('%((.+)%)')
                hologram.add_image(buf, source, row, col)
            end
        end
    end

    vim.defer_fn(function()
        hologram.update_images(0)
    end, 300)
end

function hologram.create_autocmds()
    vim.cmd("augroup Hologram") vim.cmd("autocmd!")
    vim.cmd("silent autocmd WinScrolled * :lua require('hologram').update_images(0)")
    vim.cmd("augroup END")
end

return hologram
