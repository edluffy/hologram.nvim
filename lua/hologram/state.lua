local Job = require('hologram.job')

local state = {
	dimensions = {
		screen_cells = {
			width = 0,
			height = 0,
		},
		screen_pixels = {
			width = 0,
			height = 0,
		},
		cell_pixels = {
			width = 0,
			height = 0,
		},
	}
}

function state.update_dimensions()
	if vim.fn.executable('kitty') ~= 1 then
		vim.api.nvim_err_writeln('Unable to find Kitty executable')
		return
	end

	state.dimensions.screen_cells = {
		width  = vim.api.nvim_get_option('columns'),
		height = vim.api.nvim_get_option('lines'),
	}

	Job:new({
		cmd = 'kitty',
		args = { '+kitten', 'icat', '--print-window-size' },
		on_data = function(data)
			data = { data:match("(.+)x(.+)") }

			state.dimensions.screen_pixels.width  = tonumber(data[1])
			state.dimensions.screen_pixels.height = tonumber(data[2])

			state.dimensions.cell_pixels = {
				width  = state.dimensions.screen_pixels.width  / state.dimensions.screen_cells.width,
				height = state.dimensions.screen_pixels.height / state.dimensions.screen_cells.height,
			}
		end,
	}):start()
end

return state
