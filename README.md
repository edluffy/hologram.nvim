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
## Roadmap
Core functionality:
- [ ] Support for [Kitty Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol.html)
    - [x] Ability to transfer .png format files and display at an arbitrary location in an nvim buffer.
    - [x] Retain image transparency when being displayed.
    - [x] Retain image position when scrolling.
    - [ ] Extend to work with file formats other than png, like jpg.
    - [ ] Add more transmission mediums apart from direct (data is transmitted within escape code itself), e.g files and temporary files - add download and display image from url?
    - [ ] Auto crop image when partly out of bounds.
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
There are plans for parts of Hologram to be able to be used in other plugins, such as its render functionality.
#### `Renderer:new(opts)`
```lua
Renderer:new({
	buf = 0 -- default: current buffer
})
```

#### `Renderer:transmit(id, source, opts)`
```lua
Renderer:transmit(id, source, {
	medium = 'direct' | 'file' | 'temp_file' | 'shared' -- default: 'direct'
	format =  24 | 32 | 100 -- default: 32
	height = -- Pixel height of image. default: auto
	width  = -- Pixel width of image. default: auto
	col    = -- Nvim buffer column to display at. default: cursor column
	row    = -- Nvim buffer row to display at. default: cursor row
})
```

#### `Renderer:adjust(id, opts)`
Every image can be displayed an arbitrary number of times on the screen, with different adjustments applied. 
These operations do not require the re-transmission of image data and are as a result very fast and lightweight.
There should be no flicker or delay after an adjustment is made.

```lua
Renderer:adjust(id, {
    z_index = -- Vertical stacking order of the image, a negative z_index will draw below text. default: 0.
    crop = {} -- Cropped region of the image to display in pixels. default: show all of image
    area = {} -- Specifies terminal area to display image over, will stretch/squash if necessary. default: auto
    edge = {} -- Top and left edge to start displaying the image at. default: {0, 0}
    offset = {} -- Position within first cell at which to begin displaying image (in pixels). Must be smaller than the size of a cell. default: {0, 0}
})
```
#### `Renderer:delete(id, opts)`

Delete images by specifying an image 'id'  and/or from set of 'opts'.

```lua
Renderer:delete(id, {
    free = -- When deleting image, free stored image data also. default: false
    all = -- Delete all images.
    z_index = -- Delete all images that have the specified z-index.
    col = -- Delete all images that intersect the specified column.
    row = -- Delete all images that intersect the specified row.
    cell = {} -- Delete all images that intersect the specified cell {col, row}
})
```
