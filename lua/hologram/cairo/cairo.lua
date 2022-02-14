
--cairo graphics library ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

--Supports garbage collection, metatype methods, accepting and returning
--strings, returning multiple values instead of passing output buffers,
--and many API additions for completeness.

local ffi = require'ffi'
local bit = require'bit'
require'hologram.cairo.cairo_h'
local C = ffi.load'cairo'
local M = {C = C}

--binding vocabulary ---------------------------------------------------------

--C namespace that returns nil for missing symbols instead of raising an error.
local function sym(name) return C[name] end
local _C = setmetatable({}, {__index = function(_C, k)
    return pcall(sym, k) and C[k] or nil
end})
M._C = _C

--bidirectional mapper for enum values to names
local enums = {} --{prefix -> {enumval -> name; name -> enumval}}
local function map(prefix, t)
	local dt = {}
	for i,v in ipairs(t) do
		local k = C[prefix..tostring(v)]
		local v = type(v) == 'string' and v:lower() or v
		dt[k] = v
		dt[v] = k
	end
	enums[prefix] = dt
end
M.enums = enums

--'foo' -> C.CAIRO_<PREFIX>_FOO and C.CAIRO_<PREFIX>_FOO -> 'foo' conversions
local function X(prefix, val)
	local val = enums[prefix][val]
	if not val then
		error('invalid enum value for '..prefix, 2)
	end
	return val
end

--create a gc-tying constructor
local function ref_func(create, destroy)
	return create and function(...)
		local self = create(...)
		return self ~= nil and ffi.gc(self, destroy) or nil
	end
end

--method for freeing reference-counted objects: crash if there are still references.
local function free(self)
	local n = self:refcount() - 1
	self:unref()
	if n ~= 0  then
		error(string.format('refcount of %s is %d, should be 0', tostring(self), n))
	end
end

--create a gc-untying destructor
local function destroy_func(destroy)
	return function(self)
		ffi.gc(self, nil)
		destroy(self)
	end
end

--create a flag setter
local function setflag_func(set, prefix)
	return set and function(self, flag)
		set(self, X(prefix, flag))
	end
end

--create a flag getter
local function getflag_func(get, prefix)
	return get and function(self)
		return X(prefix, get(self))
	end
end

--create a get/set function that disambiguates get() from set() actions
--by the second argument being nil or not.
local function getset_func(get, set, prefix)
	if not (get and set) then return end
	if prefix then
		get = getflag_func(get, prefix)
		set = setflag_func(set, prefix)
	end
	return function(self, ...)
		if type((...)) == 'nil' then --get val
			return get(self, ...)
		else --set val
			set(self, ...)
			return self --for method chaining
		end
	end
end

--scratch out-vars
local d1 = ffi.new'double[1]'
local d2 = ffi.new'double[1]'
local d3 = ffi.new'double[1]'
local d4 = ffi.new'double[1]'
local d5 = ffi.new'double[1]'
local d6 = ffi.new'double[1]'

--wrap a function that takes two output doubles
local function d2out_func(func)
	return func and function(self)
		func(self, d1, d2)
		return d1[0], d2[0]
	end
end

--wrap a function that takes two in-out doubles
local function d2inout_func(func)
	return func and function(self, x, y)
		d1[0], d2[0] = x, y
		func(self, d1, d2)
		return d1[0], d2[0]
	end
end

--wrap a function that takes 4 output doubles
local function d4out_func(func)
	return func and function(self)
		func(self, d1, d2, d3, d4)
		return d1[0], d2[0], d3[0], d4[0]
	end
end

-- wrap a function that returns a boolean
local function bool_func(f)
	return f and function(...)
		return f(...) == 1
	end
end

--factory for creating wrappers for functions that have a struct output arg
local function structout_func(ctype)
	ctype = ffi.typeof(ctype)
	return function(func)
		return func and function(self, out)
			out = out or ctype()
			func(self, out)
			return out
		end
	end
end
local mtout_func = structout_func'cairo_matrix_t'

--factory for creating wrappers for functions that have a constructed output arg
local function consout_func(cons)
	return function(func)
		return func and function(self, out)
			out = out or cons()
			func(self, out)
			return out
		end
	end
end
local foptout_func = consout_func(ref_func(C.cairo_font_options_create, C.cairo_font_options_destroy))

--wrap a function that has a cairo_text_extents_t as output arg 2 after self
local function texout2_func(func)
	local ctype = ffi.typeof'cairo_text_extents_t'
	return func and function(self, arg1, out)
		out = out or ctype()
		func(self, arg1, out)
		return out
	end
end

--wrap a function that has a cairo_text_extents_t as output arg 3 after self
local function texout3_func(func)
	local ctype = ffi.typeof'cairo_text_extents_t'
	return func and function(self, arg1, arg2, out)
		out = out or ctype()
		func(self, arg1, arg2, out)
		return out
	end
end

--wrap a function that has a cairo_font_extents_t as output arg 1 after self
local function fexout_func(func)
	local ctype = ffi.typeof'cairo_font_extents_t'
	return func and function(self, out)
		out = out or ctype()
		func(self, out)
		return out
	end
end

--wrap a function that returns a string
local function str_func(func)
	return func and function(...)
		return ffi.string(func(...))
	end
end

--convert a function with an output arg into a getter to be used with getset_func.
--all we're doing is shifting the out arg from arg#1 to arg#2 after self so that
--disambiguation between get and set actions can continue to work yet we can still
--be able to give an output buffer in arg#2 for the get action.
local function getter_func(out_func)
	return function(func)
		local func = out_func(func)
		return function(self, _, out)
			return func(self, out)
		end
	end
end
local mtout_getfunc = getter_func(mtout_func)
local foptout_getfunc = getter_func(foptout_func)

local function check_status(status)
	if status ~= 0 then
		error(M.status_message(status), 2)
	end
end

local function ret_status(st)
	if st == 0 then
		return true
	else
		return nil, M.status_message(st), st
	end
end
local function status_func(func)
	return function(...)
		return ret_status(func(...))
	end
end

local function ptr(p) --convert NULL to nil
	if p == nil then return nil end
	return p
end

--wrap a pointer-returning function so that NULL is converted to nil
local function ptr_func(func)
	return func and function(...)
		return ptr(func(...))
	end
end

--method to get status as a string, for any object which has a status() method.
local function status_message(self)
	return M.status_message(self:status())
end

--method to check the status and raise and error
local function check(self)
	local status = self:status()
	if status ~= 0 then
		error(self:status_message(), 2)
	end
end

local ir = ffi.new'cairo_rectangle_int_t'
local function set_int_rect(x, y, w, h)
	if not x then return end
	ir.x = x
	ir.y = y
	ir.width = w
	ir.height = h
	return ir
end

local sr_ct = ffi.typeof'cairo_surface_t*'
local function patt_or_surface_func(patt_func, surface_func)
	return function(self, patt, x, y)
		if ffi.istype(patt, sr_ct) then
			surface_func(self, patt, x or 0, y or 0)
		else
			patt_func(self, patt)
		end
	end
end

local function unpack_rect(r)
	return r.x, r.y, r.width, r.height
end

local function ret_self(func)
	return function(self, ...)
		func(self, ...)
		return self
	end
end

--binding --------------------------------------------------------------------

M.NULL = ffi.cast('void*', 0)

