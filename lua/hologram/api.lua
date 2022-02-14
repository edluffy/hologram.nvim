local Image = require('hologram.image')
local state = require('hologram.state')
local utils = require('hologram.utils')
local vim = _G.vim

local hologram = {}

-- Returns {top, bot, left, right} area of image that can be displayed.
-- nil if completely hidden
function hologram.check_region(img)
    if not img or not (img.height and img.width) then
        return nil
    end

    local cell_pixels = state.dimensions.cell_pixels

    local wintop = vim.fn.line('w0')
    local winbot = vim.fn.line('w$')
    local winleft = 0
    local winright = vim.fn.winwidth(0)

    local row, col = unpack(img:pos())
    local top = math.max(winleft, (wintop - row) * cell_pixels.height)
    local bot = math.min(img.height, (winbot - row+1) * cell_pixels.height)
    local right = winright * cell_pixels.width  -  col * cell_pixels.width

    if top > bot - 1 then
        return nil
    end

    return { top = top, bot = bot, left = 0, right = right }
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

    for _, ext_loc in ipairs(hologram.get_ext_loclist(0)) do
        local ext, _, _ = unpack(ext_loc)

        local img = hologram.get_image(buf, ext)
        local crop_area = state.dimensions.screen
        if img.window ~= nil then
            crop_area =
                utils.get_window_rectangle(img.window)
                    :to_pixels(state.dimensions.cell_pixels)
        end

        img:adjust({ screen = crop_area })
    end
end

function hologram.clear_images(buf)
    if buf == 0 then
        buf = vim.api.nvim_get_current_buf()
    end

    for _, image in ipairs(Image.instances) do
        if buf == nil or image.buffer == buf then
            image:delete({ free = true })
        end
    end
end

function hologram.add_image(buf, data, row, col)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    local opts = {
        window = vim.fn.bufwinid(buf),
        buffer = buf,
        row = row,
        col = col,
    }

    local img = nil
    if type(data) == 'string' then
        img = Image:from_file(data, opts)
    elseif #(data[1][1]) == 3 then
        img = Image:from_rgb(data, opts)
    elseif #(data[1][1]) == 4 then
        img = Image:from_rgba(data, opts)
    else
        assert(false, 'Unsupported image format')
    end

    img:transmit()

    return img
end

-- Return image in 'buf' linked to 'ext'
function hologram.get_image(buf, ext)
    if buf == 0 then buf = vim.api.nvim_get_current_buf() end

    local img = nil
    for _, i in ipairs(Image.instances) do
        if i.buffer == buf and i.extmark == ext then
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
                hologram.add_image(buf, source, row, 0)
            end
        end
    end
end

function hologram.create_autocmds()
    vim.cmd("augroup Hologram")
    vim.cmd("autocmd!")
    vim.cmd("silent autocmd WinScrolled * :lua require('hologram').update_images(0)")
    vim.cmd("augroup END")
end

return hologram
