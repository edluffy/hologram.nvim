cd src || exit 1

# cairo expects CAIRO_HAS_* defines in cairo-features.h,
# but we specify those on the command line instead
echo "#define CAIRO_FEATURES_H" > cairo-features.h

C="$C
	-DHAVE_STDINT_H=1
	-DHAVE_UINT64_T=1
	cairo-analysis-surface.c
	cairo-arc.c
	cairo-array.c
	cairo-atomic.c
	cairo-base64-stream.c
	cairo-base85-stream.c
	cairo-bentley-ottmann.c
	cairo-bentley-ottmann-rectangular.c
	cairo-bentley-ottmann-rectilinear.c
	cairo-botor-scan-converter.c
	cairo-boxes.c
	cairo-boxes-intersect.c
	cairo.c
	cairo-cache.c
	cairo-clip.c
	cairo-clip-boxes.c
	cairo-clip-polygon.c
	cairo-clip-region.c
	cairo-clip-surface.c
	cairo-color.c
	cairo-composite-rectangles.c
	cairo-compositor.c
	cairo-contour.c
	cairo-damage.c
	cairo-debug.c
	cairo-default-context.c
	cairo-device.c
	cairo-error.c
	cairo-fallback-compositor.c
	cairo-fixed.c
	cairo-font-face.c
	cairo-font-face-twin.c
	cairo-font-face-twin-data.c
	cairo-font-options.c
	cairo-freelist.c
	cairo-freed-pool.c
	cairo-gstate.c
	cairo-hash.c
	cairo-hull.c
	cairo-lzw.c
	cairo-matrix.c
	cairo-mask-compositor.c
	cairo-mesh-pattern-rasterizer.c
	cairo-mempool.c
	cairo-misc.c
	cairo-mono-scan-converter.c
	cairo-mutex.c
	cairo-no-compositor.c
	cairo-observer.c
	cairo-output-stream.c
	cairo-paginated-surface.c
	cairo-path-bounds.c
	cairo-path.c
	cairo-path-fill.c
	cairo-path-fixed.c
	cairo-path-in-fill.c
	cairo-path-stroke.c
	cairo-path-stroke-boxes.c
	cairo-path-stroke-polygon.c
	cairo-path-stroke-traps.c
	cairo-path-stroke-tristrip.c
	cairo-pattern.c
	cairo-pen.c
	cairo-polygon.c
	cairo-polygon-intersect.c
	cairo-polygon-reduce.c
	cairo-raster-source-pattern.c
	cairo-rectangle.c
	cairo-rectangular-scan-converter.c
	cairo-region.c
	cairo-rtree.c
	cairo-scaled-font.c
	cairo-shape-mask-compositor.c
	cairo-slope.c
	cairo-spans.c
	cairo-spans-compositor.c
	cairo-spline.c
	cairo-stroke-dash.c
	cairo-stroke-style.c
	cairo-surface.c
	cairo-surface-clipper.c
	cairo-surface-fallback.c
	cairo-surface-observer.c
	cairo-surface-offset.c
	cairo-surface-snapshot.c
	cairo-surface-subsurface.c
	cairo-surface-wrapper.c
	cairo-time.c
	cairo-tor-scan-converter.c
	cairo-tor22-scan-converter.c
	cairo-clip-tor-scan-converter.c
	cairo-toy-font-face.c
	cairo-traps.c
	cairo-tristrip.c
	cairo-traps-compositor.c
	cairo-unicode.c
	cairo-user-font.c
	cairo-version.c
	cairo-wideint.c

	cairo-cff-subset.c
	cairo-scaled-font-subsets.c
	cairo-truetype-subset.c
	cairo-type1-fallback.c
	cairo-type1-glyph-names.c
	cairo-type1-subset.c

	cairo-type3-glyph-surface.c

	cairo-deflate-stream.c

	-I.
	-I../../zlib
"

L="$L -lz"

[ "$IMAGE_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_IMAGE_SURFACE=1
		cairo-image-compositor.c
		cairo-image-info.c
		cairo-image-source.c
		cairo-image-surface.c
		-I../../pixman
	"
	L="$L -lpixman"
}

[ "$PNG_FUNCTIONS" ] && {
	C="$C
		-DCAIRO_HAS_PNG_FUNCTIONS=1
		cairo-png.c
		-I../../libpng
	"
	L="$L -lpng"
}

[ "$RECORDING_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_RECORDING_SURFACE=1
		cairo-recording-surface.c
	"
}

[ "$SVG_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_SVG_SURFACE=1
		cairo-svg-surface.c
	"
}

[ "$WIN32_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_WIN32_SURFACE=1
		-DCAIRO_HAS_WIN32_FONT=1
		win32/cairo-win32-debug.c
		win32/cairo-win32-device.c
		win32/cairo-win32-display-surface.c
		win32/cairo-win32-gdi-compositor.c
		win32/cairo-win32-printing-surface.c
		win32/cairo-win32-surface.c
		win32/cairo-win32-system.c
		win32/cairo-win32-font.c
	"
	L="$L -lgdi32 -lkernel32 -lmsimg32"
}

[ "$QUARTZ_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_QUARTZ_SURFACE=1
		-DCAIRO_HAS_QUARTZ_IMAGE_SURFACE=1
		-DCAIRO_HAS_QUARTZ_FONT=1
		cairo-quartz-font.c
		cairo-quartz-image-surface.c
		cairo-quartz-surface.c
	"
	L="$L -framework ApplicationServices"
}

[ "$PS_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_PS_SURFACE=1
		cairo-ps-surface.c
	"
}

[ "$PDF_SURFACE" ] && {
	C="$C
		-DCAIRO_HAS_PDF_SURFACE=1
		cairo-pdf-surface.c
		cairo-pdf-operators.c
		cairo-pdf-shading.c
	"
}

[ "$FT_FONT" ] && {
	C="$C
		-DCAIRO_HAS_FT_FONT=1
		cairo-ft-font.c
		-I../../freetype/include
	"
	L="$L -lfreetype"
}

<<COMMENT

	-DCAIRO_HAS_WGL_FUNCTIONS=0
	-DCAIRO_HAS_SCRIPT_SURFACE=0
	-DCAIRO_HAS_MIME_SURFACE=0
	-DCAIRO_HAS_OBSERVER_SURFACE=0
	-DCAIRO_HAS_USER_FONT=0
	-DCAIRO_HAS_INTERPRETER=0
	-DCAIRO_HAS_GLESV2_SURFACE=0

   -DCAIRO_HAS_GL_SURFACE=0
	cairo-gl-composite.c
	cairo-gl-device.c
	cairo-gl-dispatch.c
	cairo-gl-glyphs.c
	cairo-gl-gradient.c
	cairo-gl-info.c
	cairo-gl-operand.c
	cairo-gl-shaders.c
	cairo-gl-msaa-compositor.c
	cairo-gl-spans-compositor.c
	cairo-gl-traps-compositor.c
	cairo-gl-source.c
	cairo-gl-surface.c

	cairo-wgl-context.c

	cairo-egl-context.c

	cairo-vg-surface.c

	cairo-cogl-surface.c
	cairo-cogl-gradient.c
	cairo-cogl-context.c
	cairo-cogl-utils.c

COMMENT

rm -f *.o
${X}gcc -c -O2 $C
${X}gcc *.o -shared -o ../../../bin/$P/$D -L../../../bin/$P $L
rm -f      ../../../bin/$P/$A
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
