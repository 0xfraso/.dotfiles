vim.g.mapleader = " "
vim.wo.number = true
vim.wo.relativenumber = true

vim.g.completeopt = "menu,menuone,noselect,noinsert"

vim.o.clipboard = 'unnamedplus'

vim.opt.shell = 'zsh'

vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.winblend = 0
vim.opt.wildoptions = 'pum'
vim.opt.pumblend = 0
vim.opt.background = 'dark'

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.scrolloff = 10
vim.opt.backupskip = { '/tmp/*', '/private/tmp/*' }
vim.opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search
vim.opt.breakindent = true
vim.opt.backspace = { 'start', 'eol', 'indent' }
vim.opt.path:append { '**' } -- Finding files - Search down into subfolders
vim.opt.wildignore:append { '*/node_modules/*' }
vim.opt.mouse = 'a'
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache")

-- disable cursor styling
-- vim.opt.guicursor = ''

vim.o.splitbelow = true
vim.o.splitright = true

vim.opt.list = true

vim.g.editorconfig = false -- remove automatic trim on BufWritePre

vim.cmd("packadd cfilter")
