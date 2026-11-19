-- Custom completion popup rendered through the UI event API.
-- vim.ui_attach(ext_popupmenu) hands us the popupmenu events; returning a
-- truthy value from the handler stops Nvim from drawing its own PUM.
-- Selection and accept keys stay core-driven -- we only render.
-- See :h vim.ui_attach(), :h ui-popupmenu, :h complete-items.

local ns = vim.api.nvim_create_namespace('fraso_pum')

-- Icon lookup by LSP completion kind; falls back to the first letter.
local icons = {
  Text = '󰉿', Method = '󰆧', Function = '󰊕', Constructor = '󰈏',
  Field = '󰇽', Variable = '󰀫', Property = '󰌹', Class = '󰠱',
  Interface = '󰡢', Module = '󰏗', Unit = '󰑭', Value = '󰎠',
  Enum = '󰦞', Keyword = '󰌋', Snippet = '󰅴', Color = '󰏘',
  File = '󰈙', Reference = '󰈇', Folder = '󰉋', Struct = '󰙅',
  Event = '󱐋', Operator = '󰆕', TypeParameter = '󰊄',
}

-- Linked to builtin groups so colorschemes keep working; default=true lets
-- themes override without us fighting them.
local hl = vim.api.nvim_set_hl
hl(0, 'FrasoPum', { link = 'Pmenu', default = true })
hl(0, 'FrasoPumKind', { link = 'Special', default = true })
hl(0, 'FrasoPumMenu', { link = 'Comment', default = true })
hl(0, 'FrasoPumBorder', { link = 'FloatBorder', default = true })

-- Selection must stay visible even if the theme's PmenuSel is faint or
-- absent: derive real attributes from PmenuSel (Visual fallback), force bold,
-- re-derive on every colorscheme switch.
local function paint_sel_hl()
  local sel = vim.api.nvim_get_hl(0, { name = 'PmenuSel' })
  if sel.bg == nil and sel.fg == nil and sel.reverse ~= true then
    sel = vim.api.nvim_get_hl(0, { name = 'Visual' })
  end
  if sel.bg == nil and sel.fg == nil and sel.reverse ~= true then
    sel = { bg = '#45475a' }
  end
  sel.bold = true
  vim.api.nvim_set_hl(0, 'FrasoPumSel', sel)
end
paint_sel_hl()
vim.api.nvim_create_autocmd('ColorScheme', { callback = paint_sel_hl })

local state = { win = nil, buf = nil, items = {}, selected = -1, offset = 0, height = 12 }

local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  state.win = nil
end

local function icon_for(kind)
  if kind == nil or kind == '' then return '' end
  if vim.g.have_nerd_font then
    return icons[kind] or kind:sub(1, 1)
  end
  return kind:sub(1, 1)
end

