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

return M
