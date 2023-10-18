return {
    {
        'tpope/vim-fugitive',
        cmd = "G",
        keys = {
            { "<leader>gg", "<cmd>G<cr>", desc = "Fugitive" },
        }
    },
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require("gitsigns").setup()
        end,
        lazy = false,
        keys = {
            { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Gitsigns preview hunk" },
        }
    },
}
