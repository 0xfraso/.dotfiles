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

return M
