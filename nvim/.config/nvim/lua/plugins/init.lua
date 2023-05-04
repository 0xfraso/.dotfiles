return
{
    { 'mg979/vim-visual-multi' },
    { 'nvim-treesitter/playground' },

    'nvim-lua/plenary.nvim',

    { 'norcalli/nvim-colorizer.lua',  config = function() require("colorizer").setup() end },
    { 'lewis6991/gitsigns.nvim',      config = function() require("gitsigns").setup() end },
    { 'kyazdani42/nvim-web-devicons', config = function() require("nvim-web-devicons").setup() end }, -- File icons

    -- Lazy loaded

    { 'folke/neodev.nvim',            ft = "lua" },

    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && yarn install",
        setup = function()
            vim.g.mkdp_filetypes = {
                "markdown" }
        end,
        ft = { "markdown" },
    }
}
