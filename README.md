# hologram.nvim
WIP - not ready for use yet

## Usage
If you are using init.vim instead of init.lua, remember to wrap block below with `lua << EOF` and `EOF`
```lua
require('hologram').setup{ 
    protocol = ...
}
```

Displaying arbitrary images:
```lua
require('hologram').display{
    image = '... .png',
    width = ...,
    height = ...,
}
```
