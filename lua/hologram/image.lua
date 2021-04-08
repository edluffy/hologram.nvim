local graphics = require('hologram.graphics')

local Image = {}
Image.__index = Image

local function create_tempfile()
    print("creating tempfile")
end

function Image:new(opts)
    opts = opts or {}
	assert(opts.source, "`source` field required to create new Image")

    local obj = setmetatable({
		source = opts.source,
		tempfile = opts.tempfile or create_tempfile(),
		--transform =,
		cmds = opts.cmds or {},
		mark_id = opts.mark_id or vim.api.nvim_buf_set_extmark(0, vim.g.mark_ns, 0, 0, {}),
    }, self)
    return obj
end

function Image:generate()
    local file = io.open(self.source, "r")
    local raw = file:read("*all")
    io.close(file)


	local l, c = self:get_pos()
	self.cmds[#self.cmds+1] = graphics.cursor_move_cmd(l, c)

	graphics.kitty_write_chunked({a='T', f='100'}, raw, self.cmds)

	self.cmds[#self.cmds+1] = graphics.cursor_revert_cmd()
end

function Image:remove()
end

function Image:show()
    graphics.write_cmds(self.cmds)
end

function Image:hide()
end

function Image:toggle()
end

function Image:state()
end

function Image:set_pos(l, c)
	vim.api.nvim_buf_set_extmark(0, vim.g.mark_ns, l, c, {id = self.mark_id})
end

function Image:get_pos()
    l, c = unpack(vim.api.nvim_buf_get_extmark_by_id(0, vim.g.mark_ns, self.mark_id, {}))
	return l, c
end

function Image:move_pos(dl, dc)
	local l, c = self:get_pos()
	self:set_pos(l+dl, c+dc)
end

function Image:set_transform(tf)
end

function Image:get_transform(tf)
end

return Image
