local image = require('hologram.image')
local utils = require('hologram.utils')

local hologram = {}

local DEFAULT_OPTS = {
    mappings = {},
    protocol = 'kitty', -- hologram.detect()
}

local cellsize = utils.get_cell_size()
local _buffer_images = {}

function hologram.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts)

    vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')
    vim.cmd("highlight default link HologramVirtualText LspDiagnosticsDefaultHint")

    hologram.create_autocmds()
end


-- Returns {top, bot, left, right} area of image that can be displayed.
function hologram.viewport_check_region(img)
    local wintop = vim.fn.line('w0')
    local winbot = vim.fn.line('w$')
    local winleft = 0
    local winright = vim.fn.winwidth(0)

    local row, col = img:pos()
    local top = math.max(0, (wintop-row)*cellsize.y)
    local bot = math.min(img.height, (winbot-row+1)*cellsize.y)
    local right = winright*cellsize.x - col*cellsize.x

    return {top=top, bot=bot, left=0, right=right}
end

function hologram.buf_update_viewport(buf)
    local buf = buf or vim.api.nvim_get_current_buf()

    for _, ext_loc in ipairs(hologram.buf_get_ext_loclist(buf)) do
        local ext, row, col = unpack(ext_loc)
        
        local img = hologram.buf_get_image(buf, ext)
        local rg = hologram.viewport_check_region(img)

        img:adjust({ 
            edge = {rg.left, rg.top},
            crop = {rg.right, rg.bot},
        })
    end
end

function hologram.buf_clear_images(buf)
    if _buffer_images[buf] then
        for _, img in ipairs(_buffer_images[buf]) do
            img:delete({ free = true, })
        end
        _buffer_images[buf] = {}
    end
end

-- Return image in 'buf' linked to 'ext'
function hologram.buf_get_image(buf, ext)
    local img = nil
    if _buffer_images[buf] then
        for _, i in ipairs(_buffer_images[buf]) do 
            if i:ext() == ext then
                img = i
            end
        end
    end
    return img
end

-- Get all extmarks in viewport (and within winwidth/2 of viewport bounds)
function hologram.buf_get_ext_loclist(buf)
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

function hologram.buf_add_images(buf, images)
    if not _buffer_images[buf] then
        _buffer_images[buf] = {}
    end

    for _, img in ipairs(images) do
        table.insert(_buffer_images[buf], img)
        img:transmit({ hide = true, })
    end
end

function hologram.gen_inline_md()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    hologram.buf_clear_images(buf)

    local images = {}
    for row, line in ipairs(lines) do
        --line = line:match('!%[[^%]]%]%((.-%).)%s("(.[^"])")%s-%)')
        local image_link = line:match('!%[.-%]%(.-%)')
        if image_link then
            local source = image_link:match('%((.+)%)')
            --magick.validate_source(source)
            images[#images+1] = image:new({
                source = source,
                row = row-1,
                col = 0,
            })
        end
    end
    hologram.buf_add_images(buf, images)

    -- oneshot timer with 0 timeout. Callback fires on the next event loop iteration
    vim.defer_fn(function()
        hologram.buf_update_viewport(buf)
    end, 0)
end

function hologram.gen_inline_tex()
end

function hologram.gen_preview_md()
end

function hologram.gen_preview_tex()
end

function hologram.create_autocmds()
    vim.cmd("augroup Hologram") vim.cmd("autocmd!")
    --vim.cmd("silent autocmd BufEnter * :lua require('hologram').gen_inline_md()")
    --vim.cmd("silent autocmd WinScrolled * :lua require('hologram').buf_update_viewport()")
    --vim.cmd("silent autocmd BufWinEnter * :lua require('hologram').gen_inline_md()")
    vim.cmd("augroup END")
end

return hologram
