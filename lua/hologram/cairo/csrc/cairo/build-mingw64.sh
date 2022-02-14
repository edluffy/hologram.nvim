export IMAGE_SURFACE=1
export PNG_FUNCTIONS=1
export RECORDING_SURFACE=1
export SVG_SURFACE=1
export PS_SURFACE=1
export PDF_SURFACE=1
export FT_FONT=1
export WIN32_SURFACE=1

P=mingw64 L="-s -static-libgcc" D=cairo.dll A=cairo.a ./build.sh