M.version = C.cairo_version
M.version_string = str_func(C.cairo_version_string)

map('CAIRO_STATUS_', {
	'SUCCESS',
	'NO_MEMORY',
	'INVALID_RESTORE',
	'INVALID_POP_GROUP',
	'NO_CURRENT_POINT',
	'INVALID_MATRIX',
	'INVALID_STATUS',
	'NULL_POINTER',
	'INVALID_STRING',
	'INVALID_PATH_DATA',
	'READ_ERROR',
	'WRITE_ERROR',
	'SURFACE_FINISHED',
	'SURFACE_TYPE_MISMATCH',
	'PATTERN_TYPE_MISMATCH',
	'INVALID_CONTENT',
	'INVALID_FORMAT',
	'INVALID_VISUAL',
	'FILE_NOT_FOUND',
	'INVALID_DASH',
	'INVALID_DSC_COMMENT',
	'INVALID_INDEX',
	'CLIP_NOT_REPRESENTABLE',
	'TEMP_FILE_ERROR',
	'INVALID_STRIDE',
	'FONT_TYPE_MISMATCH',
	'USER_FONT_IMMUTABLE',
	'USER_FONT_ERROR',
	'NEGATIVE_COUNT',
	'INVALID_CLUSTERS',
	'INVALID_SLANT',
	'INVALID_WEIGHT',
	'INVALID_SIZE',
	'USER_FONT_NOT_IMPLEMENTED',
	'DEVICE_TYPE_MISMATCH',
	'DEVICE_ERROR',
	'INVALID_MESH_CONSTRUCTION',
	'DEVICE_FINISHED',
	'LAST_STATUS',
})

map('CAIRO_CONTENT_', {
	'COLOR',
	'ALPHA',
	'COLOR_ALPHA',
})

map('CAIRO_FORMAT_', {
	'INVALID',
	'ARGB32',
	'RGB24',
	'A8',
	'A1',
	'RGB16_565',
	'RGB30',
})

local cairo_formats = {
	bgra8  = 'argb32',
	bgrx8  = 'rgb24',
	g8     = 'a8',
	g1     = 'a1',
	rgb565 = 'rgb16_565',
	bgr10  = 'rgb30',
}

local bitmap_formats = {
	argb32    = 'bgra8',
	rgb24     = 'bgrx8',
	a8        = 'g8',
	a1        = 'g1',
	rgb16_565 = 'rgb565',
	rgb30     = 'bgr10',
	invalid   = 'invalid',
}

function M.cairo_format(format)
	return cairo_formats[format] or format
end

function M.bitmap_format(format)
	return bitmap_formats[format] or format
end

local cr = {}

cr.status = C.cairo_status
cr.status_message = status_message
cr.check = check

cr.ref = ref_func(C.cairo_reference, C.cairo_destroy)
cr.unref = destroy_func(C.cairo_destroy)
cr.free = free
cr.refcount = C.cairo_get_reference_count

cr.save = C.cairo_save
cr.restore = C.cairo_restore

local push_group_with_content = setflag_func(C.cairo_push_group_with_content, 'CAIRO_CONTENT_')
cr.push_group = function(cr, content)
	if content then
		push_group_with_content(cr, content)
	else
		C.cairo_push_group(cr)
	end
end
cr.pop_group = ref_func(C.cairo_pop_group, C.cairo_pattern_destroy)
cr.pop_group_to_source = C.cairo_pop_group_to_source

map('CAIRO_OPERATOR_', {
	'CLEAR',
	'SOURCE',
	'OVER',
	'IN',
	'OUT',
	'ATOP',
	'DEST',
	'DEST_OVER',
	'DEST_IN',
	'DEST_OUT',
	'DEST_ATOP',
	'XOR',
	'ADD',
	'SATURATE',
	'MULTIPLY',
	'SCREEN',
	'OVERLAY',
	'DARKEN',
	'LIGHTEN',
	'COLOR_DODGE',
	'COLOR_BURN',
	'HARD_LIGHT',
	'SOFT_LIGHT',
	'DIFFERENCE',
	'EXCLUSION',
	'HSL_HUE',
	'HSL_SATURATION',
	'HSL_COLOR',
	'HSL_LUMINOSITY',
})

cr.operator = getset_func(C.cairo_get_operator, C.cairo_set_operator, 'CAIRO_OPERATOR_')
cr.source = getset_func(C.cairo_get_source, patt_or_surface_func(C.cairo_set_source, C.cairo_set_source_surface))
cr.rgb = C.cairo_set_source_rgb
cr.rgba = C.cairo_set_source_rgba
cr.tolerance = getset_func(C.cairo_get_tolerance, C.cairo_set_tolerance)

map('CAIRO_ANTIALIAS_', {
	'DEFAULT',
	'NONE',
	'GRAY',
	'SUBPIXEL',
	'FAST',
	'GOOD',
	'BEST',
})

cr.antialias = getset_func(C.cairo_get_antialias, C.cairo_set_antialias, 'CAIRO_ANTIALIAS_')

map('CAIRO_FILL_RULE_', {
	'WINDING',
	'EVEN_ODD',
})

cr.fill_rule = getset_func(C.cairo_get_fill_rule, C.cairo_set_fill_rule, 'CAIRO_FILL_RULE_')

cr.line_width = getset_func(C.cairo_get_line_width, C.cairo_set_line_width)

map('CAIRO_LINE_CAP_', {
	'BUTT',
	'ROUND',
	'SQUARE',
})

cr.line_cap = getset_func(C.cairo_get_line_cap, C.cairo_set_line_cap, 'CAIRO_LINE_CAP_')

map('CAIRO_LINE_JOIN_', {
	'MITER',
	'ROUND',
	'BEVEL',
})

cr.line_join = getset_func(C.cairo_get_line_join, C.cairo_set_line_join, 'CAIRO_LINE_JOIN_')

cr.dash = function(cr, dashes, num_dashes, offset)
	if dashes == '#' then --dash(cr, '#') -> get count
		return C.cairo_get_dash_count(cr)
	elseif dashes == nil then
		if num_dashes then --dash(cr, nil, double*) -> get into array
			dashes = num_dashes
			C.cairo_get_dash(cr, dashes, d1)
			return dashes, d1[0]
		else --dash(cr) -> get into table
			local n = C.cairo_get_dash_count(cr)
			dashes = ffi.new('double[?]', n)
			C.cairo_get_dash(cr, dashes, d1)
			local t = {}
			for i=1,n do
				t[i] = dashes[i-1]
			end
			return t, d1[0]
		end
	elseif type(dashes) == 'table' then --dash(cr, t[, offset]) -> set from table
		num_dashes, offset = #dashes, num_dashes
		dashes = ffi.new('double[?]', num_dashes, dashes)
		C.cairo_set_dash(cr, dashes, num_dashes, offset or 0)
	else --dash(cr, dashes*, num_dashes[, offset]) -> set from array
		if dashes == false then --for when num_dashes == 0
			dashes = nil
			assert(num_dashes == 0)
		end
		C.cairo_set_dash(cr, dashes, num_dashes, offset or 0)
	end
end

cr.miter_limit = getset_func(C.cairo_get_miter_limit, C.cairo_set_miter_limit)

cr.translate = ret_self(C.cairo_translate)
cr.scale = function(cr, sx, sy) C.cairo_scale(cr, sx, sy or sx); return cr end
cr.rotate = ret_self(C.cairo_rotate)
cr.transform = ret_self(C.cairo_transform)