-- Render `state.items` starting at `offset`, `selected` highlighted; also
-- resizes/repositions the window content. Returns the content width.
-- Two passes: compose every line and mark range first, insert the lines in
-- ONE call, then draw the marks. Extmarks drawn while lines are still being
-- inserted get pushed around by the later insertions -- that is how the
-- selection ended up painting the wrong row.
local function render(offset, selected)
  local buf = state.buf
  local shown = math.min(#state.items, state.height)
  offset = math.max(0, math.min(offset, math.max(0, #state.items - shown)))
  state.offset = offset

  -- Pass 1: compose line texts and byte ranges for each highlight.
  local menu_width = 0
  for i = 1, shown do
    local m = state.items[offset + i][3] or ''
    menu_width = math.max(menu_width, vim.fn.strdisplaywidth(m))
  end
  if menu_width > 20 then menu_width = 20 end

  local lines, ranges = {}, {}
  local width = 0
  for i = 1, shown do
    local item = state.items[offset + i]
    local word, kind, menu = item[1] or '', item[2] or '', item[3] or ''
    -- Selected row gets a '▸' indicator; others get blank padding so the
    -- text stays aligned. Visibility doesn't depend on theme contrast.
    local lead = (offset + i == selected + 1) and '▸ ' or '  '
    local icon = icon_for(kind)
    local has_icon = icon ~= ''
    if not has_icon then icon = ' ' end -- keep the icon column aligned
    local line = lead .. icon .. ' ' .. word
    local r = { lead = #lead, icon = has_icon and { #lead, #lead + #icon } or nil }
    if menu_width > 0 then
      local m = menu
      if m == '' then
        line = line .. string.rep(' ', menu_width + 2)
      else
        if vim.fn.strdisplaywidth(m) > menu_width then
          m = m:sub(1, #m - (vim.fn.strdisplaywidth(m) - menu_width) - 1) .. '…'
        end
        local pad = menu_width - vim.fn.strdisplaywidth(m) + 2
        r.menu = { #line + pad, #line + pad + #m }
        line = line .. string.rep(' ', pad) .. m
      end
    end
    lines[i] = line
    width = math.max(width, vim.fn.strdisplaywidth(line))
    ranges[i] = r
  end

  -- Pass 2: one insert, then marks at final positions.
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for i = 1, shown do
    local idx = offset + i
    local r = ranges[i]
    if r.icon then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, r.icon[1], {
        end_col = r.icon[2], hl_group = 'FrasoPumKind', priority = 20,
      })
    end
    if r.menu then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, r.menu[1], {
        end_col = r.menu[2], hl_group = 'FrasoPumMenu', priority = 20,
      })
    end
    if idx == selected + 1 then
      -- priority above kind/menu marks: the selected row paints uniformly
      -- with FrasoPumSel, like the native PUM does
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_row = i, hl_eol = true, hl_group = 'FrasoPumSel', priority = 30,
      })
    end
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_config(state.win, { width = width, height = shown })
    vim.api.nvim__redraw({ win = state.win, flush = true })
  end
  return width
end

local function show(items, selected, row, col)
  close()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
  end
  state.items = items
  state.selected = selected or -1

  local shown = math.min(#items, state.height)
  local first = math.max(0, math.min((state.selected or 0) - math.floor(shown / 2), #items - shown))
  local width = render(first, state.selected)

  -- Anchor below the word; flip up near the screen bottom, clamp at the right edge.
  local anchor = (row + 1 + shown + 2 >= vim.o.lines) and 'SW' or 'NW'
  local win_row = anchor == 'SW' and row or row + 1
  local win_col = math.max(0, math.min(col, vim.o.columns - width - 1))

  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = 'editor', row = win_row, col = win_col, anchor = anchor,
    width = width, height = shown,
    style = 'minimal', border = 'rounded',
    noautocmd = true, focusable = false, zindex = 150,
  })
  vim.wo[state.win].winhighlight = 'Normal:FrasoPum,NormalFloat:FrasoPum,FloatBorder:FrasoPumBorder'
  vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
end

-- Scroll-style offset: move only when the selection would leave the view.
local function view_offset(selected, shown)
  local off = state.offset or 0
  if selected < off then return selected end
  if selected >= off + shown then return selected - shown + 1 end
  return off
end

vim.ui_attach(ns, { ext_popupmenu = true }, function(event, ...)
  if vim.fn.mode() == 'c' then return false end -- leave cmdline wildmenu to Nvim
  if event == 'popupmenu_show' then
    local items, selected, row, col = ...
    pcall(show, items, selected, row, col)
    return true
  elseif event == 'popupmenu_select' then
    local selected = ...
    state.selected = selected
    if state.win then
      local shown = math.min(#state.items, state.height)
      pcall(render, view_offset(selected, shown), selected)
    end
    return true
  elseif event == 'popupmenu_hide' then
    pcall(close)
    return true
  end
  return false
end)

-- Menu navigation: <C-j>/<C-k> move down/up while the popup is open.
-- Outside completion they fall back to cursor movement (no recursion: expr
-- result is re-interpreted as typed, so never return the same lhs).
for lhs, down in pairs({ ['<C-j>'] = true, ['<C-k>'] = false }) do
  vim.keymap.set('i', lhs, function()
    if vim.fn.pumvisible() == 1 then return down and '<C-n>' or '<C-p>' end
    return down and '<Down>' or '<Up>'
  end, { expr = true, silent = true, desc = 'Completion menu down/up' })
end
