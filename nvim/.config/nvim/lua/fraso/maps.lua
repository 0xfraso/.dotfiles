local default_opts = {
    silent = true,
    noremap = true
}
local keymap = function(mode, lhs, rhs, opts)
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- Save
keymap("n", '<leader>w', ':w<Return>')

-- Center cursor on screen after page down-up
keymap("n", '<C-u>', '<C-u>zz')
keymap("n", '<C-d>', '<C-d>zz')
keymap("n", "n", 'nzz')
keymap("n", "N", 'Nzz')
keymap("n", "J", "mzJ`z")

-- move highlighted lines and indent

keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Source lua file
keymap("n", '<leader>o', ':so %<Return>')

-- Don't yank on x
keymap("n", 'x', '"_x')

-- Alt delete (delete word)
keymap('i', '<M-BS>', '<C-W>')

-- Clear highlighted
keymap("n", '<F2>', ':noh<Return><C-l>')

-- Increment/decrement
keymap("n", '+', '<C-a>')
keymap("n", '-', '<C-x>')

-- Close buffer
keymap("n", '<leader>x', ':bdelete<Return>')
keymap("n", 'tn', ':tabNext<CR>')

keymap("n", "gR", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { silent = false })

keymap("t", "<Esc>", [[<C-\><C-n>]])

keymap("n", "<leader>=", '<Cmd>lua vim.lsp.buf.format()<CR>')

keymap("n", "<leader>sw", "<Cmd>set wrap!<CR>")

-- quickfix mappings
keymap("n", "<leader>qn", "<Cmd>cnext<CR>")
keymap("n", "<leader>qp", "<Cmd>cprevious<CR>")
keymap("n", "<leader>qx", "<Cmd>cclose<CR>")
keymap("n", "<leader>qo", "<Cmd>copen<CR>")

keymap("n", "<Del>", '"_x')
keymap("v", "<Del>", '"_x')
