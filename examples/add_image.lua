-- !exe [luafile %]

local h = require('hologram')
local state = require('hologram.state')
local cairo = require('hologram.cairo.cairo')

-- Draw image using cairo

local width  = state.dimensions.cell_pixels.width  * 5
local height = state.dimensions.cell_pixels.height * 3
local surface = cairo.image_surface('argb32', width, height)
local cr = surface:context()
cr:line_width(2) cr:rgba(1.0, 0.0, 0.0, 1.0)
cr:rectangle(0, 0, width, height)
cr:stroke()
cr:save()
cr:translate(width / 2.0, height / 2.0)
cr:scale(5, 5)
cr:arc(0.0, 0.0, 1.0, 0.0, 2 * math.pi)
cr:stroke_preserve()
cr:restore()
surface:flush()

h.add_image(0, surface, 25, 0)






-- h.add_image(0, '/home/romgrk/img/lena.png', 32, 0)


-- Send a custom created bitmap

-- local red_100 = {255, 0, 0, 255}
-- local red_50  = {255, 0, 0, 100}
--
-- local function fill(length, value)
--   local array = {}
--   for i = 1, length do
--     table.insert(array, value)
--   end
--   return array
-- end
--
-- local function concat(tables)
--   local result = {}
--   for _, t in ipairs(tables) do
--     for _, value in ipairs(t) do
--       table.insert(result, value)
--     end
--   end
--   return result
-- end
--
-- local size = 50
-- local width = 1
-- local data = concat({
--   { fill(size, red_100) },
--   fill(size, concat({ { red_100 }, fill(size - width * 2, red_50), { red_100 } })),
--   { fill(size, red_100) },
-- })
--
-- h.add_image(0, data, 17, 0)




























