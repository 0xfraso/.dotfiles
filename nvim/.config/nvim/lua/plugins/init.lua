return
{
    { -- colorschemes
        'raddari/last-color.nvim',
        'blazkowolf/gruber-darker.nvim', -- rexim's epic colorscheme
        'tjdevries/colorbuddy.nvim',
        'catppuccin/nvim',
        'rose-pine/neovim',
        'Shatur/neovim-ayu',
        'ellisonleao/gruvbox.nvim',
        'EdenEast/nightfox.nvim',
    },

    'nvim-lua/plenary.nvim', -- Common utilities
    'jose-elias-alvarez/null-ls.nvim', -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    'MunifTanjim/prettier.nvim', -- Prettier plugin for Neovim's built-in LSP client
    { 'aserowy/tmux.nvim',            config = function() require("tmux").setup() end },
    { 'norcalli/nvim-colorizer.lua',  config = function() require("colorizer").setup() end },
    { 'lewis6991/gitsigns.nvim',      config = function() require("gitsigns").setup() end },
    { 'kyazdani42/nvim-web-devicons', config = function() require("nvim-web-devicons").setup() end }, -- File icons
    { 'windwp/nvim-ts-autotag',       config = function() require("nvim-ts-autotag").setup() end },
    { 'windwp/nvim-autopairs',        config = function() require("nvim-autopairs").setup({
            disable_filetype = { "TelescopePrompt", "vim" }, }) end },
    { "iamcco/markdown-preview.nvim", build = function() vim.fn["mkdp#util#install"]() end, },

    -- 'dinhhuy258/git.nvim', -- For git blame & browse
    -- 'folke/todo-comments.nvim',
}
