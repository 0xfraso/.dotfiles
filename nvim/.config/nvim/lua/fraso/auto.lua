local api = vim.api
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd
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

autocmd("ColorScheme", {
  group = group,
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "NormalFloat", { link = "Float" })
  end,
})

return M
