vim.g.mapleader = ' '

local map = vim.api.nvim_set_keymap

map('n', '<C-h>', '<C-w>h', {noremap = true, silent = false})
map('n', '<C-l>', '<C-w>l', {noremap = true, silent = false})
map('n', '<C-j>', '<C-w>j', {noremap = true, silent = false})
map('n', '<C-k>', '<C-w>k', {noremap = true, silent = false})

map('i', 'jk', '<ESC>', {noremap = true, silent = false})
map('i', 'kj', '<ESC>', {noremap = true, silent = false})

map('n', '<leader>e', ':NvimTreeToggle<CR>', {noremap = true, silent = true})

map('v', '<', '<gv', {noremap = true, silent = false})
map('v', '>', '>gv', {noremap = true, silent = false})

-- control-del to del whole word
map('i', '<C-H>', '<C-W>', {noremap = true, silent = false})

-- visual select all file
map('n', '<leader>a', 'gg<S-v>G', {noremap = true, silent = false})

-- delete without yank
map('n', '<leader>d', '"_d', {noremap = true, silent = false})
