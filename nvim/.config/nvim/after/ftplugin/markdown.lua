vim.opt_local.wrap = true

vim.keymap.set("n", "<leader>b", [[ciw**<c-r>"**<esc>]], { noremap = true })
vim.keymap.set("n", "<leader>i", [[ciw*<c-r>"*<esc>]], { noremap = true })

vim.keymap.set("v", "<leader>b", [[c**<c-r>"**<esc>]], { noremap = true })
vim.keymap.set("v", "<leader>i", [[c*<c-r>"*<esc>]], { noremap = true })

vim.keymap.set("n", "#", [[I#<esc>]], { noremap = true })
