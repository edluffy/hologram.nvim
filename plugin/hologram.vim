if !has('nvim') || exists('g:loaded_hologram')
	finish
endif

lua require('hologram').setup()

let g:loaded_hologram = 1