cr.matrix = getset_func(mtout_getfunc(C.cairo_get_matrix), C.cairo_set_matrix)
cr.identity_matrix = ret_self(C.cairo_identity_matrix)

cr.user_to_device          = d2inout_func(C.cairo_user_to_device)
cr.user_to_device_distance = d2inout_func(C.cairo_user_to_device_distance)
cr.device_to_user          = d2inout_func(C.cairo_device_to_user)
cr.device_to_user_distance = d2inout_func(C.cairo_device_to_user_distance)

cr.new_path = C.cairo_new_path
cr.move_to = C.cairo_move_to
cr.new_sub_path = C.cairo_new_sub_path
cr.line_to = C.cairo_line_to
cr.curve_to = C.cairo_curve_to
cr.arc = C.cairo_arc
cr.arc_negative = C.cairo_arc_negative
cr.rel_move_to = C.cairo_rel_move_to
cr.rel_line_to = C.cairo_rel_line_to
cr.rel_curve_to = C.cairo_rel_curve_to
cr.rectangle = C.cairo_rectangle
cr.close_path = C.cairo_close_path
cr.path_extents = d4out_func(C.cairo_path_extents)
cr.paint = C.cairo_paint
cr.paint_with_alpha = C.cairo_paint_with_alpha
cr.mask = patt_or_surface_func(C.cairo_mask, C.cairo_mask_surface)
cr.stroke = C.cairo_stroke
cr.stroke_preserve = C.cairo_stroke_preserve
cr.fill = C.cairo_fill
cr.fill_preserve = C.cairo_fill_preserve

cr.copy_page = C.cairo_copy_page
cr.show_page = C.cairo_show_page

cr.in_stroke = bool_func(C.cairo_in_stroke)
cr.in_fill = bool_func(C.cairo_in_fill)
cr.in_clip = bool_func(C.cairo_in_clip)

cr.stroke_extents = d4out_func(C.cairo_stroke_extents)
cr.fill_extents = d4out_func(C.cairo_fill_extents)
cr.reset_clip = C.cairo_reset_clip
cr.clip = C.cairo_clip
cr.clip_preserve = C.cairo_clip_preserve
cr.clip_extents = d4out_func(C.cairo_clip_extents)
cr.clip_rectangles = ref_func(C.cairo_copy_clip_rectangle_list, C.cairo_rectangle_list_destroy)

local rl = {}

rl.free = destroy_func(C.cairo_rectangle_list_destroy)

M.allocate_glyphs = ref_func(C.cairo_glyph_allocate, C.cairo_glyph_free)

local glyph = {}

glyph.free = destroy_func(C.cairo_glyph_free)

M.allocate_text_clusters = ref_func(C.cairo_text_cluster_allocate, C.cairo_text_cluster_free)

local cluster = {}

cluster.free = destroy_func(C.cairo_text_cluster_free)

map('CAIRO_TEXT_CLUSTER_FLAG_', {
	'BACKWARD',
})

map('CAIRO_FONT_SLANT_', {
	'NORMAL',
	'ITALIC',
	'OBLIQUE',
})

map('CAIRO_FONT_WEIGHT_', {
	'NORMAL',
	'BOLD',
})

map('CAIRO_SUBPIXEL_ORDER_', {
	'DEFAULT',
	'RGB',
	'BGR',
	'VRGB',
	'VBGR',
})

map('CAIRO_HINT_STYLE_', {
	'DEFAULT',
	'NONE',
	'SLIGHT',
	'MEDIUM',
	'FULL',
})

map('CAIRO_HINT_METRICS_', {
	'DEFAULT',
	'OFF',
	'ON',
})

M.font_options = ref_func(C.cairo_font_options_create, C.cairo_font_options_destroy)

local fopt = {}

fopt.copy = ref_func(C.cairo_font_options_copy, C.cairo_font_options_destroy)
fopt.free = destroy_func(C.cairo_font_options_destroy)
fopt.status = C.cairo_font_options_status
fopt.status_message = status_message
fopt.check = check
fopt.merge = C.cairo_font_options_merge
fopt.equal = bool_func(C.cairo_font_options_equal)
fopt.hash = C.cairo_font_options_hash
fopt.antialias = getset_func(
	C.cairo_font_options_get_antialias,
	C.cairo_font_options_set_antialias, 'CAIRO_ANTIALIAS_')
fopt.subpixel_order = getset_func(
	C.cairo_font_options_get_subpixel_order,
	C.cairo_font_options_set_subpixel_order, 'CAIRO_SUBPIXEL_ORDER_')
fopt.hint_style = getset_func(
	C.cairo_font_options_get_hint_style,
	C.cairo_font_options_set_hint_style, 'CAIRO_HINT_STYLE_')
fopt.hint_metrics = getset_func(
	C.cairo_font_options_get_hint_metrics,
	C.cairo_font_options_set_hint_metrics, 'CAIRO_HINT_METRICS_')

cr.font_size = C.cairo_set_font_size
cr.font_matrix = getset_func(mtout_getfunc(C.cairo_get_font_matrix), C.cairo_set_font_matrix)
cr.font_options = getset_func(foptout_getfunc(C.cairo_get_font_options), C.cairo_set_font_options)
cr.font_face = getset_func(C.cairo_get_font_face, function(cr, family, slant, weight)
	if type(family) == 'string' then
		C.cairo_select_font_face(cr, family,
			X('CAIRO_FONT_SLANT_', slant or 'normal'),
			X('CAIRO_FONT_WEIGHT_', weight or 'normal'))
	else
		C.cairo_set_font_face(cr, family) --in fact: cairo_font_face_t
	end
end)
cr.scaled_font = getset_func(C.cairo_get_scaled_font, C.cairo_set_scaled_font) --weak ref
cr.show_text = C.cairo_show_text
cr.show_glyphs = C.cairo_show_glyphs
cr.show_text_glyphs = function(cr, s, slen, glyphs, num_glyphs, clusters, num_clusters, cluster_flags)
	C.cairo_show_text_glyphs(cr, s, slen or #s, glyphs, num_glyphs, clusters, num_clusters,
		cluster_flags and X('CAIRO_TEXT_CLUSTER_FLAG_', cluster_flags) or 0)
end
cr.text_path = C.cairo_text_path
cr.glyph_path = C.cairo_glyph_path
cr.text_extents = texout2_func(C.cairo_text_extents)
cr.glyph_extents = texout3_func(C.cairo_glyph_extents)
cr.font_extents = fexout_func(C.cairo_font_extents)

local face = {}

face.ref = ref_func(C.cairo_font_face_reference)
face.unref = destroy_func(C.cairo_font_face_destroy)
face.free = free
face.refcount = C.cairo_font_face_get_reference_count
face.status = C.cairo_font_face_status
face.status_message = status_message
face.check = check

map('CAIRO_FONT_TYPE_', {
	'TOY',
	'FT',
	'WIN32',
	'QUARTZ',
	'USER',
})

face.type = getflag_func(C.cairo_font_face_get_type, 'CAIRO_FONT_TYPE_')
face.scaled_font = ref_func(function(face, mt, ctm, fopt)
	--cairo crashes if any of these is null
	assert(mt ~= nil)
	assert(ctm ~= nil)
	assert(fopt ~= nil)
	return C.cairo_scaled_font_create(face, mt, ctm, fopt)
end, C.cairo_scaled_font_destroy)

