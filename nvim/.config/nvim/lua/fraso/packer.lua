local status, packer = pcall(require, "packer")
if (not status) then
    print("Packer is not installed")
    return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
    use 'wbthomason/packer.nvim'

    use { -- colorschemes
        'xiyaowong/nvim-transparent', -- Nvim transparent background toggler
        'raddari/last-color.nvim',
        'tjdevries/colorbuddy.nvim',
        'folke/tokyonight.nvim',
        'sainnhe/gruvbox-material',
        'catppuccin/nvim',
        'rose-pine/neovim',
        'Shatur/neovim-ayu',
        'ellisonleao/gruvbox.nvim',
        'EdenEast/nightfox.nvim'
    }

    use 'epwalsh/obsidian.nvim'
    use 'lukas-reineke/indent-blankline.nvim'
    use 'nvim-lualine/lualine.nvim' -- Statusline
    use 'nvim-lua/plenary.nvim' -- Common utilities
    use 'onsails/lspkind-nvim' -- vscode-like pictograms
    use 'hrsh7th/cmp-buffer' -- nvim-cmp source for buffer words
    use 'hrsh7th/cmp-path' -- nvim-cmp source for buffer words
    use 'hrsh7th/cmp-nvim-lsp' -- nvim-cmp source for neovim's built-in LSP
    use 'hrsh7th/nvim-cmp' -- Completion
    use 'neovim/nvim-lspconfig' -- LSP
    use 'folke/neodev.nvim'
    use 'jose-elias-alvarez/null-ls.nvim' -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    use 'MunifTanjim/prettier.nvim' -- Prettier plugin for Neovim's built-in LSP client
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'glepnir/lspsaga.nvim' -- LSP UIs
    use 'aserowy/tmux.nvim'
    use 'L3MON4D3/LuaSnip'
    use 'saadparwaiz1/cmp_luasnip'
    use 'benfowler/telescope-luasnip.nvim'
    use "rafamadriz/friendly-snippets"

    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }
    use 'kyazdani42/nvim-web-devicons' -- File icons
    use 'nvim-telescope/telescope.nvim'
    use 'nvim-telescope/telescope-file-browser.nvim'

    use 'windwp/nvim-autopairs'
    use 'windwp/nvim-ts-autotag'
    use 'norcalli/nvim-colorizer.lua'
    use 'folke/zen-mode.nvim'
    -- use 'folke/todo-comments.nvim'
    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })
    use 'akinsho/nvim-bufferline.lua'
    use 'lewis6991/gitsigns.nvim'
    -- use 'dinhhuy258/git.nvim' -- For git blame & browse
    use 'tpope/vim-fugitive'
end)
