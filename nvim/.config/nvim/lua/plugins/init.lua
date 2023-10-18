return
{
    { 'mg979/vim-visual-multi' },
    'nvim-treesitter/playground',
    'nvim-lua/plenary.nvim',

    { 'norcalli/nvim-colorizer.lua',  config = function() require("colorizer").setup() end },
    { 'kyazdani42/nvim-web-devicons', config = function() require("nvim-web-devicons").setup() end }, -- File icons

    { 'folke/neodev.nvim',            ft = "lua" },

    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        setup = function()
            vim.g.mkdp_filetypes = {
                "markdown" }
        end,
        ft = { "markdown" },
    }
}
