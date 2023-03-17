vim.g.mapleader = ";"
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
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.hlsearch = false
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

-- disable cursor styling
vim.opt.guicursor = ''

vim.o.splitbelow = true
vim.o.splitright = true
