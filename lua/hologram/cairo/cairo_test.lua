--[[
drawing text (toy API)
drawing glyphs
freetype fonts
toy fonts
callback-based fonts
fonts
scaled fonts

rasterization options
font options

multi-page backends
targets
devices

matrices
regions

memory management
status
misc.

]]

local cairo = require'cairo'
local bitmap = require'bitmap'
local ffi = require'ffi'
local C = cairo.C

--pixman surfaces

local function check_sr(sr)
	assert(sr:bitmap().w == 300)
	assert(sr:bitmap().h == 300)
	assert(sr:bitmap().data)
	assert(sr:bitmap().stride == 300*4)
	assert(sr:bitmap().format == 'bgra8')
	assert(sr:format() == 'argb32')
	assert(sr:bitmap_format() == 'bgra8')
	assert(sr:width() == 300)
	assert(sr:height() == 300)
	assert(sr:stride() == 300*4)
	assert(sr:bpp() == 32)
end
local sr = cairo.image_surface('argb32', 300, 300)
check_sr(sr)
sr:free()

local bmp = bitmap.new(300, 300, 'bgra8')
local sr = cairo.image_surface(bmp)
check_sr(sr)
sr:free()

local function with_png(name, func)
	local bmp = bitmap.new(300, 300, 'bgra8')
	local sr = cairo.image_surface(bmp)
	local cr = sr:context()
	sr:check()
	func(cr, sr)
	sr:check()
	cr:free()
	sr:flush()
	sr:save_png('cairo_'..name..'.png')
	sr:finish()
	sr:check()
	sr:free()
end

--surfaces

with_png('sub', function(cr, sr)
	cr:rgb(1, 0, 0)
	cr:paint()
	local sr1 = sr:sub(50, 50, sr:width()-100, sr:height()-100)
	sr1:check()
	assert(sr1:type() == 'image')
	assert(sr1:content() == 'color_alpha')
	local cr1 = sr1:context()
	cr1:rgb(0, 1, 0)
	cr1:paint()
	cr1:free()
	sr1:free()

	--misc. surface stuff
	sr:mark_dirty()
	sr:mark_dirty(1, 1, 1, 1)
	print('fallback_resolution', sr:fallback_resolution())
	print('has_show_text_glyphs', sr:has_show_text_glyphs())
	print('supports_mime_type', sr:supports_mime_type'image/png')
end)

with_png('similar_surface', function(cr, sr)
	local sr1 = sr:similar_surface('color_alpha', sr:width() - 100, sr:height() - 100)
	sr1:check()
	assert(sr1:type() == 'image')
	assert(sr1:content() == 'color_alpha')
	local cr1 = sr1:context()
	cr1:rgb(0, 1, 0)
	cr1:paint()
	cr1:free()
	cr:source(sr1, 50, 50)
	cr:paint()
	cr:rgb(0, 0, 0)
	sr1:free()
end)

with_png('similar_image_surface', function(cr, sr)
	local sr1 = sr:similar_image_surface('rgb24', sr:width() - 100, sr:height() - 100)
	sr1:check()
	assert(sr1:type() == 'image')
	assert(sr1:content() == 'color')
	local cr1 = sr1:context()
	cr1:rgb(0, 1, 0)
	cr1:paint()
	cr1:free()
	cr:source(sr1, 50, 50)
	cr:paint()
	cr:rgb(0, 0, 0)
	sr1:free()
end)

with_png('map_to_image', function(cr, sr)
	local sr1 = sr:map_to_image(100, 100, 100, 100)
	sr1:check()
	assert(sr1:type() == 'image')
	assert(sr1:content() == 'color_alpha')
	local cr1 = sr1:context()
	cr1:rgb(0, 1, 0)
	cr1:paint()
	cr1:free()
	sr:unmap_image(sr1)
end)

with_png('apply_alpha', function(cr, sr)
	cr:rgb(0, 1, 0)
	cr:paint()
	sr:apply_alpha(0.1)
end)

--recording surfaces

with_png('recording', function(cr, sr) --TOOD: bounded recording surfaces act weird
	local sr1 = cairo.recording_surface'color_alpha'
	sr1:check()
	assert(sr1:type() == 'recording')
	assert(sr1:content() == 'color_alpha')
	assert(not sr1:recording_extents())
	local x, y, w, h = sr1:ink_extents()
	assert(x == 0 and y == 0 and w == 0 and h == 0)
	local cr1 = sr1:context()
	cr1:rectangle(0, 0, 100, 100)
	cr1:rgb(0, 1, 0)
	cr1:fill()
	cr1:free()

	cr:rgb(1, 0, 0)
	cr:paint()
	cr:source(sr1, 0, 0)
	cr:paint()
	cr:source(sr1, 100, 100)
	cr:paint()
	cr:rgb(0, 0, 0)
	sr1:free()
end)