local sfont = {}

sfont.ref = ref_func(C.cairo_scaled_font_reference, C.cairo_scaled_font_destroy)
sfont.unref = destroy_func(C.cairo_scaled_font_destroy)
sfont.free = free
sfont.refcount = C.cairo_scaled_font_get_reference_count
sfont.status = C.cairo_scaled_font_status
sfont.status_message = status_message
sfont.check = check
sfont.type = getflag_func(C.cairo_scaled_font_get_type, 'CAIRO_FONT_TYPE_')
sfont.extents = fexout_func(C.cairo_scaled_font_extents)
sfont.text_extents = texout2_func(C.cairo_scaled_font_text_extents)
sfont.glyph_extents = texout3_func(C.cairo_scaled_font_glyph_extents)

local glyphs_buf = ffi.new'cairo_glyph_t*[1]'
local num_glyphs_buf = ffi.new'int[1]'
local clusters_buf = ffi.new'cairo_text_cluster_t*[1]'
local num_clusters_buf = ffi.new'int[1]'
local cluster_flags_buf = ffi.new'cairo_text_cluster_flags_t[1]'

function sfont.text_to_glyphs(sfont, x, y, s, slen, glyphs, num_glyphs, clusters, num_clusters)
	glyphs_buf[0] = glyphs --optional: if nil, cairo allocates it
	num_glyphs_buf[0] = num_glyphs or 0
	clusters_buf[0] = clusters --optional: if nil, cairo allocates it
	num_clusters_buf[0] = num_clusters or 0
	local status = C.cairo_scaled_font_text_to_glyphs(
		sfont, x, y, s, slen or #s,
		glyphs_buf, num_glyphs_buf,
		clusters_buf, num_clusters_buf, cluster_flags_buf
	)
	if status == 0 then
		local glyphs = glyphs or ffi.gc(glyphs_buf[0], C.cairo_glyph_free)
		local clusters = clusters or ffi.gc(clusters_buf[0], C.cairo_text_cluster_free)
		return
			glyphs, num_glyphs_buf[0],
			clusters, num_clusters_buf[0],
			cluster_flags_buf[0] ~= 0 and X('CAIRO_TEXT_CLUSTER_FLAG_', tonumber(cluster_flags_buf[0])) or nil
	else
		return nil, M.status_message(status), status
	end
end

sfont.font_face = C.cairo_scaled_font_get_font_face --weak ref
sfont.font_matrix = mtout_func(C.cairo_scaled_font_get_font_matrix)
sfont.ctm = mtout_func(C.cairo_scaled_font_get_ctm)
sfont.scale_matrix = mtout_func(C.cairo_scaled_font_get_scale_matrix)
sfont.font_options = foptout_func(C.cairo_scaled_font_get_font_options)

function M.toy_font_face(family, slant, weight)
	return ffi.gc(
		C.cairo_toy_font_face_create(family,
			X('CAIRO_FONT_SLANT_', slant),
			X('CAIRO_FONT_WEIGHT_', weight)
	), C.cairo_font_face_destroy)
end

face.family = str_func(C.cairo_toy_font_face_get_family)
face.slant = getflag_func(C.cairo_toy_font_face_get_slant, 'CAIRO_FONT_SLANT_')
face.weight = getflag_func(C.cairo_toy_font_face_get_weight, 'CAIRO_FONT_WEIGHT_')

M.user_font_face = ref_func(C.cairo_user_font_face_create, C.cairo_font_face_destroy)

face.init_func = getset_func(
	C.cairo_user_font_face_get_init_func,
	C.cairo_user_font_face_set_init_func)

face.render_glyph_func = getset_func(
	C.cairo_user_font_face_get_render_glyph_func,
	C.cairo_user_font_face_set_render_glyph_func)

face.text_to_glyphs_func = getset_func(
	C.cairo_user_font_face_get_text_to_glyphs_func,
	C.cairo_user_font_face_set_text_to_glyphs_func)

face.unicode_to_glyph_func = getset_func(
	C.cairo_user_font_face_get_unicode_to_glyph_func,
	C.cairo_user_font_face_set_unicode_to_glyph_func)

cr.has_current_point = bool_func(C.cairo_has_current_point)
cr.current_point = d2out_func(C.cairo_get_current_point)
cr.target = C.cairo_get_target --weak ref
cr.group_target = C.cairo_get_group_target --weak ref

map('CAIRO_PATH_', {
	'MOVE_TO',
	'LINE_TO',
	'CURVE_TO',
	'CLOSE_PATH',
})

cr.copy_path = ref_func(C.cairo_copy_path, C.cairo_path_destroy)
cr.copy_path_flat = ref_func(C.cairo_copy_path, C.cairo_path_destroy)
cr.append_path = C.cairo_append_path

local path = {}

path.free = destroy_func(C.cairo_path_destroy)

local path_node_types = {
	[C.CAIRO_PATH_MOVE_TO] = 'move_to',
	[C.CAIRO_PATH_LINE_TO] = 'line_to',
	[C.CAIRO_PATH_CURVE_TO] = 'curve_to',
	[C.CAIRO_PATH_CLOSE_PATH] = 'close_path',
}

function path.dump(p)
	print(string.format('cairo_path_t (length = %d, status = %s)',
		p.num_data, M.status_message(p.status)))
	local i = 0
	while i < p.num_data do
		local d = p.data[i]
		print('', path_node_types[tonumber(d.header.type)])
		i = i + 1
		for j = 1, d.header.length-1 do
			local d = p.data[i]
			print('', '', string.format('%g, %g', d.point.x, d.point.y))
			i = i + 1
		end
	end
end

function path.equal(p1, p2)
	if not ffi.istype('cairo_path_t', p2) then return false end
	if p1.num_data ~= p2.num_data then return false end
	for i = 0, p1.num_data-1 do
		if p1.data[i].e1 ~= p2.data[i].e1
		or p1.data[i].e2 ~= p2.data[i].e2
		then return false end
	end
end

M.status_message = str_func(C.cairo_status_to_string)

local dev = {}

dev.ref = ref_func(C.cairo_device_reference, C.cairo_device_destroy)

map('CAIRO_DEVICE_TYPE_', {
	'DRM',
	'GL',
	'SCRIPT',
	'XCB',
	'XLIB',
	'XML',
	'COGL',
	'WIN32',
	'INVALID',
})

dev.type = getflag_func(C.cairo_device_get_type, 'CAIRO_DEVICE_TYPE_')
dev.status = C.cairo_device_status
dev.status_message = status_message
dev.check = check
dev.acquire = status_func(C.cairo_device_acquire)
dev.release = C.cairo_device_release
dev.flush = C.cairo_device_flush
dev.finish = C.cairo_device_finish
dev.unref = destroy_func(C.cairo_device_destroy)
dev.free = free
dev.refcount = C.cairo_device_get_reference_count

local sr = {}

sr.context = ref_func(C.cairo_create, C.cairo_destroy)

sr.similar_surface = ref_func(function(sr, content, w, h)
	return C.cairo_surface_create_similar(sr, X('CAIRO_CONTENT_', content), w, h)
end, C.cairo_surface_destroy)

