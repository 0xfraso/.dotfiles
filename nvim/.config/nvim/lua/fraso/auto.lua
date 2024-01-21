local api = vim.api
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd
local usercmd = api.nvim_create_user_command
local group = augroup('FrasoGroups', {})

local M = {}

autocmd('TextYankPost', {
    group = group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40
        })
    end
})

-- get hightlight under cursor
usercmd("HightlightUnderCursor", function()
    local result = vim.treesitter.get_captures_at_cursor(0)
    print(vim.inspect(result))
end, {})

usercmd('RedirToBuffer', function(ctx)
  local lines = vim.split(vim.api.nvim_exec("lua=" .. ctx.args, true), '\n', { plain = true })
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.opt_local.modified = false
end, { nargs = '+', complete = 'command' })

return M
