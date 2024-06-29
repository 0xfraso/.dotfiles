--- @return string
local location = function()
  return '%l:%2v'
end

--- @return string
local function file_percentage()
  return string.format("%%#StatusLine# %d%%%% %%*",
    math.ceil(vim.api.nvim_win_get_cursor(0)[1] / vim.api.nvim_buf_line_count(0) * 100))
end

local combine_groups = function(groups)
  local parts = vim.tbl_map(function(s)
    if type(s) == "string" then
      return s
    end
    if type(s) ~= "table" then
      return ""
    end

    local string_arr = vim.tbl_filter(function(x)
      return type(x) == "string" and x ~= ""
    end, s.strings or {})
    local str = table.concat(string_arr, " ")
    -- Use previous highlight group
    if s.hl == nil then
      return " " .. str .. " "
    end
    -- Allow using this highlight group later
    if str:len() == 0 then
      return "%#" .. s.hl .. "#" .. " "
    end
    return string.format("%%#%s# %s ", s.hl, str)
  end, groups)

  return table.concat(parts, "")
end

---@return string
local section_filename = function()
  if vim.bo.buftype == 'terminal' then
    return '%t'
  else
    return "%#StatusLine#%t%r%m"
  end
end

local section_lsp = function()
  local has_devicons, devicons = pcall(require, "nvim-web-devicons")
  local icon = ""
  if has_devicons then
    icon = devicons.get_icon(vim.fn.expand("%:t"), nil, { default = true })
  end
  local msg = 'no lsp'
  local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
  local clients = vim.lsp.get_active_clients()
  if next(clients) == nil then
    return msg
  end
  for _, client in ipairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
      return icon .. " " .. client.name
    end
  end
  return msg
end

local status_recording = function ()
  local reg = vim.fn.reg_recording()
  if reg == "" then return "" end -- not recording
  return "@" .. reg
end

return {
  "echasnovski/mini.statusline",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local active_content = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 2000 })
      local git = MiniStatusline.section_git({ trunc_width = 40 })
      local filename = section_filename({ trunc_width = 140 })
      local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

      return combine_groups({
        { hl = "Cursor", strings = {} },
        { hl = "StatusLinePart", strings = { mode:lower() } },
        { hl = "StatusLine", strings = { git } },
        "%<", -- Mark general truncate point
        { hl = "StatusLine", strings = { filename } },
        { hl = "StatusLine", strings = { search, location(), file_percentage() } },
        "%=", -- End left alignment
        { hl = "StatusLine", strings = { status_recording(), section_lsp() } },
        { hl = "Cursor", strings = {} },
      })
    end

    require("mini.statusline").setup({
      content = {
        active = active_content,
      },
    })
  end,
}