--drawing contexts

with_png('save_restore', function(cr)
	cr:rgb(1, 0, 0)
	cr:save()
	cr:rgb(0, 1, 0)
	cr:restore()
	cr:paint()
end)

--compositing

with_png('operator', function(cr) --operator()
	cr:rectangle(100, 100, 200, 200)
	cr:rgba(0, 1, 0, 1)
	cr:fill()
	cr:operator'add'
	cr:rectangle(0, 0, 200, 200)
	cr:rgba(1, 0, 0, 1)
	cr:fill()
end)

with_png('mask', function(cr, sr)
	cr:scale(sr:width(), sr:height())

	local linpat = cairo.linear_gradient(0, 0, 1, 1)
	linpat:add_color_stop(0, 0, 0, 1)
	linpat:add_color_stop(1, 0, 1, 0)

	local radpat = cairo.radial_gradient(0.5, 0.5, 0.25, 0.5, 0.5, 0.75)
	radpat:add_color_stop(0, 0, 0, 0, 1)
	radpat:add_color_stop(0.5, 0, 0, 0, 0)

	cr:source(linpat)
	cr:mask(radpat)
end)

with_png('mask_surface', function(cr, sr)
	local sr1 = cairo.image_surface('argb32', sr:width(), sr:height())
	local cr1 = sr1:context()
	cr1:rectangle(100, 100, 100, 100)
	cr1:rgba(1, 0, 0, 0.5)
	cr1:fill()
	cr:rgb(1, 1, 1)
	cr:mask(sr1)
end)

--groups

with_png('groups', function(cr)
	cr:push_group()
	cr:rectangle(100, 100, 100, 100)
	cr:rgb(1, 0, 0)
	cr:fill()
	local patt = cr:pop_group()
	cr:source(patt, 10000, 10000) --position ignored
	cr:paint()
end)

--transformations

with_png('transforms', function(cr, sr)
	local w, h = sr:width(), sr:height()
	--draw a 40% square in the center of the image rotated 45 degrees
	cr:scale(w, h)
	cr:translate(0.4, 0.4)
	cr:scale_around(0.1, 0.1, 0.5)
	cr:rotate_around(0.1, 0.1, math.pi/4)
	cr:scale_around(0.1, 0.1, 4)
	cr:rotate_around(0.1, 0.1, math.pi/2)
	cr:rectangle(0, 0, .2, .2)
	cr:rgb(1, 0, 0)
	cr:fill()
end)

with_png('paths', function(cr)
	assert(not cr:has_current_point())
	cr:new_path()
	cr:move_to(10, 10)
	assert(cr:current_point() == 10)
	cr:line_to(40, 40)
	cr:curve_to(50, 0, 60, 0, 100, 20)
	cr:quad_curve_to(0, 60, 100, 40)

	cr:new_sub_path()
	cr:arc(150, 150, 50, math.pi/2, math.pi)
	cr:arc_negative(150, 150, 50, 0, math.pi/2)
	cr:circle(150, 150, 60)
	cr:ellipse(150, 150, 80, 60, math.pi/4)

	local x1, y1, x2, y2 = cr:path_extents()
	cr:rectangle(x1, y1, x2-x1, y2-y1)

	cr:rel_move_to(50, 50)
	cr:rel_line_to(10, 10)
	cr:rel_line_to(-10, 100)
	cr:rel_curve_to(10, 10, 10, 10, 10, 10)
	cr:rel_quad_curve_to(10, 10, 10, 10)
	cr:close_path()

	local p1 = cr:copy_path()
	local p2 = cr:copy_path_flat()
	cr:translate(250, 0)
	cr:append_path(p1)
	cr:translate(0, 250)
	cr:append_path(p2)
	cr:line_width(8)
	cr:rgb(1, 1, 0)
	cr:stroke_preserve()
	cr:line_width(1)
	cr:rgb(0, 0, 0)
	cr:stroke()

	--cr:in_stroke(x, y) -> t|f	hit-test the stroke area
	--cr:in_fill(x, y) -> t|f	hit-test the fill area
	--cr:in_clip(x, y) -> t|f	hit-test the clip area
	--cr:stroke_extents() -> x1, y1, x2, y2	get the bounding box of stroking the current path
	--cr:fill_extents() -> x1, y1, x2, y2
end)

with_png('clipping', function(cr)
	cr:rectangle(100, 100, 100, 100)
	cr:clip_preserve()
	cr:rgb(1, 1, 1)
	cr:paint()
	cr:rgb(1, 0, 0)
	cr:line_width(10)
	cr:stroke()
end)

