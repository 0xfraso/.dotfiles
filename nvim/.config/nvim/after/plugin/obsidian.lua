require("obsidian").setup({
  dir = "~/vault",
  completion = {
    nvim_cmp = true
  }
})

-- if cursor is on obsidian link follow that link using gf
vim.keymap.set(
  "n",
  "gf",
  function()
    if require('obsidian').util.cursor_on_markdown_link() then
      return "<cmd>ObsidianFollowLink<CR>"
    else
      return "gf"
    end
  end,
  { noremap = false, expr = true }
)
