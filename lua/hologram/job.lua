local Job = {}
Job.__index = Job

function Job:new(opts)
    local obj = setmetatable({
        cmd = opts.cmd,
        args = opts.args,
        done = false,
        on_stdin = opts.on_stdin or function() end,
        on_stdout = opts.on_stdout or function() end,
        on_stderr = opts.on_stderr or function() end,
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
        self.done = true
    end)

    self.stdin:read_start(self.on_stdin)
    self.stdout:read_start(self.on_stdout)
    self.stderr:read_start(self.on_stderr)
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