with_png('pattern_color', function(cr)
	local patt = cairo.color_pattern(1, 0, 0)
	cr:source(patt)
	cr:paint()
end)

with_png('pattern_color', function(cr)
	local patt = cairo.color_pattern(1, 0, 0)
	cr:source(patt)
	cr:paint()
end)

with_png('pattern_linear_gradient', function(cr, sr)
	cr:scale(sr:width(), sr:height())
	local linpat = cairo.linear_gradient(0, 0, 0, 1)
	assert(linpat:matrix().xx == 1)
	assert(linpat:type() == 'linear')
	assert(linpat:linear_points() == 0)
	assert(linpat:extend() == 'pad')
	assert(linpat:filter() == 'good')
	linpat:filter'nearest'
	linpat:add_color_stop(0, 0, 0, 1)
	linpat:add_color_stop(1, 0, 1, 0)
	assert(linpat:color_stop'#' == 2)
	assert(linpat:color_stop(1) == 1)
	cr:source(linpat)
	cr:paint()
end)

with_png('pattern_radial_gradient', function(cr, sr)
	cr:scale(sr:width(), sr:height())
	local radpat = cairo.radial_gradient(0.5, 0.5, 0.25, 0.5, 0.5, 0.75)
	assert(radpat:matrix().xx == 1)
	assert(radpat:type() == 'radial')
	assert(radpat:radial_circles() == 0.5)
	assert(radpat:extend() == 'pad')
	assert(radpat:filter() == 'good')
	radpat:filter'gaussian'
	radpat:add_color_stop(0, 1, 0, 0, 1)
	radpat:add_color_stop(0.5, 0, 0, 0, 0)
	assert(radpat:color_stop'#' == 2)
	assert(radpat:color_stop(1) == 0.5)
	cr:source(radpat)
	cr:paint()
end)

with_png('pattern_surface', function(cr, sr)
	local sr1 = cairo.load_png'cairo_pattern_radial_gradient.png'
	local patt = cairo.surface_pattern(sr1)
	local mt = cairo.matrix():scale(2, 2)
	patt:matrix(mt)
	patt:extend'repeat'
	cr:source(patt)
	cr:paint()
	cr:rgb(1, 1, 1)
	patt:free()
	sr1:free()
end)

--TODO: raster source patterns
--TODO: mesh patterns

with_png('text_toy', function(cr)
	cr:font_face('Times New Roman', 'italic', 'bold')
	cr:font_size(72)
	cr:rgb(1, 1, 1)
	cr:move_to(50, 100)
	cr:show_text'Hello!'
	cr:move_to(50, 200)
	cr:line_width(1)
	cr:text_path'Hello!'
	cr:stroke()
	local e = cr:text_extents'Hello!'
	cr:translate(50, 200)
	cr:rectangle(e.x_bearing, e.y_bearing, e.width, e.height)
	cr:stroke()
	cr:circle(e.x_advance, e.y_advance, 5)
	cr:fill()
end)

local function show_text_extents(cr, e)
	cr:rectangle(e.x_bearing, e.y_bearing, e.width, e.height)
	cr:stroke()
	cr:circle(e.x_advance, e.y_advance, 5)
end

with_png('text_toy', function(cr)
	cr:font_face('Times New Roman', 'italic', 'bold')
	cr:font_size(72)
	cr:font_matrix(cairo.matrix():scale(72)) --same as above!
	cr:rgb(1, 1, 0)
	print(cr:font_extents())
	cr:move_to(50, 100)
	cr:show_text'Hello!'
	cr:move_to(50, 200)
	cr:line_width(1)
	cr:text_path'Hello!'
	cr:stroke()
	local e = cr:text_extents'Hello!'
	cr:translate(50, 200)
	show_text_extents(cr, e)
end)

with_png('text_glyphs', function(cr)
	local face = cairo.toy_font_face('Times New Roman', 'italic', 'bold')
	assert(face:type() == 'toy')
	cr:font_face(face)
	cr:font_size(72)

	local g = cairo.allocate_glyphs(2)
	g[0].index = 40
	g[0].x = 0
	g[0].y = 0
	g[1].index = 41
	g[1].x = 40
	g[1].y = 0

	cr:rgb(1, 1, 0)
	cr:translate(100, 100)
	cr:show_glyphs(g, 2)
	local e = cr:glyph_extents(g, 2)
	show_text_extents(cr, e)

	cr:translate(0, 100)
	cr:glyph_path(g, 2)
	cr:stroke()
	local e = cr:glyph_extents(g, 2)
	show_text_extents(cr, e)
	cr:stroke()
end)