sr.similar_image_surface = ref_func(function(sr, fmt, w, h)
	local fmt = M.cairo_format(fmt)
	return C.cairo_surface_create_similar_image(sr, X('CAIRO_FORMAT_', fmt), w, h)
end, C.cairo_surface_destroy)

sr.map_to_image = function(sr, x, y, w, h)
	local isr = C.cairo_surface_map_to_image(sr, set_int_rect(x, y, w, h))
	return ffi.gc(isr, function(isr)
		C.cairo_surface_unmap_image(sr, isr)
	end)
end

sr.unmap_image = function(sr, isr)
	ffi.gc(isr, nil)
	C.cairo_surface_unmap_image(sr, isr)
end

sr.sub = ref_func(C.cairo_surface_create_for_rectangle, C.cairo_surface_destroy)

map('CAIRO_SURFACE_OBSERVER_', {
	'NORMAL',
	'RECORD_OPERATIONS',
})

sr.observer_surface = function(sr, mode)
	local osr = C.cairo_surface_create_observer(sr, X('CAIRO_SURFACE_OBSERVER_', mode))
	return ffi.gc(osr, C.cairo_surface_destroy)
end

sr.add_paint_callback = C.cairo_surface_observer_add_paint_callback
sr.add_mask_callback = C.cairo_surface_observer_add_mask_callback
sr.add_fill_callback = C.cairo_surface_observer_add_fill_callback
sr.add_stroke_callback = C.cairo_surface_observer_add_stroke_callback
sr.add_glyphs_callback = C.cairo_surface_observer_add_glyphs_callback
sr.add_flush_callback = C.cairo_surface_observer_add_flush_callback
sr.add_finish_callback = C.cairo_surface_observer_add_finish_callback
sr.print = C.cairo_surface_observer_print
sr.elapsed = C.cairo_surface_observer_elapsed

dev.print = C.cairo_device_observer_print
dev.elapsed = C.cairo_device_observer_elapsed
dev.paint_elapsed = C.cairo_device_observer_paint_elapsed
dev.mask_elapsed = C.cairo_device_observer_mask_elapsed
dev.fill_elapsed = C.cairo_device_observer_fill_elapsed
dev.stroke_elapsed = C.cairo_device_observer_stroke_elapsed
dev.glyphs_elapsed = C.cairo_device_observer_glyphs_elapsed

sr.ref = ref_func(C.cairo_surface_reference, C.cairo_surface_destroy)
sr.finish = C.cairo_surface_finish
sr.unref = destroy_func(C.cairo_surface_destroy)
sr.free = free

sr.device = ptr_func(C.cairo_surface_get_device) --weak ref
sr.refcount = C.cairo_surface_get_reference_count
sr.status = C.cairo_surface_status
sr.status_message = status_message
sr.check = check

map('CAIRO_SURFACE_TYPE_', {
	'IMAGE',
	'PDF',
	'PS',
	'XLIB',
	'XCB',
	'GLITZ',
	'QUARTZ',
	'WIN32',
	'BEOS',
	'DIRECTFB',
	'SVG',
	'OS2',
	'WIN32_PRINTING',
	'QUARTZ_IMAGE',
	'SCRIPT',
	'QT',
	'RECORDING',
	'VG',
	'GL',
	'DRM',
	'TEE',
	'XML',
	'SKIA',
	'SUBSURFACE',
	'COGL',
})

sr.type = getflag_func(C.cairo_surface_get_type, 'CAIRO_SURFACE_TYPE_')
sr.content = getflag_func(C.cairo_surface_get_content, 'CAIRO_CONTENT_')

sr.save_png = status_func(function(self, arg1, ...)
	if type(arg1) == 'string' then
		return C.cairo_surface_write_to_png(self, arg1, ...)
	else
		return C.cairo_surface_write_to_png_stream(self, arg1, ...)
	end
end)

local data_buf = ffi.new'void*[1]'
local len_buf = ffi.new'unsigned long[1]'
sr.mime_data = function(sr, mime_type, data, len, destroy, closure)
	if data then
		return ret_status(C.cairo_surface_set_mime_data(sr, mime_type, data, len, destroy, closure))
	else
		C.cairo_surface_get_mime_data(sr, mime_type, data_buf, len_buf)
		return data_buf[0], len_buf[0]
	end
end

sr.supports_mime_type = bool_func(C.cairo_surface_supports_mime_type)

sr.font_options = foptout_func(C.cairo_surface_get_font_options)
sr.flush = C.cairo_surface_flush

sr.mark_dirty = function(sr, x, y, w, h)
	if x then
		C.cairo_surface_mark_dirty_rectangle(sr, x, y, w, h)
	else
		C.cairo_surface_mark_dirty(sr)
	end
end

sr.device_offset = getset_func(
	d2out_func(C.cairo_surface_get_device_offset),
	           C.cairo_surface_set_device_offset)
sr.fallback_resolution = getset_func(
	d2out_func(C.cairo_surface_get_fallback_resolution),
	           C.cairo_surface_set_fallback_resolution)

sr.copy_page = C.cairo_surface_copy_page
sr.show_page = C.cairo_surface_show_page
sr.has_show_text_glyphs = bool_func(C.cairo_surface_has_show_text_glyphs)

M.image_surface = function(fmt, w, h)
	if type(fmt) == 'table' then
		local bmp = fmt
		local fmt = M.cairo_format(bmp.format)
		local sr = C.cairo_image_surface_create_for_data(
			bmp.data, X('CAIRO_FORMAT_', fmt), bmp.w, bmp.h, bmp.stride)
		return ffi.gc(sr, function(sr)
			local _ = bmp.data --pin it
			C.cairo_surface_destroy(sr)
		end)
	else
		local fmt = M.cairo_format(fmt)
		return ffi.gc(
			C.cairo_image_surface_create(X('CAIRO_FORMAT_', fmt), w, h),
			C.cairo_surface_destroy)
	end
end

M.stride = function(fmt, width)
	local fmt = M.cairo_format(fmt)
	return C.cairo_format_stride_for_width(X('CAIRO_FORMAT_', fmt), width)
end

sr.data = _C.cairo_image_surface_get_data
sr.format = getflag_func(_C.cairo_image_surface_get_format, 'CAIRO_FORMAT_')
sr.width = _C.cairo_image_surface_get_width
sr.height = _C.cairo_image_surface_get_height
sr.stride = _C.cairo_image_surface_get_stride

M.load_png = ref_func(function(arg1, ...)
	if type(arg1) == 'string' then
		return C.cairo_image_surface_create_from_png(arg1, ...)
	else
		return C.cairo_image_surface_create_from_png_stream(arg1, ...)
	end
end, C.cairo_surface_destroy)

local r = ffi.new'cairo_rectangle_t'
function M.recording_surface(content, x, y, w, h)
	if x then
		r.x = x
		r.y = y
		r.width = w
		r.height = h
	end
	return ffi.gc(
		C.cairo_recording_surface_create(
			X('CAIRO_CONTENT_', content),
			x and r or nil
		), C.cairo_surface_destroy)
end

sr.ink_extents = d4out_func(C.cairo_recording_surface_ink_extents)
sr.recording_extents = function(sr)
	if C.cairo_recording_surface_get_extents(sr, r) == 1 then
		return unpack_rect(r)
	end
end

