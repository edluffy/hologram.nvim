local graphics = require('hologram.graphics')
local Image = require('hologram.image')

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
end

function hologram.show()
    img = Image:new({
    })
    
    
    img:generate()
    img:show()

    img:move_pos(10, 15)
    img:generate()
    img:show()
end

function hologram.test()
    hologram.setup{}
    hologram.show()
end

return hologram