with_png('text_cluster_mapping', function(cr)
	cr:font_face('Times New Roman', 'italic', 'bold')
	local face = cr:font_face()
	face:check()
	local mt = cairo.matrix():scale(15)
	local ctm = cairo.matrix():scale(2)
	cr:matrix(ctm)
	local fopt = cairo.font_options()
	local sfont = face:scaled_font(mt, ctm, fopt)
	sfont:check()
	local s = 'Hello!'
	local g, ng, c, nc, cf = sfont:text_to_glyphs(100, 100, s)
	cr:rgb(1, 1, 0)
	cr:show_text_glyphs(s, nil, g, ng, c, nc, cf)
	g:free()
	c:free()
	sfont:free()
	face:unref()
end)


with_png('matrices', function(cr, sr)
	local mt = cairo.matrix()
	assert(mt == cairo.matrix(1, 0, 0, 1, 0, 0))
	assert(mt == cairo.matrix(mt))
	assert(mt == mt:copy())
	assert(mt:copy():scale(2) == mt:copy():reset(mt:copy():scale(2)))
	assert(mt:copy():translate(3, 5):scale(2) == mt:copy():reset(2, 0, 0, 2, 3, 5))
	assert(mt == cairo.matrix():translate(2, 3):scale(5, 7):rotate(2):reset())

	mt:scale(10):rotate(math.pi):translate(5, 0):skew(0, 0)
	local x, y = mt(1, 0)
	assert(x == -60 and math.abs(y) <= 1e-10)
	local x, y = mt:distance(1, 0)
	assert(x == -10 and math.abs(y) <= 1e-10)

	assert(mt:invert())
	local x, y = mt(0, 0)
	assert(x == -5 and y == 0)

	local mt0 = mt:copy()
	local mt1 = mt * cairo.matrix():scale(-2)
	assert(mt0 == mt)
	assert(mt1 ~= mt)
	local x, y = mt1(0, 0)
	assert(x == 10 and y == 0)

	assert(mt:copy():rotate_around(2, 5, 3) == mt:copy():translate(2, 5):rotate(3):translate(-2, -5))
	assert(mt:copy():scale_around(2, 5, 3, 4) == mt:copy():translate(2, 5):scale(3, 4):translate(-2, -5))

	local mt = cairo.matrix(0, 0, 0, 0, 0, 0)
	assert(mt:determinant() == 0)
	assert(not mt:invertible())
	local mt1 = mt:copy()
	assert(not mt:invert())
	assert(mt1 == mt)
end)

local function pdf_test()
	print('pdf versions', table.concat(cairo.pdf_versions(), ', '))
	local sr = cairo.pdf_surface('cairo_test.pdf', 500, 500)
	sr:check()
	assert(sr:type() == 'pdf')
	sr:pdf_version'1.5'
	sr:pdf_size(1000, 1000)
	local cr = sr:context()
	sr:check()
	cr:rgb(1, 0, 0)
	cr:rectangle(400, 400, 200, 200)
	cr:fill_preserve()
	cr:rgb(0, 1, 0)
	cr:line_width(10)
	cr:stroke()
	cr:free()
	sr:free()
end
pdf_test()

local function ps_test()
	print('ps levels', table.concat(cairo.ps_levels(), ', '))
	local sr = cairo.ps_surface('cairo_test.ps', 500, 500)
	sr:check()
	assert(sr:type() == 'ps')
	sr:ps_level(3)
	sr:ps_size(1000, 1000)
	sr:ps_eps(true)
	assert(sr:ps_eps())
	sr:ps_dsc_begin_setup()
	sr:ps_dsc_begin_page_setup()
	local cr = sr:context()
	sr:check()
	cr:rgb(1, 0, 0)
	cr:rectangle(400, 400, 200, 200)
	cr:fill_preserve()
	cr:rgb(0, 1, 0)
	cr:line_width(10)
	cr:stroke()
	cr:free()
	sr:free()
end
ps_test()

local function svg_test()
	print('svg versions', table.concat(cairo.svg_versions(), ', '))
	local sr = cairo.svg_surface('cairo_test.svg', 1000, 1000)
	sr:check()
	assert(sr:type() == 'svg')
	sr:svg_version'1.2'
	local cr = sr:context()
	sr:check()
	cr:rgb(1, 0, 0)
	cr:rectangle(400, 400, 200, 200)
	cr:fill_preserve()
	cr:rgb(0, 1, 0)
	cr:line_width(10)
	cr:stroke()
	cr:free()
	sr:free()
end
svg_test()

--misc.
print('cairo version: ', cairo.version())
print('cairo version string: ', cairo.version_string())