M.raster_source_pattern = function(udata, content, w, h)
	local patt = C.cairo_pattern_create_raster_source(udata, X('CAIRO_CONTENT_', content), w, h)
	return ffi.gc(patt, C.cairo_pattern_destroy)
end

local patt = {}

patt.callback_data = getset_func(
	C.cairo_raster_source_pattern_get_callback_data,
	C.cairo_raster_source_pattern_set_callback_data)

local acquire_buf = ffi.new'cairo_raster_source_acquire_func_t[1]'
local release_buf = ffi.new'cairo_raster_source_release_func_t[1]'
patt.acquire_function = function(patt, acquire, release)
	if acquire then
		C.cairo_raster_source_pattern_set_acquire(patt, acquire, release)
	else
		C.cairo_raster_source_pattern_get_acquire(patt, acquire_buf, release_buf)
		return ptr(acquire_buf[0]), ptr(release_buf[0])
	end
end

patt.snapshot_function = getset_func(
	C.cairo_raster_source_pattern_get_snapshot,
	C.cairo_raster_source_pattern_set_snapshot)

patt.copy_function = getset_func(
	C.cairo_raster_source_pattern_get_copy,
	C.cairo_raster_source_pattern_set_copy)

patt.finish_function = getset_func(
	C.cairo_raster_source_pattern_get_finish,
	C.cairo_raster_source_pattern_set_finish)

M.color_pattern = ref_func(function(r, g, b, a)
	return C.cairo_pattern_create_rgba(r, g, b, a or 1)
end, C.cairo_pattern_destroy)
M.surface_pattern = ref_func(C.cairo_pattern_create_for_surface, C.cairo_pattern_destroy)
M.linear_gradient = ref_func(C.cairo_pattern_create_linear, C.cairo_pattern_destroy)
M.radial_gradient = ref_func(C.cairo_pattern_create_radial, C.cairo_pattern_destroy)
M.mesh_pattern = ref_func(C.cairo_pattern_create_mesh, C.cairo_pattern_destroy)

patt.ref = ref_func(C.cairo_pattern_reference, C.cairo_pattern_destroy)
patt.unref = destroy_func(C.cairo_pattern_destroy)
patt.free = free
patt.refcount = C.cairo_pattern_get_reference_count
patt.status = C.cairo_pattern_status
patt.status_message = status_message
patt.check = check

map('CAIRO_PATTERN_TYPE_', {
	'SOLID',
	'SURFACE',
	'LINEAR',
	'RADIAL',
	'MESH',
	'RASTER_SOURCE',
})

patt.type = getflag_func(C.cairo_pattern_get_type, 'CAIRO_PATTERN_TYPE_')

patt.add_color_stop = function(patt, offset, r, g, b, a)
	C.cairo_pattern_add_color_stop_rgba(patt, offset, r, g, b, a or 1)
end

patt.begin_patch = C.cairo_mesh_pattern_begin_patch
patt.end_patch = C.cairo_mesh_pattern_end_patch

patt.curve_to = C.cairo_mesh_pattern_curve_to
patt.line_to = C.cairo_mesh_pattern_line_to
patt.move_to = C.cairo_mesh_pattern_move_to

patt.control_point = function(patt, patch_num, point_num, x, y)
	if x then
		C.cairo_mesh_pattern_set_control_point(patt, patch_num, point_num, x) --in fact: patt, point_num, x, y
	else
		check_status(C.cairo_mesh_pattern_get_control_point(patt, patch_num, point_num, d1, d2))
		return d1[0], d2[0]
	end
end

patt.corner_color = function(patt, patch_num, corner_num, r, g, b, a)
	if r then
		C.cairo_mesh_pattern_set_corner_color_rgba(patt, patch_num, corner_num, r, g, b or 1) --in fact: patt, corner_num, r, g, b, a
	else
		check_status(C.cairo_mesh_pattern_get_corner_color_rgba(patt, patch_num, corner_num, d1, d2, d3, d4))
		return d1[0], d2[0], d3[0], d4[0]
	end
end

patt.matrix = getset_func(mtout_getfunc(C.cairo_pattern_get_matrix), C.cairo_pattern_set_matrix)

map('CAIRO_EXTEND_', {
	'NONE',
	'REPEAT',
	'REFLECT',
	'PAD',
})

patt.extend = getset_func(C.cairo_pattern_get_extend, C.cairo_pattern_set_extend, 'CAIRO_EXTEND_')

map('CAIRO_FILTER_', {
	'FAST',
	'GOOD',
	'BEST',
	'NEAREST',
	'BILINEAR',
	'GAUSSIAN',
})

patt.filter = getset_func(C.cairo_pattern_get_filter, C.cairo_pattern_set_filter, 'CAIRO_FILTER_')

patt.color = d4out_func(function(...)
	check_status(C.cairo_pattern_get_rgba(...))
end)

local sr_buf = ffi.new'cairo_surface_t*[1]'
patt.surface = function(patt)
	check_status(C.cairo_pattern_get_surface(patt, sr_buf))
	return ptr(sr_buf[0])
end

local c = ffi.new'int[1]'
patt.color_stop = function(patt, i)
	if i == '#' then
		check_status(C.cairo_pattern_get_color_stop_count(patt, c))
		return c[0]
	else
		check_status(C.cairo_pattern_get_color_stop_rgba(patt, i, d1, d2, d3, d4, d5))
		return d1[0], d2[0], d3[0], d4[0], d5[0] --offset, r, g, b, a
	end
end

patt.linear_points = function(patt)
	check_status(C.cairo_pattern_get_linear_points(patt, d1, d1, d2, d2))
	return d1[0], d2[0], d3[0], d4[0]
end

patt.radial_circles = function(patt)
	check_status(C.cairo_pattern_get_radial_circles(patt, d1, d2, d3, d4, d5, d6))
	return d1[0], d2[0], d3[0], d4[0], d5[0], d6[0] --x1, y1, r1, x2, y2, r2
end

local c = ffi.new'unsigned int[1]'
patt.patch_count = function(patt)
	check_status(C.cairo_mesh_pattern_get_patch_count(patt, c))
	return tonumber(c[0])
end

patt.path = ptr_func(C.cairo_mesh_pattern_get_path) --weak ref? doc doesn't say

local mat_cons = ffi.typeof'cairo_matrix_t'
M.matrix = function(arg1, ...)
	if not arg1 then --default constructor
		return mat_cons(1, 0, 0, 1, 0, 0)
	end
	return mat_cons(arg1, ...) --copy and value constructors from ffi
end

local mt = {}

mt.reset = function(mt, arg1, ...)
	if not arg1 then --default constructor
		return mt:reset(1, 0, 0, 1, 0, 0)
	elseif type(arg1) == 'number' then --value constructor
		C.cairo_matrix_init(mt, arg1, ...)
		return mt
	else --copy constructor
		ffi.copy(mt, arg1, ffi.sizeof(mt))
		return mt
	end
end
mt.translate = ret_self(C.cairo_matrix_translate)
mt.scale = function(mt, sx, sy) C.cairo_matrix_scale(mt, sx, sy or sx); return mt; end
mt.rotate = ret_self(C.cairo_matrix_rotate)
mt.invert = function(mt)
	check_status(C.cairo_matrix_invert(mt))
	return mt
end
mt.multiply = function(mt, mt1, mt2)
	if mt2 then
		C.cairo_matrix_multiply(mt, mt1, mt2)
	else
		C.cairo_matrix_multiply(mt, mt, mt1)
	end
	return mt
