local image = require('hologram.image')
local utils = require('hologram.utils')

local hologram = {}

local DEFAULT_OPTS = {
    mappings = {},
    protocol = 'kitty', -- hologram.detect()
}

local cellsize = utils.get_cell_size()
local generated_images = {}

function hologram.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts)

    vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')
    vim.cmd("highlight default link HologramVirtualText LspDiagnosticsDefaultHint")

    hologram.create_autocmds()
end

-- Get all extmarks in viewport (and within winwidth/2 of viewport bounds)
function hologram.viewport_get_extmarks()
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('w$')

    local view_top = math.floor(math.max(0, top-(bot-top)/2))
    local view_bot = math.floor(bot+(bot-top)/2)

    return vim.api.nvim_buf_get_extmarks(0,
        vim.g.hologram_extmark_ns,
        {view_top, 0},
        {view_bot, -1},
    {})
end

-- Returns {top, bot, left, right} area of image that can be displayed.
function hologram.viewport_check_region(img)
    local wintop = vim.fn.line('w0')
    local winbot = vim.fn.line('w$')
    local winleft = 0
    local winright = vim.fn.winwidth(0)

    local row, col = img:ext()
    local top = math.max(0, (wintop-row)*cellsize.y)
    local bot = math.min(img.height, (winbot-row+1)*cellsize.y)
    local right = winright*cellsize.x - col*cellsize.x

    return {top=top, bot=bot, left=0, right=right}
end

function hologram.scroll_images()
    local ext_list = hologram.viewport_get_extmarks()
    local buf = vim.api.nvim_get_current_buf()

    --print(vim.inspect(generated_images))
    for _, ext in ipairs(ext_list) do
        local img = generated_images[buf*100 + ext[1]]
        local rg = hologram.viewport_check_region(img)

        img:adjust({ 
            edge = {rg.left, rg.top},
            crop = {rg.right, rg.bot},
        })
    end
end

function hologram.clear_images()
    for _, img in ipairs(generated_images) do
        img:delete({ free = false, })
    end

    vim.api.nvim_buf_clear_namespace(0, vim.g.hologram_extmark_ns, 0, -1)
    generated_images = {}
end

function hologram.gen_inline_md()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    --hologram.clear_images()

    for row, line in ipairs(lines) do
        --line = line:match('!%[[^%]]%]%((.-%).)%s("(.[^"])")%s-%)')
        local image_link = line:match('!%[.-%]%(.-%)')
        if image_link then
            local source = image_link:match('%((.+)%)')
            --magick.validate_source(source)
            local img = image:new({
                source = source,
                row = row-1,
                col = 0,
            })
            generated_images[img.id] = img
            img:transmit({ hide = true, })
        end
    end
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
    vim.cmd("silent autocmd WinScrolled * :lua require('hologram').scroll_images()")
    --vim.cmd("silent autocmd WinLeave * :lua require('hologram.buffer').clear()")
    vim.cmd("augroup END")
end

return hologram
