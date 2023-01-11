local augroup = vim.api.nvim_create_augroup

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
  group = yank_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({
      higroup = 'IncSearch',
      timeout = 40
    })
  end
})

local attach_to_buffer = function(output_bufnr, pattern, command)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("fraso-automagic", { clear = true }),
    pattern = pattern,
    callback = function()
      local append_data = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(output_bufnr, -1, -1, false, data)
        end
      end
      vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { "output: " })
      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
      })
    end,
  })
end

vim.api.nvim_create_user_command("AutoRun", function()
  local bufnr = vim.fn.input 'Bufnr: '
  local pattern = vim.fn.input 'Pattern: '
  local command = vim.split(vim.fn.input 'Command: ', ' ')
  attach_to_buffer(tonumber(bufnr), pattern, command)
end, {})

vim.api.nvim_create_user_command('Bufnr', function()
  local bufnr = vim.api.nvim_get_current_buf()
  print(bufnr)
end, {})

-- get hightlight under cursor
vim.api.nvim_create_user_command("HightlightUnderCursor", function()
  local result = vim.treesitter.get_captures_at_cursor(0)
  print(vim.inspect(result))
end, {})
