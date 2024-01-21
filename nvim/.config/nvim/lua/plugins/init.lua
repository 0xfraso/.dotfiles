return
{
    { 'mg979/vim-visual-multi' },
    'nvim-treesitter/playground',
    { 'nvim-lua/plenary.nvim' },
    { 'folke/neodev.nvim' },

    { 'norcalli/nvim-colorizer.lua',    config = function() require("colorizer").setup() end },
    { 'kyazdani42/nvim-web-devicons',   config = function() require("nvim-web-devicons").setup() end }, -- File icons

    { "stevearc/dressing.nvim",         opts = true,                                                 event = "VeryLazy" },
    { "numtoStr/Comment.nvim",          opts = {},                                                   lazy = false },
    { "ThePrimeagen/git-worktree.nvim", config = function() require("git-worktree").setup({}) end },
}
