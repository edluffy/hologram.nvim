<h3 align="center">
    <img src="https://user-images.githubusercontent.com/28115337/185177835-27fd08cd-864e-4f10-85ad-751d7a4eb431.png" alt="hologram.nvim" width="500"/>
</h3>

<p align="center">
    A cross platform terminal image viewer for Neovim. Extensible and fast, written in Lua and C.<br />
    Works on macOS and Linux with current support for Kitty Graphics Protocol.<br />
    Highly experimental, expect breaking changes 🚧.
</p>

<p align="center">
  <img src="https://user-images.githubusercontent.com/28115337/185186641-0c532c02-76fc-4e24-9ea6-638f23d30df4.gif" alt="showcase" />
</p>

# Install
Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'edluffy/hologram.nvim'}
```
Using [vim-plug](https://github.com/junegunn/vim-plug):
```vimscript
Plug 'edluffy/hologram.nvim'
```

# Usage
Hologram.nvim allows you to view inline images directly inside a Neovim buffer. Requires the following setup in `init.lua`:

```lua
require('hologram').setup{
    auto_display = true -- WIP automatic markdown image display, may be prone to breaking
}
```

# Exposed API
There are plans for parts of Hologram to be able to be used in other plugins, such as its image functionality.

## `image.lua`
Minimal example - save as a file (e.g. minimal.lua) then run with `:luafile %`:

```lua
local source = '/Users/.../Documents/my-image.png'
local buf = vim.api.nvim_get_current_buf()
local image = require('hologram.image'):new(source, {})

-- Image should appear below this line, then disappear after 5 seconds

image:display(5, 0, buf, {})

vim.defer_fn(function()
    image:delete(0, {free = true})
end, 5000)
```

#### `Image:new(source, keys)`
Creates a new image object and sends image data with transmission keys to terminal.
```lua
Image:new(source, {
    format = 100, -- format in which image data is sent
    transmission_type = 'f', -- transmission medium used
    data_width = nil, -- px. width of image
    data_height = nil, -- px. height of image
    data_size = nil, -- size of data to read from file
    data_offset = nil, -- offset from which to read file data
    image_number = nil, -- image number
    compressed = nil, -- whether data is compressed or not
    image_id = nil, -- image id
    placement_id = 1, -- placement id
})
```
For more details see https://sw.kovidgoyal.net/kitty/graphics-protocol/#control-data-reference

#### `Image:display(row, col, buf, keys)`
Every image can be displayed an arbitrary number of times on the screen, with different adjustments applied. 
These operations do not require the re-transmission of image data and are as a result very fast and lightweight.
There should be no flicker or delay after an adjustment is made.
```lua
Image:display(row, col, buf, {
    x_offset = nil, -- left edge of image area to start displaying from (px.)
    y_offset = nil, -- top edge of image area to start displaying from (px.)
    width = nil, -- width of image area to display
    height = nil, -- height of image area to display
    cell_x = nil, -- x-offset within first cell to start displaying from (px.)
    cell_y = nil, -- y-offset within first cell to start displaying from (px.)
    cols = nil, -- number of columns to display over
    rows = nil, -- number of rows to display over
    z_index = 0, -- vertical stacking order of image
    placement_id = 1, -- placement id
})
```

#### `Image:delete(buf, opts)`

Deletes the image located in `buf`.

```lua
Image:delete(id, {
    free = false -- when deleting image, free stored image data and also extmark of image. (default: false)
})
```

# Roadmap
Core functionality:
- [ ] Support for [Kitty Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol.html)
    - [x] Ability to transfer .png format files and display at an arbitrary location in an nvim buffer.
    - [x] Retain image transparency when being displayed.
    - [x] Retain image position when scrolling.
    - [ ] Extend to work with file formats other than png, like jpg.
    - [ ] Add more transmission mediums apart from direct (data is transmitted within escape code itself), e.g files and temporary files - add download and display image from url?
    - [x] Auto crop image when partly out of bounds.
    - [ ] Ability to transfer animation frame data.
- [ ] Support for [Iterm2 Images Protocol](https://iterm2.com/documentation-images.html#:~:text=Inline%20Images%20Protocol-,Inline%20Images%20Protocol,8%2Dbit%2Dclean%20environment).
- (potential) Support for Sixel format.
- Extend to work with [tmux](https://github.com/tmux/tmux/wiki) - wrap with DCS passthrough sequences?

Extensions:
- [ ] Floating image preview for .pdf, .md and .tex.
- [ ] Live file preview for .pdf and .md (using window splits).
- [ ] Live equation preview for .tex format.

Misc:
- [x] Switch to bare C implementation for base64 image encoding.