end
mt.distance = d2inout_func(C.cairo_matrix_transform_distance)
mt.point = d2inout_func(C.cairo_matrix_transform_point)

map('CAIRO_REGION_OVERLAP_', {
	'IN',
	'OUT',
	'PART',
})

M.region = ref_func(function(arg1, ...)
	if type(arg1) == 'cdata' then
		C.cairo_region_create_rectangles(arg1, ...)
	elseif arg1 then
		return C.cairo_region_create_rectangle(set_int_rect(arg1, ...))
	else
		C.cairo_region_create()
	end
end, C.cairo_region_destroy)

local rgn = {}

rgn.copy = ref_func(C.cairo_region_copy, C.cairo_region_destroy)
rgn.ref = C.cairo_region_reference
rgn.unref = destroy_func(C.cairo_region_destroy)
rgn.free = free
rgn.equal = bool_func(C.cairo_region_equal)
rgn.status = C.cairo_region_status
rgn.status_message = status_message
rgn.check = check

rgn.extents = function(rgn)
	C.cairo_region_get_extents(rgn, ir)
	return unpack_rect(ir)
end

rgn.num_rectangles = C.cairo_region_num_rectangles

rgn.rectangle = function(rgn, i)
	C.cairo_region_get_rectangle(rgn, i, ir)
	return unpack_rect(ir)
end

rgn.is_empty = bool_func(C.cairo_region_is_empty)

local overlap = {
	[C.CAIRO_REGION_OVERLAP_IN] = true,
	[C.CAIRO_REGION_OVERLAP_OUT] = false,
	[C.CAIRO_REGION_OVERLAP_PART] = 'partial',
}
function rgn.contains(x, y, w, h)
	if w then
		return overlap[C.cairo_region_contains_rectangle(rgn, set_int_rect(x, y, w, h))]
	else
		return overlap[C.cairo_region_contains_point(rgn, x, y)]
	end
end

rgn.ref = ref_func(C.cairo_region_reference, C.cairo_region_destroy)
rgn.translate = C.cairo_region_translate

local function op_func(rgn_func_name)
	local rgn_func = C['cairo_'..rgn_func_name]
	local rect_func = C['cairo_'..rgn_func_name..'_rectangle']
	return function(rgn, x, y, w, h)
		if type(x) == 'cdata' then
			check_status(rgn_func(rgn, x))
		else
			check_status(rect_func(rgn, set_int_rect(x, y, w, h)))
		end
	end
end
rgn.subtract  = op_func'region_subtract'
rgn.intersect = op_func'region_intersect'
rgn.union     = op_func'region_union'
rgn.xor       = op_func'region_xor'

M.debug_reset_static_data = C.cairo_debug_reset_static_data

--private APIs available only in our custom build

map('CAIRO_LCD_FILTER_', {
	'DEFAULT',
	'NONE',
	'INTRA_PIXEL',
	'FIR3',
	'FIR5',
})

map('CAIRO_ROUND_GLYPH_POS_', {
	'DEFAULT',
	'ON',
	'OFF',
})

fopt.lcd_filter = getset_func(
	_C._cairo_font_options_get_lcd_filter,
	_C._cairo_font_options_set_lcd_filter,
	'CAIRO_LCD_FILTER_')

fopt.round_glyph_positions = getset_func(
	_C._cairo_font_options_get_round_glyph_positions,
	_C._cairo_font_options_set_round_glyph_positions,
	'CAIRO_ROUND_GLYPH_POS_')

--additions to context

function cr:safe_transform(mt)
	if mt:invertible() then
		self:transform(mt)
	end
	return self
end

function cr:rotate_around(cx, cy, angle)
	self:translate(cx, cy)
	self:rotate(angle)
	return self:translate(-cx, -cy)
end

function cr:scale_around(cx, cy, ...)
	self:translate(cx, cy)
	self:scale(...)
	return self:translate(-cx, -cy)
end

local sm = M.matrix()
function cr:skew(ax, ay)
	sm:reset()
	sm.xy = math.tan(ax)
	sm.yx = math.tan(ay)
	return self:transform(sm)
end

--additions to surfaces

function sr:apply_alpha(alpha)
	if alpha >= 1 then return end
	local cr = self:context()
	cr:rgba(0, 0, 0, alpha)
	cr:operator'dest_in' --alphas are multiplied, dest. color is preserved
	cr:paint()
	cr:free()
end

local bpp = {
	argb32 = 32,
	rgb24 = 32,
	a8 = 8,
	a1 = 1,
	rgb16_565 = 16,
	rgb30 = 30,
}
function sr:bpp()
	return bpp[self:format()]
end


function sr:bitmap_format()
	return M.bitmap_format(self:format())
end

function sr:bitmap()
	return {
		data   = self:data(),
		format = self:bitmap_format(),
		w      = self:width(),
		h      = self:height(),
		stride = self:stride(),
	}
end

--additions to paths

local pi = math.pi
function cr:circle(cx, cy, r)
	self:new_sub_path()
	self:arc(cx, cy, r, 0, 2 * pi)
	self:close_path()
end

local mt0
function cr:ellipse(cx, cy, rx, ry, rotation)
	mt0 = self:matrix(nil, mt0)
	self:translate(cx, cy)
	if rotation then self:rotate(rotation) end
	self:scale(1, ry/rx)
	self:circle(0, 0, rx)
	self:matrix(mt0)
end

local function elliptic_arc_func(arc)
	return function(self, cx, cy, rx, ry, rotation, a1, a2)
		if rx == 0 or ry == 0 then
			if self:has_current_point() then
				self:line_to(cx, cy)
			end
		elseif rx ~= ry or (rotation and rotation ~= 0) then
			self:save()
			self:translate(cx, cy)
			self:rotate(rotation)
			self:scale(rx / ry, 1)
			arc(self, 0, 0, ry, a1, a2)
			self:restore()
		else
			arc(self, cx, cy, ry, a1, a2)
		end
	end
end
cr.elliptic_arc = elliptic_arc_func(cr.arc)
cr.elliptic_arc_negative = elliptic_arc_func(cr.arc_negative)

function cr:quad_curve_to(x1, y1, x2, y2)
	local x0, y0 = self:current_point()
	self:curve_to((x0 + 2 * x1) / 3,
					(y0 + 2 * y1) / 3,
					(x2 + 2 * x1) / 3,
					(y2 + 2 * y1) / 3,
					x2, y2)
end

function cr:rel_quad_curve_to(x1, y1, x2, y2)
	local x0, y0 = self:current_point()
	self:quad_curve_to(x0+x1, y0+y1, x0+x2, y0+y2)
end

--additions to matrices

function mt:transform(mt)
	return self:multiply(mt, self)
end

function mt:determinant()
	return self.xx * self.yy - self.yx * self.xy
end

function mt:invertible()
	local det = self:determinant()
	return det ~= 0 and det ~= 1/0 and det ~= -1/0
end

function mt:safe_transform(self, mt)
	if mt:invertible() then
		self:transform(mt)
	end
	return self
end

function mt:skew(ax, ay)
	local sm = M.matrix()
	sm.xy = math.tan(ax)
	sm.yx = math.tan(ay)
	return self:transform(sm)
end

