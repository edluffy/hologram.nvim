--result of `cpp cairo-win32.h` from cairo 1.12.3
local ffi = require'ffi'

assert(ffi.os == 'Windows', 'platform not Windows')

require'cairo_h'
require'winapi.types' --HDC, HFONT
require'winapi.logfonttype' --LOGFONTW

ffi.cdef[[
 cairo_surface_t *
cairo_win32_surface_create (HDC hdc);
 cairo_surface_t *
cairo_win32_printing_surface_create (HDC hdc);
 cairo_surface_t *
cairo_win32_surface_create_with_ddb (HDC hdc,
                                     cairo_format_t format,
                                     int width,
                                     int height);
 cairo_surface_t *
cairo_win32_surface_create_with_dib (cairo_format_t format,
                                     int width,
                                     int height);
 HDC
cairo_win32_surface_get_dc (cairo_surface_t *surface);
 cairo_surface_t *
cairo_win32_surface_get_image (cairo_surface_t *surface);
 cairo_font_face_t *
cairo_win32_font_face_create_for_logfontw (LOGFONTW *logfont);
 cairo_font_face_t *
cairo_win32_font_face_create_for_hfont (HFONT font);
 cairo_font_face_t *
cairo_win32_font_face_create_for_logfontw_hfont (LOGFONTW *logfont, HFONT font);
 cairo_status_t
cairo_win32_scaled_font_select_font (cairo_scaled_font_t *scaled_font,
         HDC hdc);
 void
cairo_win32_scaled_font_done_font (cairo_scaled_font_t *scaled_font);
 double
cairo_win32_scaled_font_get_metrics_factor (cairo_scaled_font_t *scaled_font);
 void
cairo_win32_scaled_font_get_logical_to_device (cairo_scaled_font_t *scaled_font,
            cairo_matrix_t *logical_to_device);
 void
cairo_win32_scaled_font_get_device_to_logical (cairo_scaled_font_t *scaled_font,
            cairo_matrix_t *device_to_logical);
]]
