local keymap = vim.keymap

-- Save
keymap.set("n", '<leader>w', ':w<Return>')

-- Center cursor on screen after page down-up
keymap.set("n", '<C-u>', '<C-u>zz')
keymap.set("n", '<C-d>', '<C-d>zz')
keymap.set("n", "n", 'nzz')
keymap.set("n", "N", 'Nzz')
keymap.set("n", "J", "mzJ`z")

-- move highlighted lines and indent

keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Source lua file
keymap.set("n", '<leader>o', ':so %<Return>')

-- Don't yank on x
keymap.set("n", 'x', '"_x')

-- Alt delete (delete word)
keymap.set('i', '<M-BS>', '<C-W>')

-- Clear highlighted
keymap.set("n", '<F2>', ':noh<Return><C-l>')

-- Increment/decrement
keymap.set("n", '+', '<C-a>')
keymap.set("n", '-', '<C-x>')

-- Close tab
keymap.set("n", '<leader>x', ':bdelete<Return>')

-- Resize window
keymap.set("n", '<C-w><left>', '<C-w><')
keymap.set("n", '<C-w><right>', '<C-w>>')
keymap.set("n", '<C-w><up>', '<C-w>+')
keymap.set("n", '<C-w><down>', '<C-w>-')

keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

keymap.set("n", "<leader>t", '<Cmd>term<CR>')
keymap.set("t", "<Esc>", [[<C-\><C-n>]])

keymap.set("n", "<leader>cc", '<Cmd>lua require("fraso/compile").compile()<CR>')
keymap.set("n", "<leader>c", '<Cmd>lua require("fraso/compile").compile_command()<CR>')

keymap.set("n", "<leader>=", '<Cmd>lua vim.lsp.buf.format()<CR>')
