local default_opts = {
  silent = true,
  noremap = true
}
local keymap = function(mode, lhs, rhs, opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

keymap("n", "<leader>bd", ":bd<cr>")
--%bd = delete all buffers. e# = open the last buffer for editing. bd# delete the [No Name] buffer that gets created
keymap("n", "<leader>bo", ":%bd|e#|bd#<cr>")

-- Center cursor on screen after page down-up
keymap("n", '<C-u>', '<C-u>zz')
keymap("n", '<C-d>', '<C-d>zz')
keymap("n", "n", 'nzz')
keymap("n", "N", 'Nzz')
keymap("n", "J", "mzJ`z")

-- move highlighted lines and indent
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Don't yank on x
keymap("n", 'x', '"_x')

keymap("n", 'tn', ':tabNext<CR>')
keymap("n", 'L', ':bnext<CR>')
keymap("n", 'H', ':bprevious<CR>')

keymap("n", "gR", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { silent = false })

keymap("t", "<Esc>", [[<C-\><C-n>]])

keymap("n", "<leader>=", '<Cmd>lua vim.lsp.buf.format()<CR>')

keymap("n", "<leader>sw", "<Cmd>set wrap!<CR>")

-- quickfix mappings
keymap("n", "<C-j>", "<Cmd>cnext<CR>")
keymap("n", "<C-k>", "<Cmd>cprevious<CR>")

keymap("n", "<Del>", '"_x')
keymap("v", "<Del>", '"_x')
keymap("n", "<Esc>", ':noh<CR>')

-- toggle wrap
keymap("n", "<leader>uw", function()
  vim.cmd("set wrap!")
  local wrap = vim.opt.wrap:get() and "enabled" or "disabled"
  vim.notify(("Wrap %s"):format(wrap))
end)

keymap("n", "<leader>so", ":so %<CR>")
