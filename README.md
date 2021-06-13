# hologram.nvim
A cross platform terminal image viewer for Neovim. Extensible and fast, written in Lua and C. Works on macOS and Linux. Current support for
[Kitty Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol.html). Highly experimental, expect breaking changes.

![showcase](https://user-images.githubusercontent.com/28115337/115054101-c0848680-9ed7-11eb-9980-a3bc2d691fc2.gif)

## Install
Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'edluffy/hologram.nvim'}
```
Using [vim-plug](https://github.com/junegunn/vim-plug):
```vimscript
Plug 'edluffy/hologram.nvim'
```

## Usage
Hologram.nvim allows you to view images directly inside a Neovim buffer (let buf=0 for current buffer):

- `:lua require('hologram').add_image(buf, '/Users/..../Documents/my-image.png', row, col)`
    - Add an image to buffer at position row, col.

- `:lua require('hologram').gen_images(buf, ft)`
    - Generate buffer images for certain filetypes (only 'markdown' currently)

- `:lua require('hologram').clear_images(buf)`
    - Remove all images from buffer.

- `:lua require('hologram').update_images(buf)`
    - Repositions buffer images in viewport (automatically done on WinScrolled event)

## Roadmap
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
- [ ] Switch to bare C implementation for base64 image encoding.

## Exposed API
There are plans for parts of Hologram to be able to be used in other plugins, such as its image functionality.

## `image.lua`
Images are objects that comprise of an `id`, `source`, and an `extmark`.

- `id` holds info about the images buffer and its extmark. This is used in Kitty's Graphics protocol to ensure that each image can be uniquely identified.

- `source` is the path to the image file. e.g '/Users/..../Documents/my-image.png'

- `extmark` holds the position of an image in its buffer - this can be useful for finding images within ranges.

Minimal example:

```lua
local my_image = require('hologram.image'):new({
    source = '/Users/..../Documents/my-image.png',
    row = 11,
    col = 0,
})

my_image:transmit() -- send image data to terminal

-- Move image 5 rows down after 1 second
vim.defer_fn(function()
    my_image:move(15, 0)
    my_image:adjust() -- must adjust to update image
end, 1000)

-- Crop image to 100x100 pixels after 2 seconds
vim.defer_fn(function()
    my_image:adjust({
        crop = {100, 100},
    })
end, 2000)

-- Resize image to 75x50 pixels after 3 seconds
vim.defer_fn(function()
    my_image:adjust({
        area = {75, 50},
    })
end, 3000)
```

#### `Image:new(opts)`
```lua
Image:new({
    source  = -- specifies path of image data
    buf     = -- buf to display in, default: current buffer
    row     = -- row to display at, default: cursor row
    col     = -- col to display at, default: cursor col
})
```

#### `Image:transmit(opts)`
```lua
Image:transmit({
    medium = 'direct' | 'file' | 'temp_file' | 'shared' -- default: 'direct'
    format = 24 | 32 | 100 -- default: 32
    height = -- specify pixel height of image. (optional)
    width  = -- specify pixel width of image. (optional)
    hide   = -- do not display image immediately after transmission, default: false
})
```

#### `Image:adjust(opts)`
Every image can be displayed an arbitrary number of times on the screen, with different adjustments applied. 
These operations do not require the re-transmission of image data and are as a result very fast and lightweight.
There should be no flicker or delay after an adjustment is made.

```lua
Image:adjust({
    z_index = -- vert. stacking order of the image, a negative z_index will draw below text. (default: 0).
    crop    = {x_px, y_px} -- pixel region to crop image to, with top left anchored. (optional)
    area    = {cols, rows} -- cell region to display image over, will stretch/squash if necessary. (optional)
    edge    = {left_px, top_px} -- pixel coords to treat as top left of image. will cause crash if edge > img size. (optional)
    offset  = {xoff_px, yoff_px} -- pixel coords within first cell to begin displaying image, must be smaller than cell size. (optional)
})
```
#### `Image:delete(id, opts)`

Deletes the image and all that satisfy requirements in opts. Images deleted via 'opts' will not have their extmarks removed.

```lua
Image:delete(id, {
    free    = true | false -- when deleting image, free stored image data and also extmark of image. (default: false)
    all     = true | false -- del. all images. (default: false)
    z_index = -- del. images that have the specified z-index.
    col     = -- del. images that intersect the specified column.
    row     = -- del. images that intersect the specified row.
    cell    = {col, row} -- del. images that intersect the specified cell
})
```

#### `Image:move(row, col)`
Sets location by moving the extmark associated with the image.

#### `Image:pos()`
Returns position of image (via its extmark).

#### `Image:buf()`
Returns buf. number of image.

#### `Image:ext()`
Returns extmark id of image.
