local Job = {}
Job.__index = Job

function Job:new(opts)
    local obj = setmetatable({
        cmd = opts.cmd,
        args = opts.args,
        on_data  = opts.on_data or function() end,
        on_done  = opts.on_done or function() end,
        stdin = vim.loop.new_pipe(false),
        stdout = vim.loop.new_pipe(false),
        stderr = vim.loop.new_pipe(false),
    }, self)

    return obj
end

function Job:start()
    local handle = vim.loop.spawn(self.cmd, {
        args = self.args,
        stdio = {self.stdin, self.stdout, self.stderr},
    }, function()
        self:stop()
        self.safe_close(self.stdin)
        self.safe_close(self.stdout)
        self.safe_close(self.stderr)
        self.safe_close(handle)
        self.on_done()
    end)

    self.stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
            self.on_data(data)
        end
    end)

    self.stderr:read_start(function(err, data)
        assert(not err, err)
        assert(not data, data)
    end)
end

function Job:stop()
    self.stdin:read_stop()
    self.stdout:read_stop()
    self.stderr:read_stop()
end

function Job:safe_close(handle)
    if not handle then
        return
    elseif not handle:is_closing() then
        handle:close()
    end
end

return Job
