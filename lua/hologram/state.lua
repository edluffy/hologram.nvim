local state = {}

state.cell_size = {
    x = 0,
    y = 0,
}

state.screen_size = {
    x = 0,
    y = 0,
    cols = 0,
    rows = 0,
}

function state.update_cell_size()
    local ffi = require('ffi')
    ffi.cdef[[
        typedef struct {
            unsigned short row;
            unsigned short col;
            unsigned short xpixel;
            unsigned short ypixel;
        } winsize;

        int ioctl(int, int, ...);
    ]]

    local TIOCGWINSZ = nil
    if vim.fn.has('linux') == 1 then
        TIOCGWINSZ = 0x5413
    elseif vim.fn.has('mac') == 1 then
        TIOCGWINSZ = 0x40087468
    end

    local sz = ffi.new("winsize")
    assert(ffi.C.ioctl(1, TIOCGWINSZ, sz) == 0,
        'Hologram failed to get screen size: detected OS is not linux or macos.')

    state.screen_size.x = sz.xpixel
    state.screen_size.y = sz.ypixel
    state.screen_size.cols = sz.col
    state.screen_size.rows = sz.row
    state.cell_size.x = sz.xpixel / sz.col
    state.cell_size.y = sz.ypixel / sz.row
end

return state
