return
{
    { -- colorschemes
        'raddari/last-color.nvim',
        { '~/projects/gruber-darker.nvim', dev = true },
        'tjdevries/colorbuddy.nvim',
        'catppuccin/nvim',
        'rose-pine/neovim',
        'Shatur/neovim-ayu',
        'ellisonleao/gruvbox.nvim',
        'EdenEast/nightfox.nvim',
        'olivercederborg/poimandres.nvim',
    },

    'nvim-lua/plenary.nvim', -- Common utilities
    { 'aserowy/tmux.nvim',             config = function() require("tmux").setup() end },
    { 'norcalli/nvim-colorizer.lua',   config = function() require("colorizer").setup() end },
    { 'lewis6991/gitsigns.nvim',       config = function() require("gitsigns").setup() end },
    { 'kyazdani42/nvim-web-devicons',  config = function() require("nvim-web-devicons").setup() end }, -- File icons

    -- Lazy loaded

    { 'folke/neodev.nvim', ft = "lua" },
    { 'windwp/nvim-ts-autotag',
        ft = { "html", "ts", "js", "tsx", "jsx", "xml", "xhtml" },
        config = function() require("nvim-ts-autotag").setup() end },
    { 'windwp/nvim-autopairs', config = function()
        require("nvim-autopairs").setup({
            disable_filetype = { "TelescopePrompt", "vim" }, })
    end },
    { "iamcco/markdown-preview.nvim", build = "cd app && yarn install", setup = function()
        vim.g.mkdp_filetypes = {
            "markdown" }
    end, ft = { "markdown" }, }
}
