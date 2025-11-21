local api = vim.api
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd
local group = augroup('FrasoGroups', {})

local setHl = function(hl, opts) api.nvim_set_hl(0, hl, opts) end
local getHl = function(hl) return api.nvim_get_hl(0, { name = hl }) end

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
local toHex = function(value)
  return string.format("#%06x", value)
end

local remove_bg = {
  "StatusLine",
}

local override_hls = {
  NormalFloat =              { link = "NormalPopup" },
  GitSignsCurrentLineBlame = { fg = toHex(getHl("Normal")["fg"]) },
  StatusLine =               { link = "Normal" },
  StatusLineLspWarn =        { link = "DiagnosticWarn" },
  StatusLineLspError =       { link = "DiagnosticError" },
  StatusLineLspInfo =        { link = "DiagnosticInfo" },
  StatusLineBorder =         { fg = toHex(getHl("Cursor")["bg"]) },
  Cursor =                   { bg = "#ffdd33" },
  iCursor =                  { bg = "#5f87af" },
  rCursor =                  { bg = "#d70000" },
}

autocmd("ColorScheme", {
  group = group,
  pattern = "*",
  callback = function()
    for k, v in pairs(override_hls) do
      setHl(k, v)
    end
    for _, v in ipairs(remove_bg) do
      local ok, prev = pcall(getHl, v)
      if ok and (prev['background'] or prev["bg"] or prev["ctermbg"]) then
        local attrs = vim.tbl_extend("force", prev, { bg = "NONE", ctermbg = "NONE" })
        attrs[true] = nil
        setHl(v, attrs)
      end
    end
  end,
})

-- restore cursor to file position in previous editing session
autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- open help in vertical split
autocmd("FileType", {
  pattern = "help",
  command = "wincmd L",
})

-- auto resize splits when the terminal's window is resized
autocmd("VimResized", {
  command = "wincmd =",
})

-- no auto continue comments on new line
autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", {}),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

return M