function mt:rotate_around(cx, cy, angle)
	self:translate(cx, cy)
	self:rotate(angle)
	self:translate(-cx, -cy)
	return self
end

function mt:scale_around(cx, cy, ...)
	self:translate(cx, cy)
	self:scale(...)
	self:translate(-cx, -cy)
	return self
end

function mt:copy()
	return M.matrix(self)
end

function mt.tostring(mt)
	return string.format('[%12f%12f]\n[%12f%12f]\n[%12f%12f]',
		mt.xx, mt.yx, mt.xy, mt.yy, mt.x0, mt.y0)
end

function mt.equal(m1, m2)
	return type(m2) == 'cdata' and
		m1.xx == m2.xx and m1.yy == m2.yy and
		m1.xy == m2.xy and m1.yx == m2.yx and
		m1.x0 == m2.x0 and m1.y0 == m2.y0
end

--freetype extension

function M.ft_font_face(ft_face, load_flags)
	local ft = require'freetype'
	local key = ffi.new'cairo_user_data_key_t[1]'
	local face = ffi.gc(
		C.cairo_ft_font_face_create_for_ft_face(ft_face, load_flags or 0),
		C.cairo_font_face_destroy)
	local status = C.cairo_font_face_set_user_data(
		face, key, ft_face, ffi.cast('cairo_destroy_func_t', function()
			ft_face:free()
			ft_face.glyph.library:free()
		end))
	if status ~= 0 then
		C.cairo_font_face_destroy(face)
		ft_face:free()
		return nil, M.status_message(status), status
	end
	ft_face.glyph.library:ref()
	return face
end

local function synthesize_flag(bitmask)
	return function(face, enable)
		if enable == nil then
			return bit.band(C.cairo_ft_font_face_get_synthesize(face), bitmask) ~= 0
		elseif enable then
			C.cairo_ft_font_face_set_synthesize(face, bitmask)
		else
			C.cairo_ft_font_face_unset_synthesize(face, bitmask)
		end
	end
end
face.synthesize_bold = synthesize_flag(C.CAIRO_FT_SYNTHESIZE_BOLD)
face.synthesize_oblique = synthesize_flag(C.CAIRO_FT_SYNTHESIZE_OBLIQUE)

sfont.lock_face = _C.cairo_ft_scaled_font_lock_face
sfont.unlock_face = _C.cairo_ft_scaled_font_unlock_face

--pdf surfaces

enums['CAIRO_PDF_VERSION_'] = {
	[C.CAIRO_PDF_VERSION_1_4] = '1.4',
	[C.CAIRO_PDF_VERSION_1_5] = '1.5',
	['1.4'] = C.CAIRO_PDF_VERSION_1_4,
	['1.5'] = C.CAIRO_PDF_VERSION_1_5,
}
M.pdf_surface = ref_func(function(arg1, ...)
	if type(arg1) == 'string' then
		return C.cairo_pdf_surface_create(arg1, ...)
	else
		return C.cairo_pdf_surface_create_for_stream(arg1, ...)
	end
end, C.cairo_surface_destroy)

sr.pdf_version = setflag_func(_C.cairo_pdf_surface_restrict_to_version, 'CAIRO_PDF_VERSION_')

local function listout_func(func, ct, prefix)
	return func and function()
		local ibuf = ffi.new'int[1]'
		local vbuf = ffi.new(ffi.typeof('const $*[1]', ffi.typeof(ct)))
		func(vbuf, ibuf)
		local t = {}
		for i=0,ibuf[0]-1 do
			t[#t+1] = X(prefix, tonumber(vbuf[0][i]))
		end
		return t
	end
end

M.pdf_versions = listout_func(_C.cairo_pdf_get_versions, 'cairo_pdf_version_t', 'CAIRO_PDF_VERSION_')
sr.pdf_size = _C.cairo_pdf_surface_set_size

--ps surfaces

map('CAIRO_PS_LEVEL_', {2, 3})

M.ps_surface = ref_func(function(arg1, ...)
	if type(arg1) == 'string' then
		return C.cairo_ps_surface_create(arg1, ...)
	else
		return C.cairo_ps_surface_create_for_stream(arg1, ...)
	end
end, C.cairo_surface_destroy)

sr.ps_level = setflag_func(_C.cairo_ps_surface_restrict_to_level, 'CAIRO_PS_LEVEL_')
M.ps_levels = listout_func(_C.cairo_ps_get_levels, 'cairo_ps_level_t', 'CAIRO_PS_LEVEL_')
sr.ps_eps = getset_func(bool_func(_C.cairo_ps_surface_get_eps), _C.cairo_ps_surface_set_eps)
sr.ps_size = _C.cairo_ps_surface_set_size
sr.ps_dsc_comment = _C.cairo_ps_surface_dsc_comment
sr.ps_dsc_begin_setup = _C.cairo_ps_surface_dsc_begin_setup
sr.ps_dsc_begin_page_setup = _C.cairo_ps_surface_dsc_begin_page_setup

--svg surfaces

enums['CAIRO_SVG_VERSION_'] = {
	[C.CAIRO_SVG_VERSION_1_1] = '1.1',
	[C.CAIRO_SVG_VERSION_1_2] = '1.2',
	['1.1'] = C.CAIRO_SVG_VERSION_1_1,
	['1.2'] = C.CAIRO_SVG_VERSION_1_2,
}
M.svg_surface = ref_func(function(arg1, ...)
	if type(arg1) == 'string' then
		return C.cairo_svg_surface_create(arg1, ...)
	else
		return C.cairo_svg_surface_create_for_stream(arg1, ...)
	end
end, C.cairo_surface_destroy)

sr.svg_version = setflag_func(_C.cairo_svg_surface_restrict_to_version, 'CAIRO_SVG_VERSION_')
M.svg_versions = listout_func(_C.cairo_svg_get_versions, 'cairo_svg_version_t', 'CAIRO_SVG_VERSION_')

--metatype must come last

ffi.metatype('cairo_t', {__index = cr})
ffi.metatype('cairo_rectangle_list_t', {__index = rl})
ffi.metatype('cairo_glyph_t', {__index = glyph})
ffi.metatype('cairo_text_cluster_t', {__index = cluster})
ffi.metatype('cairo_font_options_t', {__index = fopt})
ffi.metatype('cairo_font_face_t', {__index = face})
ffi.metatype('cairo_scaled_font_t', {__index = sfont})
ffi.metatype('cairo_path_t', {__index = path})
ffi.metatype('cairo_device_t', {__index = dev})
ffi.metatype('cairo_surface_t', {__index = sr})
ffi.metatype('cairo_pattern_t', {__index = patt})
ffi.metatype('cairo_matrix_t', {__index = mt,
	__call = mt.point,
	__mul = function(mt1, mt2) return mt1:copy():multiply(mt2) end,
})
ffi.metatype('cairo_region_t', {__index = rgn})

ffi.metatype('cairo_text_extents_t', {__tostring = function(t)
	return string.format('bearing: (%d, %d), height: %d, advance: (%d, %d)',
		t.x_bearing, t.y_bearing, t.width, t.height, t.x_advance, t.y_advance)
end})

ffi.metatype('cairo_font_extents_t', {__tostring = function(t)
	return string.format('ascent: %d, descent: %d, height: %d, max_advance: (%d, %d)',
		t.ascent, t.descent, t.height, t.max_x_advance, t.max_y_advance)
end})

return M
