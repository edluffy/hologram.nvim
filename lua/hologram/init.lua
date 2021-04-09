local render = require('hologram.render')

local hologram = {}

local DEFAULT_OPTS = {
    align = 'float',
    mappings = {},
    protocol = 'kitty', -- hologram.detect()
}

function hologram.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts)

    vim.g.mark_ns = vim.api.nvim_create_namespace('hologram')
    vim.api.nvim_set_decoration_provider(vim.g.mark_ns, {
        on_buf = hologram._on_buf,
    })
    hologram.create_autocmds()
end

local renderer = render._Renderer:new()


function hologram.create_autocmds()
    vim.cmd("augroup Hologram") vim.cmd("autocmd!")
    vim.cmd("silent autocmd CursorMoved * :lua require('hologram').update_viewport()")
    vim.cmd("augroup END")
end

return hologram
