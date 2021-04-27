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

-- Scroll all images in viewport (and within winwidth/2 of viewport bounds)
function hologram.scroll_images()
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('w$')

    local view_top = math.max(0, top-(bot-top)/2)
    local view_bot = bot+(bot-top)/2

    local ext_list = vim.api.nvim_buf_get_extmarks(0,
        vim.g.hologram_extmark_ns,
        {view_top, 0},
        {view_bot, -1},
    {})


    --print(vim.inspect(ext_list))

    for _, ext in ipairs(ext_list) do
        local id, row, col = unpack(ext)
        local edge_y = math.max(0, (top-row)*cellsize.y)
        local crop_y = math.min(img.height, (bot-row+1)*cellsize.y)

        generated_images[id]:adjust({ 
            edge = {0, edge_y},
            crop = {0, crop_y},
        })
    end
end

function hologram.toggle_images()
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

    hologram.clear_images()

    for row, line in ipairs(lines) do
        local col = #line
        --line = line:match('!%[[^%]]%]%((.-%).)%s("(.[^"])")%s-%)')
        local image_link = line:match('!%[.-%]%(.-%)')
        if image_link then
            local source = image_link:match('%((.+)%)')
            --magick.validate_source(source)
            img = image:new({
                source = source,
                row = row,
                col = col,
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
