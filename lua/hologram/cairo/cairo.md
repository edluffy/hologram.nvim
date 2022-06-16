---
tagline: cairo graphics engine
---

## `local cairo = require'cairo'`

A lightweight ffi binding of the [cairo graphics] library.

[cairo graphics]:   http://cairographics.org/

## API

__NOTE:__ In the table below, `foo(val) /-> val` is a shortcut for saying
that `foo(val)` sets the value of foo and `foo() -> val` gets it.

__NOTE:__ flags can be passed as lowercase strings without prefix eg.
pass 'argb32' for `C.CAIRO_FORMAT_ARGB32` in `cairo.image_surface()`.

------------------------------------------------------------------- -------------------------------------------------------------------
__pixman surfaces__
`cairo.image_surface(fmt, w, h) -> sr`                              [create a pixman surface][cairo_image_surface_create]
`cairo.image_surface(bmp) -> sr`                                    [create a pixman surface given a][cairo_image_surface_create_for_data] [bitmap] (+)
`sr:bitmap() -> bmp`                                                get the image surface as a [bitmap]
`sr:data() -> data`                                                 [get the image surface pixel buffer][cairo_image_surface_get_data]
`sr:format() -> fmt`                                                [get the image surface format][cairo_image_surface_get_format]
`sr:bitmap_format() -> fmt`                                         get the image surface [bitmap] format
`sr:width() -> w`                                                   [get the image surface width][cairo_image_surface_get_width]
`sr:height() -> h`                                                  [get the image surface height][cairo_image_surface_get_height]
`sr:stride() -> stride`                                             [get the image surface stride][cairo_image_surface_get_stride]
`sr:bpp() -> bpp`                                                   get the image surface bits-per-pixel
__recording surfaces__
`cairo.recording_surface(content[, x, y, w, h]) -> sr`              [create a recording surface][cairo_recording_surface_create]
`sr:ink_extents() -> x, y, w, h`                                    [get recording surface ink extents][cairo_recording_surface_ink_extents]
`sr:recording_extents() -> x, y, w, h | nil`                        [get recording surface extents][cairo_recording_surface_get_extents]
__PDF surfaces__
`cairo.pdf_surface(filename, w, h) -> sr`                           [create a PDF surface for a filename][cairo_pdf_surface_create]
`cairo.pdf_surface(write_func, arg, w, h) -> sr`                    [create a PDF surface with a write function][cairo_pdf_surface_create_for_stream]
`cairo.pdf_versions() -> {ver1, ...}`                               [get available spec versions][cairo_pdf_get_versions]
`sr:pdf_version(ver)`                                               [restrict to spec version][cairo_pdf_surface_restrict_to_version]
`sr:pdf_size(w, h)`                                                 [set page size][cairo_pdf_surface_set_size]
__PS surfaces__
`cairo.ps_surface(filename, w, h) -> sr`                            [create a PS surface for a filename][cairo_ps_surface_create]
`cairo.ps_surface(write_func, arg, w, h) -> sr`                     [create a PS surface with a write function][cairo_ps_surface_create_for_stream]
`cairo.ps_levels() -> {level1, ...}`                                [get available levels][cairo_ps_get_levels]
`sr:ps_level(level)`                                                [restrict to level][cairo_ps_surface_restrict_to_level]
`sr:ps_eps(t|f) /-> t|f`                                            [get/set Encapsulated PostScript][cairo_ps_surface_set_eps]
`sr:ps_size(w, h)`                                                  [set page size][cairo_ps_surface_set_size]
`sr:ps_dsc_comment(s)`                                              [add comment][cairo_ps_surface_dsc_comment]
`sr:ps_dsc_begin_setup()`                                           [comments go to Setup section][cairo_ps_surface_dsc_begin_setup]
`sr:ps_dsc_begin_page_setup()`                                      [comments go to PageSetup section][cairo_ps_surface_dsc_begin_page_setup]
__SVG surfaces__
`cairo.svg_surface(filename, w, h) -> sr`                           [create a SVG surface for a filename][cairo_svg_surface_create]
`cairo.svg_surface(write_func, arg, w, h) -> sr`                    [create a SVG surface with a write function][cairo_svg_surface_create_for_stream]
`cairo.svg_versions() -> {ver1, ...}`                               [get available spec versions][cairo_svg_get_versions]
`sr:svg_version(ver)`                                               [restrict to spec version][cairo_svg_surface_restrict_to_version]
__PNG support__
`cairo.load_png(filename) -> sr`                                    [create a pixman surface from a png file][cairo_image_surface_create_from_png]
`cairo.load_png(read_func, arg) -> sr`                              [create a pixman surface from a png stream][cairo_image_surface_create_from_png_stream]
`sr:save_png(filename) -> true | nil,err,status`                    [write surface to png file][cairo_surface_write_to_png]
`sr:save_png(write_func, arg) -> true | nil,err,status`             [write surface to png stream][cairo_surface_write_to_png_stream]
__all surfaces__
`sr:sub(x, y, w, h) -> sr`                                          [create a sub-surface][cairo_surface_create_for_rectangle]
`sr:similar_surface(content, w, h) -> sr`                           [create a similar surface][cairo_surface_create_similar]
`sr:similar_image_surface(fmt, w, h) -> sr`                         [create a similar image surface][cairo_surface_create_similar_image]
`sr:type() -> type`                                                 [get surface type][cairo_surface_get_type]
`sr:content() -> content`                                           [get surface content type][cairo_surface_get_content]
`sr:flush()`                                                        [perform any pending drawing commands][cairo_surface_flush]
`sr:mark_dirty([x, y, w, h])`                                       [re-read any cached areas of (parts of) the surface][cairo_surface_mark_dirty]
`sr:fallback_resolution(xppi, yppi) /-> xppi, yppi`                 [get/set fallback resolution][cairo_surface_set_fallback_resolution]
`sr:mime_data(type, data, len[, destroy[, arg]])`                   [set mime data][cairo_surface_set_mime_data]
`sr:mime_data(type) -> data, len`                                   [get mime data][cairo_surface_get_mime_data]
`sr:supports_mime_type(type) -> t|f`                                [check if the surface supports a mime type][cairo_surface_supports_mime_type]
`sr:map_to_image([x, y, w, h]) -> image_sr`                         [get an image surface for modifying the backing store][cairo_surface_map_to_image]
`sr:unmap_image(image_sr)`                                          [upload image to backing store and unmap][cairo_surface_unmap_image]
`sr:finish()`                                                       [finish the surface][cairo_surface_finish]
`sr:apply_alpha(a)`                                                 make the surface transparent
__drawing contexts__
`sr:context() -> cr`                                                [create a drawing context on a surface][cairo_create]
`cr:save()`                                                         [push context state to stack][cairo_save]
`cr:restore()`                                                      [pop context state from stack][cairo_restore]
__sources__
`cr:rgb(r, g, b)`                                                   [set a RGB color as source][cairo_set_source_rgb]
`cr:rgba(r, g, b, a)`                                               [set a RGBA color as source][cairo_set_source_rgba]
`cr:source(patt | sr, [x, y]) /-> patt`                             [get/set a pattern or surface as source][cairo_set_source]
__compositing__
`cr:operator(operator) /-> operator`                                [get/set the compositing operator][cairo_set_operator]
`cr:mask(patt | sr[, x, y])`                                        [draw using a pattern's (or surface's) alpha as mask][cairo_mask]
`cr:paint()`                                                        [paint the current source][cairo_paint]
`cr:paint_with_alpha(alpha)`                                        [paint the current source with transparency][cairo_paint_with_alpha]
__groups__
`cr:push_group([content])`                                          [redirect drawing to an intermediate surface][cairo_push_group]
`cr:pop_group() -> patt`                                            [terminate the redirection and return it as pattern][cairo_pop_group]
`cr:pop_group_to_source()`                                          [terminate the redirection and install it as pattern][cairo_pop_group_to_source]
`cr:target() -> sr`                                                 [get the ultimate destination surface][cairo_get_target]
`cr:group_target() -> sr`                                           [get the current destination surface][cairo_get_group_target]
__transformations__
`cr:translate(x, y) -> cr`                                          [translate the user-space origin][cairo_translate]
`cr:scale(sx[, sy]) -> cr`                                          [scale the user-space][cairo_scale]
`cr:scale_around(cx, cy, sx[, sy]) -> cr`                           scale the user-space arount a point
`cr:rotate(angle) -> cr`                                            [rotate the user-space][cairo_rotate]
`cr:rotate_around(cx, cy, angle) -> cr`                             rotate the user-space around a point
`cr:skew(ax, ay) -> cr`                                             skew the user-space
`cr:transform(mt) -> cr`                                            [transform the user-space][cairo_transform]
`cr:safe_transform(mt) -> cr`                                       transform the user-space if the matrix is invertible
`cr:matrix(mt[, out_mt]) /-> mt`                                    [get/set the CTM][cairo_set_matrix]
`cr:identity_matrix() -> cr`                                        [reset the CTM][cairo_identity_matrix]
`cr:user_to_device(x, y) -> x, y`                                   [user to device (point)][cairo_user_to_device]
`cr:user_to_device_distance(x, y) -> x, y`                          [user to device (distance)][cairo_user_to_device_distance]
`cr:device_to_user(x, y) -> x, y`                                   [device to user (point)][cairo_device_to_user]
`cr:device_to_user_distance(x, y) -> x, y`                          [device to user (distance)][cairo_device_to_user_distance]
__paths__
`cr:new_path()`                                                     [clear the current path][cairo_new_path]
`cr:new_sub_path()`                                                 [create a sub-path][cairo_new_sub_path]
`cr:move_to(x, y)`                                                  [move the current point][cairo_move_to]
`cr:line_to(x, y)`                                                  [add a line to the current path][cairo_line_to]
`cr:curve_to(x1, y1, x2, y2, x3, y3)`                               [add a cubic bezier to the current path][cairo_curve_to]
`cr:quad_curve_to(x1, y1, x2, y2)`                                  add a quad bezier to the current path
`cr:arc(cx, cy, r, a1, a2)`                                         [add an arc to the current path][cairo_arc]
`cr:arc_negative(cx, cy, r, a1, a2)`                                [add a negative arc to the current path][cairo_arc_negative]
`cr:circle(cx, cy, r)`                                              add a circle to the current path
`cr:ellipse(cx, cy, rx, ry, rotation)`                              add an ellipse to the current path
`cr:elliptic_arc(cx, cy, rx, ry, rotation, a1, a2)`                 add an elliptic arc to the current path
`cr:elliptic_arc_negative(cx, cy, rx, ry, rotation, a1, a2)`        add a negative elliptic arc to the current path
`cr:rel_move_to(x, y)`                                              [move the current point][cairo_rel_move_to]
`cr:rel_line_to(x, y)`                                              [add a line to the current path][cairo_rel_line_to]
`cr:rel_curve_to(x1, y1, x2, y2, x3, y3)`                           [add a cubic bezier to the current path][cairo_rel_curve_to]
`cr:rel_quad_curve_to(x1, y1, x2, y2)`                              add a quad bezier to the current path
`cr:rectangle(x, y, w, h)`                                          [add a rectangle to the current path][cairo_rectangle]
`cr:close_path()`                                                   [close current path][cairo_close_path]
`cr:copy_path() -> path`                                            [copy current path to a path object][cairo_copy_path]
`cr:copy_path_flat() -> path`                                       [copy current path flattened][cairo_copy_path_flat]
`path:dump()`                                                       pretty print path instructions
`path:equal(other_path) -> t|f`                                     compare paths
`cr:append_path(path)`                                              [append a path to current path][cairo_append_path]
`cr:path_extents() -> x1, y1, x2, y2`                               [get the bouding box of the current path][cairo_path_extents]
`cr:current_point() -> x, y`                                        [get the current point][cairo_get_current_point]
`cr:has_current_point() -> t|f`                                     [check if there's a current point][cairo_has_current_point]
__filling__
`cr:fill()`                                                         [fill the current path and discard it][cairo_fill]
`cr:fill_preserve()`                                                [fill and keep the path][cairo_fill_preserve]
`cr:fill_extents() -> x1, y1, x2, y2`                               [get the bounding box of filling the current path][cairo_fill_extents]
`cr:in_fill(x, y) -> t|f`                                           [hit-test the fill area][cairo_in_fill]
`cr:fill_rule(rule]) /-> rule`                                      [get/set the fill rule][cairo_set_fill_rule]
__stroking__
`cr:stroke()`                                                       [stroke the current path and discard it][cairo_stroke]
`cr:stroke_preserve()`                                              [stroke and keep the path][cairo_stroke_preserve]
`cr:stroke_extents() -> x1, y1, x2, y2`                             [get the bounding box of stroking the current path][cairo_stroke_extents]
`cr:in_stroke(x, y) -> t|f`                                         [hit-test the stroke area][cairo_in_stroke]
`cr:line_width(width]) /-> width`                                   [get/set the line width][cairo_set_line_width]
`cr:line_cap(cap) /-> cap`                                          [get/set the line cap][cairo_set_line_cap]
`cr:line_join(join) /-> join`                                       [get/set the line join][cairo_set_line_join]
`cr:miter_limit(limit) /-> limit`                                   [get/set the miter limit][cairo_set_miter_limit]
`cr:dash(dashes:table, [offset])`                                   [set the dash pattern for stroking][cairo_set_dash]
`cr:dash(dashes:double*, dash_count, [offset])`                     [set the dash pattern for stroking][cairo_set_dash]
`cr:dash() -> dashes, dash_count`                                   [get the dash pattern for stroking][cairo_get_dash]
`cr:dash'#' -> n`                                                   [get the dash count][cairo_get_dash_count]
`cr:dash(nil, dashes:double*) -> dash_count`                        [get the dash pattern for stroking][cairo_get_dash]
__rasterization options__
`cr:tolerance(tolerance]) /-> tolerance`                            [get/set tolerance][cairo_set_tolerance]
`cr:antialias(antialias]) /-> antialias`                            [get/set the antialiasing mode][cairo_set_antialias]
__clipping__
`cr:clip()`                                                         [intersect the current path to the current clipping region and discard the path][cairo_clip]
`cr:clip_preserve()`                                                [clip and keep the current path][cairo_clip_preserve]
`cr:reset_clip()`                                                   [remove all clipping][cairo_reset_clip]
`cr:clip_extents() -> x1, y1, x2, y2`                               [get the clip extents][cairo_clip_extents]
`cr:in_clip(x, y) -> t|f`                                           [hit-test the clip area][cairo_in_clip]
`cr:clip_rectangles() -> rlist`                                     [get the clipping rectangles][cairo_copy_clip_rectangle_list]
__solid-color patterns__
`cairo.color_pattern(r, g, b[, a]) -> patt`                         [create a solid color pattern][cairo_pattern_create_rgb]
`patt:color() -> r, g, b, a`                                        [get the color of a solid color pattern][cairo_pattern_get_rgba]
__gradient patterns__
`cairo.linear_gradient(x0, y0, x1, y1) -> patt`                     [create a linear gradient][cairo_pattern_create_linear]
`cairo.radial_gradient(cx0, cy0, r0, cx1, cy1, r1) -> patt`         [create a radial gradient][cairo_pattern_create_radial]
`patt:linear_points() -> x0, y0, x1, y1`                            [get the endpoints of a linear gradient][cairo_pattern_get_linear_points]
`patt:radial_circles() -> cx0, cy0, r0, cx1, cy1, r1`               [get the circles of a radial gradient][cairo_pattern_get_radial_circles]
`patt:add_color_stop(offset, r, g, b[, a])`                         [add a RGB(A) color stop][cairo_pattern_add_color_stop_rgb]
`patt:color_stop'#' -> n`                                           [get the number of color stops][cairo_pattern_get_color_stop_count]
`patt:color_stop(i) -> offset, r, g, b, a`                          [get a color stop][cairo_pattern_get_color_stop_rgba]
__surface patterns__
`cairo.surface_pattern(sr) -> patt`                                 [create a surface-type pattern][cairo_pattern_create_for_surface]
`patt:surface() -> sr | nil`                                        [get the pattern's surface][cairo_pattern_get_surface]
__raster-source patterns__
`cairo.raster_source_pattern(data, content, w, h) -> patt`          [create a raster source-type pattern][cairo_pattern_create_raster_source]
`patt:callback_data(data) /-> data`                                 [get/set callback data][cairo_raster_source_pattern_set_callback_data]
`patt:acquire_function(func) /-> func`                              [get/set the acquire function][cairo_raster_source_pattern_set_acquire]
`patt:snapshot_function(func) /-> func`                             [get/set the snapshot function][cairo_raster_source_pattern_set_snapshot]
`patt:copy_function(func) /-> func`                                 [get/set the copy function][cairo_raster_source_pattern_set_copy]
`patt:finish_function(func) /-> func`                               [get/set the finish function][cairo_raster_source_pattern_set_finish]
__mesh patterns__
`cairo.mesh_pattern() -> patt`                                      [create a mesh pattern][cairo_pattern_create_mesh]
`patt:begin_patch()`                                                [start a new patch][cairo_mesh_pattern_begin_patch]
`patt:end_patch()`                                                  [end current patch][cairo_mesh_pattern_end_patch]
`patt:move_to(x, y)`                                                [move the current point][cairo_mesh_pattern_move_to]
`patt:line_to(x, y)`                                                [add a line][cairo_mesh_pattern_line_to]
`patt:curve_to(x1, y1, x2, y2, x3, y3)`                             [add a cubic bezier][cairo_mesh_pattern_curve_to]
`patt:control_point(point_num, x, y)`                               [set a control point of the current patch][cairo_mesh_pattern_set_control_point]
`patt:control_point(patch_num, point_num) -> x, y`                  [get a control point][cairo_mesh_pattern_get_control_point]
`patt:corner_color(corner_num, r, g, b[, a])`                       [set a corner color of the current patch][cairo_mesh_pattern_set_corner_color_rgb]
`patt:corner_color(patch_num, corner_num) -> r, g, b, a`            [get a corner color][cairo_mesh_pattern_get_corner_color_rgba]
__all patterns__
`patt:type() -> type`                                               [get the pattern type][cairo_pattern_get_type]
`patt:matrix(mt) /-> mt`                                            [get/set the matrix][cairo_pattern_set_matrix]
`patt:extend(extend) /-> extend`                                    [get/set the extend][cairo_pattern_set_extend]
`patt:filter(filter) /-> filter`                                    [get/set the filter][cairo_pattern_set_filter]
__drawing text__
`cr:font_face(face) /-> face`                                       [get/set the font face][cairo_set_font_face]
`cr:font_size(size)`                                                [set the font size][cairo_set_font_size]
`cr:font_matrix(mt) /-> mt`                                         [get/set the font matrix][cairo_set_font_matrix]
`cr:scaled_font(sfont) /-> sfont`                                   [get/set the scaled font][cairo_set_scaled_font]
`cr:font_extents() -> cairo_font_extents_t`                         [get the font extents of the current font][cairo_font_extents]
`sr:font_options() -> fopt`                                         [get the default font options][cairo_surface_get_font_options]
`cr:font_options(fopt) /-> fopt`                                    [get/set custom font options][cairo_set_font_options]
__drawing text (toy API)__
`cr:font_face(family[, slant[, weight]])`                           [select a font face][cairo_select_font_face]
`cr:show_text(s)`                                                   [show text][cairo_show_text]
`cr:text_path(s)`                                                   [add closed paths for text to the current path][cairo_text_path]
`cr:text_extents(s) -> cairo_text_extents_t`                        [get text extents][cairo_text_extents]
__drawing glyphs__
`cairo.allocate_glyphs(count) -> cairo_glyph_t*`                    [allocate an array of glyphs][cairo_glyph_allocate]
`cr:show_glyphs(glyphs, #glyphs)`                                   [draw glyphs][cairo_show_glyphs]
`cr:glyph_path(glyphs, #glyphs)`                                    [add paths for the glyphs to the current path][cairo_glyph_path]
`cr:glyph_extents(glyphs, #glyphs) -> cairo_text_extents_t`         [get the text extents of an array of glyphs][cairo_glyph_extents]
__text cluster mapping__
`cairo.allocate_text_clusters(count) -> cairo_text_cluster_t*`      [allocate an array of text clusters][cairo_text_cluster_allocate]
`sfont:text_to_glyphs(x,y, s,[#s]) -> g,#g, c,#c, cf | nil,err`     [convert text to glyphs][cairo_scaled_font_text_to_glyphs]
`cr:show_text_glyphs(s, [#s], g, #g, c, #c, f)`                     [draw glyphs with native cluster mapping][cairo_show_text_glyphs]
`sr:has_show_text_glyphs() -> t|f`                                  [check if surface has support for cluster mapping][cairo_surface_has_show_text_glyphs]
__freetype fonts__
`cairo.ft_font_face(ft_face[, ft_flags]) -> face`                   [create a font face from a freetype handle][cairo_ft_font_face_create_for_ft_face]
`face:synthesize_bold(t|f) /-> t|f`                                 [get/set synthethize bold flag][cairo_ft_font_face_set_synthesize]
`face:synthesize_oblique(t|f) /-> t|f`                              [get/set synthethize oblique flag][cairo_ft_font_face_set_synthesize]
`sfont:lock_face() -> FT_Face`                                      [lock font face][cairo_ft_scaled_font_lock_face]
`sfont:unlock_face()`                                               [unlock font face][cairo_ft_scaled_font_unlock_face]
__toy fonts__
`cairo.toy_font_face(family[, slant[, weight]]) -> face`            [select a font with the toy text API][cairo_toy_font_face_create]
`face:family() -> family`                                           [get font family][cairo_font_face_toy_get_family]
`face:slant() -> slant`                                             [get font slant][cairo_font_face_toy_get_slant]
`face:weight() -> weight`                                           [get font weight][cairo_font_face_toy_get_weight]
__callback-based fonts__
`cairo.user_font_face() -> face`                                    [create a user font][cairo_user_font_face_create]
`face:init_func(func) /-> func`                                     [get/set the scaled-font init function][cairo_user_font_face_set_init_func]
`face:render_glyph_func(func) /-> func`                             [get/set the glyph rendering function][cairo_user_font_face_set_render_glyph_func]
`face:text_to_glyphs_func(func) /-> func`                           [get/set the text-to-glyphs function][cairo_user_font_face_set_text_to_glyphs_func]
`face:unicode_to_glyph_func(func) /-> func`                         [get/set the text-to-glyphs easy function][cairo_user_font_face_set_unicode_to_glyph_func]
__all fonts__
`face:type() -> type`                                               [get font type][cairo_font_face_get_type]
__scaled fonts__
`face:scaled_font(mt, ctm, fopt) -> sfont`                          [create scaled font][cairo_scaled_font_create]
`sfont:type() -> cairo_font_type_t`                                 [get scaled font type][cairo_scaled_font_get_type]
`sfont:extents() -> cairo_font_extents_t`                           [get font extents][cairo_scaled_font_extents]
`sfont:text_extents(s) -> cairo_text_extents_t`                     [get text extents][cairo_scaled_font_text_extents]
`sfont:glyph_extents(glyphs, #glyphs) -> cairo_text_extents_t`      [get the extents of an array of glyphs][cairo_scaled_font_glyph_extents]
`sfont:font_matrix() -> mt`                                         [get the font matrix][cairo_scaled_font_get_font_matrix]
`sfont:ctm() -> mt`                                                 [get the CTM][cairo_scaled_font_get_ctm]
`sfont:scale_matrix() -> mt`                                        [get the scale matrix][cairo_scaled_font_get_scale_matrix]
`sfont:font_options(fopt) /-> fopt`                                 [get/set the font options][cairo_scaled_font_get_font_options]
`sfont:font_face() -> face`                                         [get the font face][cairo_scaled_font_get_font_face]
__font options__
`cairo.font_options() -> fopt`                                      [create a font options object][cairo_font_options_create]
`fopt:copy() -> fopt`                                               [copy font options][cairo_font_options_copy]
`fopt:merge(fopt)`                                                  [merge options][cairo_font_options_merge]
`fopt:equal(fopt) -> t|f`                                           [compare options][cairo_font_options_equal]
`fopt:hash() -> n`                                                  [get options hash][cairo_font_options_hash]
`fopt:antialias(antialias) /-> antialias`                           [get/set the antialiasing mode][cairo_font_options_set_antialias]
`fopt:subpixel_order(order) /-> order`                              [get/set the subpixel order][cairo_font_options_set_subpixel_order]
`fopt:hint_style(style) /-> style`                                  [get/set the hint style][cairo_font_options_set_hint_style]
`fopt:hint_metrics(metrics) /-> metrics`                            [get/set the hint metrics][cairo_font_options_set_hint_metrics]
`fopt:lcd_filter(filter) /-> filter`                                [get/set the lcd filter][cairo_font_options_set_lcd_filter]
`fopt:round_glyph_positions(pos) /-> pos`                           [get/set the round glyph positions][cairo_font_options_set_round_glyph_positions]
__multi-page backends__
`sr:copy_page()`                                                    [emit the current page and retain surface contents][cairo_surface_copy_page]
`sr:show_page()`                                                    [emit the current page and clear surface contents][cairo_surface_show_page]
__devices__
`sr:device() -> cairo_device_t`                                     [get the device of the surface][cairo_surface_get_device]
`sr:device_offset([x, y]) /-> x, y`                                 [set device offset][cairo_surface_set_device_offset]
`dev:type() -> type`                                                [get device type][cairo_device_get_type]
`dev:acquire() -> true | nil,err,status`                            [acquire device][cairo_device_acquire]
`dev:release()`                                                     [release acquired device][cairo_device_release]
`dev:flush()`                                                       [flush pending drawing operations][cairo_device_flush]
`dev:finish()`                                                      [finish device][cairo_device_finish]
__matrices__
`cairo.matrix([mt | a,b,c,d,e,f]) -> mt`                            create a matrix (init as identity by default)
`mt:reset([mt | a,b,c,d,e,f]) -> mt`                                reinitialize the matrix (as identity if no args given)
`mt:translate(x, y) -> mt`                                          [translate][cairo_matrix_translate]
`mt:scale(sx[, sy]) -> mt`                                          [scale][cairo_matrix_scale]
`mt:scale_around(cx, cy, sx[, sy]) -> mt`                           scale around a point
`mt:rotate(angle) -> mt`                                            [rotate][cairo_matrix_rotate]
`mt:rotate_around(cx, cy, angle) -> mt`                             rotate arount a point
`mt:invert() -> t|f`                                                [invert if possible][cairo_matrix_invert]
`mt1 * mt2 -> mt3`                                                  [multiply matrices][cairo_matrix_multiply]
`mt:multiply(mt1[, mt2]) -> mt`                                     perform `mt * mt1 -> mt` or `mt1 * mt2 -> mt`
`mt(x, y) -> x, y`                                                  [transform point][cairo_matrix_transform_point]
`mt:distance(x, y) -> x, y`                                         [transform distance][cairo_matrix_transform_distance]
`mt:transform(mt) -> mt`                                            transform by other matrix
`mt:determinant() -> d`                                             compute the determinant
`mt:invertible() -> t|f`                                            check if the matrix is invertible
`mt:safe_transform(mt) -> mt`                                       transform by matrix only if it's invertible
`mt:skew(ax, ay) -> mt`                                             skew
`mt:copy() -> mt`                                                   copy the matrix
`mt:equal(mt2) -> t|f` <br> `mt == mt2`                             test matrices for equality
__regions__
`cairo.region([[x, y, w, h] | rlist]) -> rgn`                       [create a region][cairo_region_create]
`rgn:copy() -> rgn`                                                 [copy region][cairo_region_copy]
`rgn:equal(rgn) -> t|f`                                             [compare regions][cairo_region_equal]
`rgn:extents() -> x, y, w, h`                                       [region extents][cairo_region_get_extents]
`rgn:num_rectangles() -> n`                                         [number of rectangles][cairo_region_num_rectangles]
`rgn:rectangle(i) -> x, y, w, h`                                    [get a rectangle][cairo_region_get_rectangle]
`rgn:is_empty() -> t|f`                                             [check if empty][cairo_region_is_empty]
`rgn:contains_rectangle(x, y, w, h) -> t|f | 'partial'`             [rectangle hit test][cairo_region_contains_rectangle]
`rgn:contains_point(x, y) -> t|f`                                   [point hit test][cairo_region_contains_point]
`rgn:translate(x, y)`                                               [translate region][cairo_region_translate]
`rgn:subtract(rgn | x, y, w, h)`                                    [substract region or rectangle][cairo_region_subtract]
`rgn:intersect(rgn | x, y, w, h)`                                   [intersect with region or rectangle][cairo_region_intersect]
`rgn:union(rgn | x, y, w, h)`                                       [union with region or rectangle][cairo_region_union]
`rgn:xor(rgn | x, y, w, h)`                                         [xor with region or rectangle][cairo_region_xor]
__memory management__
`obj:free()`                                                        free object
`obj:refcount() -> refcount`                                        get ref count (*)
`obj:ref()`                                                         increase ref count (*)
`obj:unref()`                                                       decrease ref count and free when 0 (*)
__status__
`obj:status() -> status`                                            [get status][cairo_status_t]
`obj:status_message() -> s`                                         [get status message][cairo_status_to_string]
`obj:check()`                                                       raise an error if the object has an error status
__misc.__
`cairo.stride(fmt, w) -> stride`                                    [get stride for a format and width][cairo_format_stride_for_width]
`cairo.bitmap_format(cairo_fmt) -> bmp_fmt`                         get the [bitmap] format matching a cairo format
`cairo.cairo_format(bmp_fmt) -> cairo_fmt`                          get the cairo format matching a bitmap format
`cairo.version() -> n`                                              [get lib version][cairo_version]
`cairo.version_string() -> s`                                       [get lib version as "X.Y.Z"][cairo_version_string]
`cairo.NULL`                                                        a `void*` NULL pointer to disambiguate from `nil` when needed
`cairo.enums -> {prefix -> {name -> value}}`                        access to enum tables
------------------------------------------------------------------- -------------------------------------------------------------------

(+) supported formats: 'bgra8', 'bgrx8', 'g8', 'g1', 'rgb565', 'bgr10'; the `bmp.data` field is anchored!

(*) for ref-counted objects only: `cr`, `sr`, `dev`, `patt`, `sfont`, `font` and `rgn`.


## Binaries

The included binaries are built with support for:

* surfaces: image (pixman), recording, PS, PDF, SVG, GDI, Quartz
* font selectors: Windows native, Quartz native
* fonts: Windows native, Quartz native, freetype
* PNG support

The build is configurable so you can add/remove these extensions as needed.
The binding won't break if extensions are missing in the binary.



[cairo_image_surface_create]:              http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create
[cairo_image_surface_create_for_data]:     http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create-for-data
[cairo_image_surface_get_data]:            http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-data
[cairo_image_surface_get_format]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-format
[cairo_image_surface_get_width]:           http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-width
[cairo_image_surface_get_height]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-height
[cairo_image_surface_get_stride]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-stride

[cairo_surface_create_for_rectangle]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-for-rectangle
[cairo_surface_create_similar]:            http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar
[cairo_surface_create_similar_image]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar-image
[cairo_surface_get_type]:                  http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-type
[cairo_surface_get_content]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-content
[cairo_surface_flush]:                     http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-flush
[cairo_surface_mark_dirty]:                http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-mark-dirty
[cairo_surface_set_fallback_resolution]:   http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-fallback-resolution
[cairo_surface_has_show_text_glyphs]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-has-show-text-glyphs
[cairo_surface_set_mime_data]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-mime-data
[cairo_surface_get_mime_data]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-mime-data
[cairo_surface_supports_mime_type]:        http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-supports-mime-type
[cairo_surface_map_to_image]:              http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-map-to-image
[cairo_surface_unmap_image]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-unmap-image
[cairo_surface_finish]:                    http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-finish

[cairo_recording_surface_create]:          http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-create
[cairo_recording_surface_ink_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-ink-extents
[cairo_recording_surface_get_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-get-extents

[cairo_create]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-create
[cairo_save]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-save
[cairo_restore]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-restore

[cairo_set_source_rgb]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgb
[cairo_set_source_rgba]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgba
[cairo_set_source]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source
[cairo_set_operator]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-operator
[cairo_mask]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-mask

[cairo_push_group]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-push-group
[cairo_pop_group]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group
[cairo_pop_group_to_source]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group-to-source
[cairo_get_target]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-target
[cairo_get_group_target]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-group-target

[cairo_translate]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-translate
[cairo_scale]:                             http://cairographics.org/manual/cairo-Transformations.html#cairo-scale
[cairo_scale_around]:                      http://cairographics.org/manual/cairo-Transformations.html#cairo-scale-around
[cairo_rotate]:                            http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate
[cairo_rotate_around]:                     http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate-around
[cairo_skew]:                              http://cairographics.org/manual/cairo-Transformations.html#cairo-skew
[cairo_transform]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-transform
[cairo_set_matrix]:                        http://cairographics.org/manual/cairo-Transformations.html#cairo-set-matrix
[cairo_identity_matrix]:                   http://cairographics.org/manual/cairo-Transformations.html#cairo-identity-matrix
[cairo_user_to_device]:                    http://cairographics.org/manual/cairo-Transformations.html#cairo-user-to-device
[cairo_user_to_device_distance]:           http://cairographics.org/manual/cairo-Transformations.html#cairo-user-to-device-distance
[cairo_device_to_user]:                    http://cairographics.org/manual/cairo-Transformations.html#cairo-device-to-user
[cairo_device_to_user_distance]:           http://cairographics.org/manual/cairo-Transformations.html#cairo-device-to-user-distance

[cairo_new_path]:                          http://cairographics.org/manual/cairo-Paths.html#cairo-new-path
[cairo_new_sub_path]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-new-sub-path
[cairo_move_to]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-move-to
[cairo_line_to]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-line-to
[cairo_curve_to]:                          http://cairographics.org/manual/cairo-Paths.html#cairo-curve-to
[cairo_quad_curve_to]:                     http://cairographics.org/manual/cairo-Paths.html#cairo-quad-curve-to
[cairo_arc]:                               http://cairographics.org/manual/cairo-Paths.html#cairo-arc
[cairo_arc_negative]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-arc-negative
[cairo_circle]:                            http://cairographics.org/manual/cairo-Paths.html#cairo-circle
[cairo_ellipse]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-ellipse
[cairo_rel_move_to]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-rel-move-to
[cairo_rel_line_to]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-rel-line-to
[cairo_rel_curve_to]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-rel-curve-to
[cairo_rel_quad_curve_to]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-rel-quad-curve-to
[cairo_rectangle]:                         http://cairographics.org/manual/cairo-Paths.html#cairo-rectangle
[cairo_close_path]:                        http://cairographics.org/manual/cairo-Paths.html#cairo-close-path
[cairo_copy_path]:                         http://cairographics.org/manual/cairo-Paths.html#cairo-copy-path
[cairo_copy_path_flat]:                    http://cairographics.org/manual/cairo-Paths.html#cairo-copy-path-flat
[cairo_append_path]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-append-path
[cairo_path_extents]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-path-extents
[cairo_has_current_point]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-has-current-point
[cairo_get_current_point]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-get-current-point

[cairo_paint]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint
[cairo_paint_with_alpha]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint-with-alpha
[cairo_stroke]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke
[cairo_stroke_preserve]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-preserve
[cairo_fill]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill
[cairo_fill_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-preserve
[cairo_in_stroke]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-stroke
[cairo_in_fill]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-fill
[cairo_in_clip]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-clip
[cairo_stroke_extents]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-extents
[cairo_fill_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-extents

[cairo_set_tolerance]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-tolerance
[cairo_set_antialias]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-antialias
[cairo_set_fill_rule]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-fill-rule
[cairo_set_line_width]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-width
[cairo_set_line_cap]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-cap
[cairo_set_line_join]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-join
[cairo_set_miter_limit]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit
[cairo_set_dash]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-dash
[cairo_get_dash]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash
[cairo_get_dash_count]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash-count

[cairo_clip]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip
[cairo_clip_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-preserve
[cairo_reset_clip]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-reset-clip
[cairo_clip_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-extents
[cairo_copy_clip_rectangle_list]:          http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-clip-rectangle-list

[cairo_pattern_get_type]:                  http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-type
[cairo_pattern_set_matrix]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-matrix
[cairo_pattern_set_extend]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-extend
[cairo_pattern_set_filter]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-filter
[cairo_pattern_get_surface]:               http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-surface

[cairo_pattern_create_rgb]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-rgb
[cairo_pattern_get_rgba]:                  http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-rgba

[cairo_pattern_create_linear]:             http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-linear
[cairo_pattern_create_radial]:             http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-radial
[cairo_pattern_get_linear_points]:         http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-linear-points
[cairo_pattern_get_radial_circles]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-radial-circles
[cairo_pattern_add_color_stop_rgb]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-add-color-stop-rgb
[cairo_pattern_get_color_stop_count]:      http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-count
[cairo_pattern_get_color_stop_rgba]:       http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-rgba

[cairo_pattern_create_for_surface]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-for-surface

[cairo_pattern_create_raster_source]:             http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-create-raster-source
[cairo_raster_source_pattern_set_callback_data]:  http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-callback-data
[cairo_raster_source_pattern_set_acquire]:        http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-acquire
[cairo_raster_source_pattern_set_snapshot]:       http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-snapshot
[cairo_raster_source_pattern_set_copy]:           http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-copy
[cairo_raster_source_pattern_set_finish]:         http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-finish

[cairo_pattern_create_mesh]:                 http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-mesh
[cairo_mesh_pattern_begin_patch]:            http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-begin-patch
[cairo_mesh_pattern_end_patch]:              http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-end-patch
[cairo_mesh_pattern_move_to]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-move-to
[cairo_mesh_pattern_line_to]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-line-to
[cairo_mesh_pattern_curve_to]:               http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-curve-to
[cairo_mesh_pattern_set_control_point]:      http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-set-control-point
[cairo_mesh_pattern_get_control_point]:      http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-control-point
[cairo_mesh_pattern_set_corner_color_rgb]:   http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-set-corner-color-rgb
[cairo_mesh_pattern_get_corner_color_rgba]:  http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-corner-color-rgba

[cairo_select_font_face]:                  http://cairographics.org/manual/cairo-text.html#cairo-select-font-face
[cairo_show_text]:                         http://cairographics.org/manual/cairo-text.html#cairo-show-text
[cairo_text_path]:                         http://cairographics.org/manual/cairo-Paths.html#cairo-text-path
[cairo_text_extents]:                      http://cairographics.org/manual/cairo-text.html#cairo-text-extents

[cairo_set_font_face]:                     http://cairographics.org/manual/cairo-text.html#cairo-set-font-face
[cairo_set_scaled_font]:                   http://cairographics.org/manual/cairo-text.html#cairo-set-scaled-font
[cairo_set_font_size]:                     http://cairographics.org/manual/cairo-text.html#cairo-set-font-size
[cairo_set_font_matrix]:                   http://cairographics.org/manual/cairo-text.html#cairo-set-font-matrix
[cairo_show_glyphs]:                       http://cairographics.org/manual/cairo-text.html#cairo-show-glyphs
[cairo_show_text_glyphs]:                  http://cairographics.org/manual/cairo-text.html#cairo-show-text-glyphs
[cairo_glyph_path]:                        http://cairographics.org/manual/cairo-Paths.html#cairo-glyph-path
[cairo_glyph_extents]:                     http://cairographics.org/manual/cairo-text.html#cairo-glyph-extents
[cairo_font_extents]:                      http://cairographics.org/manual/cairo-text.html#cairo-font-extents

[cairo_ft_font_face_create_for_ft_face]:   http://cairographics.org/manual/cairo-FreeType-Fonts.html#cairo-ft-font-face-create-for-ft-face
[cairo_ft_font_face_set_synthesize]:       http://cairographics.org/manual/cairo-FreeType-Fonts.html#cairo-ft-font-face-set-synthesize

[cairo_ft_scaled_font_lock_face]:          http://cairographics.org/manual/cairo-FreeType-Fonts.html#cairo-ft-scaled-font-lock-face
[cairo_ft_scaled_font_unlock_face]:        http://cairographics.org/manual/cairo-FreeType-Fonts.html#cairo-ft-scaled-font-unlock-face

[cairo_toy_font_face_create]:              http://cairographics.org/manual/cairo-text.html#cairo-toy-font-face-create
[cairo_font_face_toy_get_family]:          http://cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-family
[cairo_font_face_toy_get_slant]:           http://cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-slant
[cairo_font_face_toy_get_weight]:          http://cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-weight

[cairo_user_font_face_create]:                     http://cairographics.org/manual/cairo-User-Fonts.html#cairo-user-font-face-create
[cairo_user_font_face_set_init_func]:              http://cairographics.org/manual/cairo-User-Fonts.html#cairo-user-font-face-set-init-func
[cairo_user_font_face_set_render_glyph_func]:      http://cairographics.org/manual/cairo-User-Fonts.html#cairo-user-font-face-set-render-glyph-func
[cairo_user_font_face_set_text_to_glyphs_func]:    http://cairographics.org/manual/cairo-User-Fonts.html#cairo-user-font-face-set-text-to-glyphs-func
[cairo_user_font_face_set_unicode_to_glyph_func]:  http://cairographics.org/manual/cairo-User-Fonts.html#cairo-user-font-face-set-unicode-to-glyph-func

[cairo_font_face_get_type]:                http://cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-get-type

[cairo_scaled_font_create]:                http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-create
[cairo_scaled_font_get_type]:              http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-type
[cairo_scaled_font_extents]:               http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-extents
[cairo_scaled_font_text_extents]:          http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-text-extents
[cairo_scaled_font_glyph_extents]:         http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-glyph-extents
[cairo_scaled_font_text_to_glyphs]:        http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-text-to-glyphs
[cairo_scaled_font_get_font_matrix]:       http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-matrix
[cairo_scaled_font_get_ctm]:               http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-ctm
[cairo_scaled_font_get_scale_matrix]:      http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-scale-matrix
[cairo_scaled_font_get_font_options]:      http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-options
[cairo_scaled_font_get_font_face]:         http://cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-face

[cairo_surface_get_font_options]:          http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-font-options
[cairo_set_font_options]:                  http://cairographics.org/manual/cairo-text.html#cairo-set-font-options

[cairo_font_options_create]:               http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-create
[cairo_font_options_copy]:                 http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-copy
[cairo_font_options_merge]:                http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-merge
[cairo_font_options_equal]:                http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-equal
[cairo_font_options_hash]:                 http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-hash
[cairo_font_options_set_antialias]:        http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-antialias
[cairo_font_options_set_subpixel_order]:   http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-subpixel-order
[cairo_font_options_set_hint_style]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-hint-style
[cairo_font_options_set_hint_metrics]:     http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-hint-metrics
[cairo_font_options_set_lcd_filter]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-lcd-filter
[cairo_font_options_set_round_glyph_positions]:  http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-round-glyph-positions

[cairo_glyph_allocate]:                    http://cairographics.org/manual/cairo-text.html#cairo-glyph-allocate
[cairo_text_cluster_allocate]:             http://cairographics.org/manual/cairo-text.html#cairo-text-cluster-allocate

[cairo_surface_copy_page]:                 http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-copy-page
[cairo_surface_show_page]:                 http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-show-page

[cairo_surface_get_device]:                http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-device
[cairo_surface_set_device_offset]:         http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-device-offset
[cairo_device_get_type]:                   http://cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-get-type
[cairo_device_acquire]:                    http://cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-acquire
[cairo_device_release]:                    http://cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-release
[cairo_device_flush]:                      http://cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-flush
[cairo_device_finish]:                     http://cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-finish

[cairo_matrix_init]:                       http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init
[cairo_matrix_init_identity]:              http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-identity
[cairo_matrix_init_translate]:             http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-translate
[cairo_matrix_init_scale]:                 http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-scale
[cairo_matrix_init_rotate]:                http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-rotate
[cairo_matrix_translate]:                  http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-translate
[cairo_matrix_scale]:                      http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-scale
[cairo_matrix_rotate]:                     http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-rotate
[cairo_matrix_invert]:                     http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-invert
[cairo_matrix_multiply]:                   http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-multiply
[cairo_matrix_transform_point]:            http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-transform-point
[cairo_matrix_transform_distance]:         http://cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-transform-distance

[cairo_region_create]:                     http://cairographics.org/manual/cairo-Regions.html#cairo-region-create
[cairo_region_copy]:                       http://cairographics.org/manual/cairo-Regions.html#cairo-region-copy
[cairo_region_equal]:                      http://cairographics.org/manual/cairo-Regions.html#cairo-region-equal
[cairo_region_get_extents]:                http://cairographics.org/manual/cairo-Regions.html#cairo-region-get-extents
[cairo_region_num_rectangles]:             http://cairographics.org/manual/cairo-Regions.html#cairo-region-num-rectangles
[cairo_region_get_rectangle]:              http://cairographics.org/manual/cairo-Regions.html#cairo-region-get-rectangle
[cairo_region_is_empty]:                   http://cairographics.org/manual/cairo-Regions.html#cairo-region-is-empty
[cairo_region_contains_rectangle]:         http://cairographics.org/manual/cairo-Regions.html#cairo-region-contains-rectangle
[cairo_region_contains_point]:             http://cairographics.org/manual/cairo-Regions.html#cairo-region-contains-point
[cairo_region_translate]:                  http://cairographics.org/manual/cairo-Regions.html#cairo-region-translate
[cairo_region_subtract]:                   http://cairographics.org/manual/cairo-Regions.html#cairo-region-substract
[cairo_region_intersect]:                  http://cairographics.org/manual/cairo-Regions.html#cairo-region-intersect
[cairo_region_union]:                      http://cairographics.org/manual/cairo-Regions.html#cairo-region-union
[cairo_region_xor]:                        http://cairographics.org/manual/cairo-Regions.html#cairo-region-xor

[cairo_image_surface_create_from_png]:         http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png
[cairo_image_surface_create_from_png_stream]:  http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png-stream
[cairo_surface_write_to_png]:                  http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png
[cairo_surface_write_to_png_stream]:           http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png-stream

[cairo_status_t]:                          http://cairographics.org/manual/cairo-Error-handling.html#cairo-status-t
[cairo_status_to_string]:                  http://cairographics.org/manual/cairo-Error-handling.html#cairo-status-to-string
[cairo_format_stride_for_width]:           http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-stride-for-width

[cairo_version]:                           http://cairographics.org/manual/cairo-Version-Information.html#cairo-version
[cairo_version_string]:                    http://cairographics.org/manual/cairo-Version-Information.html#cairo-version-string

[cairo_pdf_surface_create]:                http://cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-create
[cairo_pdf_surface_create_for_stream]:     http://cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-create-for-stream
[cairo_pdf_get_versions]:                  http://cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-get-versions
[cairo_pdf_surface_restrict_to_version]:   http://cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-restrict-to-version
[cairo_pdf_surface_set_size]:              http://cairographics.org/manual/cairo-PDF-Surfaces.html#cairo-pdf-surface-set-size

[cairo_ps_surface_create]:                 http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-create
[cairo_ps_surface_create_for_stream]:      http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-create-for-stream
[cairo_ps_get_levels]:                     http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-get-levels
[cairo_ps_surface_restrict_to_level]:      http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-restrict-to-level
[cairo_ps_surface_set_eps]:                http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-set-eps
[cairo_ps_surface_set_size]:               http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-set-size
[cairo_ps_surface_dsc_comment]:            http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-dsc-comment
[cairo_ps_surface_dsc_begin_setup]:        http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-dsc-begin-setup
[cairo_ps_surface_dsc_begin_page_setup]:   http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-dsc-begin-page-setup

[cairo_svg_surface_create]:                http://cairographics.org/manual/cairo-SVG-Surfaces.html#cairo-svg-surface-create
[cairo_svg_surface_create_for_stream]:     http://cairographics.org/manual/cairo-SVG-Surfaces.html#cairo-svg-surface-create-for-stream
[cairo_svg_get_versions]:                  http://cairographics.org/manual/cairo-SVG-Surfaces.html#cairo-svg-get-versions
[cairo_svg_surface_restrict_to_version]:   http://cairographics.org/manual/cairo-SVG-Surfaces.html#cairo-svg-surface-restrict-to-version
[cairo_svg_surface_set_size]:              http://cairographics.org/manual/cairo-SVG-Surfaces.html#cairo-svg-surface-set-size
