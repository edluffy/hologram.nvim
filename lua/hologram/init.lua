local api = require('hologram.api')
local png = require('hologram.ft.png')
local state = require('hologram.state')

local did_init = false

local function initialize()
  if did_init then
    return
  end

  vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')

  api.create_autocmds()
  state.update_dimensions()

  did_init = true
end

local function setup(opts)
  -- opts unused for now

  initialize()

  png.enable()
end

return vim.tbl_extend('keep', api, {
  setup = setup,
})
