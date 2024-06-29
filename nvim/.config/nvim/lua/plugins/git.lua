return {
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gg", "<cmd>G<cr>", desc = "Fugitive" },
    }
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
      })
    end,
    lazy = false,
    keys = {
      { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Gitsigns preview hunk" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>",   desc = "Gitsigns reset hunk" },
      { "<leader>gd", "<cmd>Gitsigns diffthis<cr>",     desc = "Gitsigns diff current buffer" },
      { "<leader>gq", "<cmd>Gitsigns setqflist<cr>",    desc = "Gitsigns send hunks to qflist" },
      { "<leader>gn", "<cmd>Gitsigns next_hunk<cr>",    desc = "Gitsigns next hunk" },
      { "<leader>gp", "<cmd>Gitsigns prev_hunk<cr>",    desc = "Gitsigns previous hunk" },
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "ibhagwan/fzf-lua", -- optional
    },
    config = true,
    keys = {
      { "<leader>gG", function() require("neogit").open({ kind = "split" }) end, desc = "Neogit", },
    },
  },
}
