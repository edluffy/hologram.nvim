local hologram = {}
local state = require('hologram.state')
local Image = require('hologram.image')
local fs = require('hologram.fs')

function hologram.setup(opts)
    -- Create autocommands
    local augroup = vim.api.nvim_create_augroup('Hologram', {clear = false})

    vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')

    state.update_cell_size()

    if opts.auto_display == true then
        vim.api.nvim_set_decoration_provider(vim.g.hologram_extmark_ns, {
            on_win = function(_, win, buf, top, bot)
                vim.schedule(function() hologram.buf_render_images(buf, top, bot) end)
            end
        })

        vim.api.nvim_create_autocmd({'BufWinLeave'}, {
            callback = function(au)
                hologram.buf_delete_images(au.buf, 0, -1)
            end,
        })

        vim.api.nvim_create_autocmd({'BufWinEnter'}, {
            callback = function(au)
                vim.api.nvim_buf_attach(au.buf, false, {
                    on_lines = function(_, buf, tick, first, last)
                        hologram.buf_delete_images(buf, first, last)
                        hologram.buf_generate_images(buf, first, last)
                    end,
                    on_detach = function(_, buf)
                        hologram.buf_delete_images(buf, 0, -1)
                    end
                })
                hologram.buf_generate_images(au.buf, 0, -1)
            end
        })
    end
end

local prev_ids = {}

function hologram.buf_render_images(buf, top, bot)
    local exts = vim.api.nvim_buf_get_extmarks(buf,
        vim.g.hologram_extmark_ns,
        {math.max(top-1, 0), 0}, 
        {bot-2, -1},
    {})

    local curr_ids = {}
    for _, ext in ipairs(exts) do
        local id, row, col = unpack(ext)
        Image.instances[id]:display(row+1, 0, buf, {})
        curr_ids[#curr_ids+1] = id
    end

    if prev_ids[buf] ~= nil then
        for _, id in ipairs(prev_ids[buf]) do
            if not vim.tbl_contains(curr_ids, id) then
                Image.instances[id]:delete(buf, {})
            end
        end
    end
    prev_ids[buf] = curr_ids
end

function hologram.buf_generate_images(buf, top, bot)
    local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
    for n, line in ipairs(lines) do
        local source = hologram.find_source(line)
        if source ~= nil then
            local img = Image:new(source, {})
            img:display(top+n, 0, buf, {})
        end
    end
end

function hologram.buf_delete_images(buf, top, bot)
    local exts = vim.api.nvim_buf_get_extmarks(buf,
        vim.g.hologram_extmark_ns,
        {top, 0},
        {bot, -1},
    {})

    for _, ext in ipairs(exts) do
        local id, _, _ = unpack(ext)
        Image.instances[id]:delete(buf, {free=true})
    end
end

function hologram.find_source(line)
    if line:find('png') then
        local inline_link = line:match('!%[.-%]%(.-%)')
        if inline_link then
            local source = inline_link:match('%((.+)%)')
            local path = hologram._to_absolute_path(source)
            if fs.check_sig_PNG(path) then
                return path
            else return nil end
        end
    end
end

function hologram._to_absolute_path(path)
    if hologram._is_root_path(path) then
        return path
    else
        -- absolute_path: folder_path + relative_path
        local folder_path = vim.fn.expand("%:p:h")
        local absolute_path = folder_path .. "/" .. path
        return absolute_path
    end
end

function hologram._is_root_path(path)
    local first_path_char = string.sub(path, 0, 1)
    if first_path_char == "/" then
      return true
    else
      return false
    end
end

return hologram
